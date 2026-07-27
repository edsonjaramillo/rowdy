local tests = {}

local function test(name, run)
	table.insert(tests, { name = name, run = run })
end

local function assert_equal(expected, actual)
	assert(
		vim.deep_equal(expected, actual),
		("expected %s, got %s"):format(vim.inspect(expected), vim.inspect(actual))
	)
end

local function read_attempts(path)
	if vim.uv.fs_stat(path) == nil then
		return 0
	end
	return tonumber(vim.fn.readfile(path)[1])
end

local function start_discovery(outcomes, retry_after, discovery)
	local real_uv = vim.uv
	local timers = {}
	local controlled_uv = setmetatable({}, { __index = real_uv })
	controlled_uv.new_timer = function()
		local timer = { closing = false, stopped = false }
		function timer:start(delay, _, callback)
			self.delay = delay
			self.callback = callback
			table.insert(timers, self)
		end
		function timer:stop()
			self.stopped = true
		end
		function timer:is_closing()
			return self.closing
		end
		function timer:close()
			self.closing = true
		end
		return timer
	end

	local previous_environment = {}
	for _, name in ipairs({
		"PATH",
		"OPENROUTER_API_KEY",
		"ROWDY_CURL_SCENARIO",
		"ROWDY_CURL_OUTCOMES",
		"ROWDY_CURL_DISCOVERY",
		"ROWDY_CURL_STATE",
		"ROWDY_RETRY_AFTER",
	}) do
		previous_environment[name] = vim.env[name] or vim.NIL
	end
	local state = vim.fn.tempname()
	vim.env.PATH = vim.fn.getcwd() .. "/tests/fixtures:" .. previous_environment.PATH
	vim.env.OPENROUTER_API_KEY = "secret"
	vim.env.ROWDY_CURL_SCENARIO = "outcomes"
	vim.env.ROWDY_CURL_OUTCOMES = outcomes
	vim.env.ROWDY_CURL_DISCOVERY = discovery
	vim.env.ROWDY_CURL_STATE = state
	vim.env.ROWDY_RETRY_AFTER = retry_after
	vim.uv = controlled_uv
	package.loaded["rowdy"] = nil
	package.loaded["rowdy.transport"] = nil
	local rowdy = require("rowdy")
	vim.uv = real_uv

	local result
	local errors = {}
	local options = {
		on_complete = function(value)
			result = value
		end,
		on_error = function(err)
			table.insert(errors, err)
		end,
	}
	local cancel
	if discovery == "models" then
		cancel = rowdy.get_models(options)
	else
		options.model = "openai/gpt-4o-mini"
		cancel = rowdy.get_model_endpoints(options)
	end

	local operation = {}
	function operation:wait_for_attempt(count)
		assert(
			vim.wait(500, function()
				return read_attempts(state) == count
			end),
			("curl attempt %d did not start"):format(count)
		)
	end
	function operation:advance_retry(number)
		assert(
			vim.wait(500, function()
				return timers[number] ~= nil
			end),
			("retry timer %d was not created"):format(number)
		)
		timers[number].callback()
	end
	function operation:wait_for_retry(number)
		assert(
			vim.wait(500, function()
				return timers[number] ~= nil
			end),
			("retry timer %d was not created"):format(number)
		)
	end
	function operation:wait_until_settled()
		assert(
			vim.wait(500, function()
				return result ~= nil or #errors > 0
			end),
			"discovery did not settle"
		)
	end
	function operation:cleanup()
		cancel()
		os.remove(state)
		for name, value in pairs(previous_environment) do
			vim.env[name] = value ~= vim.NIL and value or nil
		end
	end
	operation.timers = timers
	operation.errors = errors
	operation.cancel = cancel
	operation.result = function()
		return result
	end
	return operation
end

local function with_discovery(outcomes, retry_after, run, discovery)
	local operation = start_discovery(outcomes, retry_after, discovery)
	local ok, err = xpcall(function()
		run(operation)
	end, debug.traceback)
	operation:cleanup()
	if not ok then
		error(err, 0)
	end
end

test(
	"retries transport failures with both default delays and stops after three attempts",
	function()
		with_discovery("transport transport transport", nil, function(operation)
			operation:wait_for_attempt(1)
			operation:advance_retry(1)
			operation:wait_for_attempt(2)
			operation:advance_retry(2)
			operation:wait_for_attempt(3)
			operation:wait_until_settled()

			assert_equal({ 250, 1000 }, { operation.timers[1].delay, operation.timers[2].delay })
			assert_equal(2, #operation.timers)
			assert_equal(1, #operation.errors)
			assert_equal("transport", operation.errors[1].kind)
		end)
	end
)

test("retries HTTP 408, 429, and the complete 5xx range only", function()
	for _, status in ipairs({ 408, 429, 500, 599 }) do
		with_discovery(("%d 200"):format(status), nil, function(operation)
			operation:wait_for_attempt(1)
			operation:advance_retry(1)
			operation:wait_for_attempt(2)
			operation:wait_until_settled()
			assert(operation.result() ~= nil, ("HTTP %d was not retried"):format(status))
			assert_equal(1, #operation.timers)
		end)
	end

	for _, status in ipairs({ 400, 499, 600 }) do
		with_discovery(tostring(status), nil, function(operation)
			operation:wait_for_attempt(1)
			operation:wait_until_settled()
			assert_equal(0, #operation.timers)
			assert_equal(status, operation.errors[1].status)
		end)
	end
end)

test("does not retry Gateway application failures with retryable HTTP statuses", function()
	with_discovery("gateway", nil, function(operation)
		operation:wait_for_attempt(1)
		operation:wait_until_settled()
		assert_equal(0, #operation.timers)
		assert_equal(1, #operation.errors)
		assert_equal("gateway", operation.errors[1].kind)
	end)
end)

test("caps numeric Retry-After guidance at five seconds", function()
	with_discovery("429 200", "10", function(operation)
		operation:wait_for_attempt(1)
		operation:wait_for_retry(1)
		assert_equal(5000, operation.timers[1].delay)
		operation:advance_retry(1)
		operation:wait_for_attempt(2)
		operation:wait_until_settled()
		assert(operation.result() ~= nil, "discovery did not recover after Retry-After")
	end)
end)

test("ignores malformed Retry-After guidance", function()
	for _, retry_after in ipairs({ "1.5", "Fri Nov   6 08:49:37 2099" }) do
		with_discovery("429 200", retry_after, function(operation)
			operation:wait_for_attempt(1)
			operation:wait_for_retry(1)
			assert_equal(250, operation.timers[1].delay)
			operation:advance_retry(1)
			operation:wait_for_attempt(2)
			operation:wait_until_settled()
		end)
	end
end)

test("accepts obsolete HTTP-date Retry-After guidance", function()
	for _, retry_after in ipairs({
		"Friday, 06-Nov-49 08:49:37 GMT",
		"Fri Nov  6 08:49:37 2099",
	}) do
		with_discovery("429 200", retry_after, function(operation)
			operation:wait_for_attempt(1)
			operation:wait_for_retry(1)
			assert_equal(5000, operation.timers[1].delay)
			operation:advance_retry(1)
			operation:wait_for_attempt(2)
			operation:wait_until_settled()
		end)
	end
end)

test("retries Model discovery failures", function()
	with_discovery("503 200", nil, function(operation)
		operation:wait_for_attempt(1)
		operation:advance_retry(1)
		operation:wait_for_attempt(2)
		operation:wait_until_settled()
		assert_equal({}, operation.result())
		assert_equal(0, #operation.errors)
	end, "models")
end)

test("cancels during retry backoff without another attempt", function()
	with_discovery("503 200", nil, function(operation)
		operation:wait_for_attempt(1)
		operation:wait_for_retry(1)
		assert_equal(250, operation.timers[1].delay)
		operation.cancel()
		operation.cancel()
		operation:wait_until_settled()
		operation.timers[1].callback()
		vim.wait(50)

		assert(operation.timers[1].stopped, "retry timer was not stopped")
		assert_equal(1, #operation.errors)
		assert_equal("cancellation", operation.errors[1].kind)
	end)
end)

return tests
