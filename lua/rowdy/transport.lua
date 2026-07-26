local uv = vim.uv

local M = {}

---@class RowdyRetryOptions
---@field max_attempts integer
---@field delays integer[]
---@field max_retry_after integer

---@class RowdyTransportRequest
---@field model? string
---@field path? string
---@field method? 'GET'|'POST'
---@field api_key string
---@field connect_timeout integer
---@field total_timeout? integer
---@field body? string
---@field retry? RowdyRetryOptions
---@field on_data? fun(data: string)

---@class RowdyTransportResponse
---@field status integer
---@field body string
---@field retry_after? string

---@class RowdyTransportError
---@field message string

local status_marker = "__ROWDY_HTTP_STATUS__"
local retry_marker = "__ROWDY_RETRY_AFTER__"
local months = {
	Jan = 1,
	Feb = 2,
	Mar = 3,
	Apr = 4,
	May = 5,
	Jun = 6,
	Jul = 7,
	Aug = 8,
	Sep = 9,
	Oct = 10,
	Nov = 11,
	Dec = 12,
}

local function config_value(value)
	return '"'
		.. tostring(value):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r")
		.. '"'
end

local function curl_config(request)
	local path = request.path or ("/models/" .. request.model .. "/endpoints")
	local lines = {
		"silent",
		"show-error",
		"location",
		"request = " .. config_value(request.method or "GET"),
		"url = " .. config_value("https://openrouter.ai/api/v1" .. path),
		"header = " .. config_value("Authorization: Bearer " .. request.api_key),
		"header = " .. config_value(
			request.on_data and "Accept: text/event-stream" or "Accept: application/json"
		),
		"connect-timeout = " .. config_value(request.connect_timeout),
	}
	if request.body then
		table.insert(lines, "header = " .. config_value("Content-Type: application/json"))
		table.insert(lines, "data = " .. config_value(request.body))
	end
	if request.on_data then
		table.insert(lines, "no-buffer")
	end
	if request.total_timeout then
		table.insert(lines, "max-time = " .. config_value(request.total_timeout))
	end
	table.insert(
		lines,
		"write-out = "
			.. config_value(
				("\n%s:%%{http_code}\n%s:%%header{retry-after}"):format(status_marker, retry_marker)
			)
	)
	return table.concat(lines, "\n") .. "\n"
end

local function parse_response(output)
	local body, status, retry_after =
		output:match("^(.*)\n" .. status_marker .. ":(%d%d%d)\n" .. retry_marker .. ":(.-)%s*$")
	if not status then
		return nil, "curl output did not contain HTTP response metadata"
	end
	return {
		status = tonumber(status),
		body = body,
		retry_after = retry_after ~= "" and retry_after or nil,
	}
end

local function should_retry(status)
	return status == 408 or status == 429 or status >= 500
end

local function http_date_delay(value)
	local day, month, year, hour, minute, second =
		value:match("^%a%a%a, (%d%d) (%a%a%a) (%d%d%d%d) (%d%d):(%d%d):(%d%d) GMT$")
	if not day or not months[month] then
		return nil
	end
	local year_number = assert(tonumber(year))
	local day_number = assert(tonumber(day))
	local hour_number = assert(tonumber(hour))
	local minute_number = assert(tonumber(minute))
	local second_number = assert(tonumber(second))
	local local_epoch = os.time({
		year = year_number,
		month = months[month],
		day = day_number,
		hour = hour_number,
		min = minute_number,
		sec = second_number,
		isdst = false,
	})
	if not local_epoch then
		return nil
	end
	local utc_table = os.date("!*t", local_epoch)
	if type(utc_table) ~= "table" then
		return nil
	end
	local utc_as_local = os.time(utc_table)
	local epoch = local_epoch + os.difftime(local_epoch, utc_as_local)
	return math.max(0, math.floor(os.difftime(epoch, os.time()) * 1000))
end

local function retry_delay(request, attempt, retry_after)
	if retry_after then
		local seconds = tonumber(retry_after)
		if seconds and seconds >= 0 then
			return math.min(math.floor(seconds * 1000), request.retry.max_retry_after)
		end
		local date_delay = http_date_delay(retry_after)
		if date_delay then
			return math.min(date_delay, request.retry.max_retry_after)
		end
	end
	return request.retry.delays[attempt] or 0
end

local function close(handle)
	if handle and not handle:is_closing() then
		handle:close()
	end
end

---@param request RowdyTransportRequest
---@param callback fun(error?: RowdyTransportError, response?: RowdyTransportResponse)
---@return fun()
function M.request(request, callback)
	local active = true
	local attempt = 0
	local process
	local timer

	local function finish(err, response)
		if not active then
			return
		end
		active = false
		callback(err, response)
	end

	local start_attempt
	local function retry_or_finish(err, response)
		if not active then
			return
		end
		local retryable = err ~= nil or (response ~= nil and should_retry(response.status))
		if retryable and request.retry and attempt < request.retry.max_attempts then
			local delay = retry_delay(request, attempt, response and response.retry_after)
			timer = uv.new_timer()
			timer:start(delay, 0, function()
				close(timer)
				timer = nil
				if active then
					start_attempt()
				end
			end)
			return
		end
		finish(err, response)
	end

	start_attempt = function()
		attempt = attempt + 1
		local stdout = uv.new_pipe(false)
		local stderr = uv.new_pipe(false)
		local stdin = uv.new_pipe(false)
		local output = {}
		local errors = {}
		local exit_code
		local exit_signal
		local stdout_done = false
		local stderr_done = false

		local function maybe_complete()
			if exit_code == nil or not stdout_done or not stderr_done then
				return
			end
			process = nil
			if exit_code ~= 0 then
				local detail = table.concat(errors):gsub("%s+$", "")
				local message = detail ~= "" and detail
					or ("curl exited with code %d (signal %d)"):format(exit_code, exit_signal)
				retry_or_finish({ message = message })
				return
			end
			local response, parse_error = parse_response(table.concat(output))
			if not response then
				retry_or_finish({ message = parse_error })
				return
			end
			retry_or_finish(nil, response)
		end

		local spawn_error
		process, spawn_error = uv.spawn("curl", {
			args = { "-q", "--config", "-" },
			stdio = { stdin, stdout, stderr },
		}, function(code, signal)
			exit_code = code
			exit_signal = signal
			close(process)
			maybe_complete()
		end)
		if not process then
			close(stdin)
			close(stdout)
			close(stderr)
			retry_or_finish({ message = "failed to start curl: " .. tostring(spawn_error) })
			return
		end

		stdout:read_start(function(err, data)
			if err then
				table.insert(errors, err)
			end
			if data then
				table.insert(output, data)
				if request.on_data then
					request.on_data(data)
				end
			else
				stdout_done = true
				close(stdout)
				maybe_complete()
			end
		end)
		stderr:read_start(function(err, data)
			if err then
				table.insert(errors, err)
			end
			if data then
				table.insert(errors, data)
			else
				stderr_done = true
				close(stderr)
				maybe_complete()
			end
		end)
		stdin:write(curl_config(request))
		stdin:shutdown(function()
			close(stdin)
		end)
	end

	start_attempt()

	return function()
		if not active then
			return
		end
		active = false
		if timer then
			timer:stop()
			close(timer)
			timer = nil
		end
		if process and not process:is_closing() then
			process:kill("sigterm")
		end
	end
end

return M
