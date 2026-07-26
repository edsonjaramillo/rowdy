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

local function load_rowdy(transport)
	package.loaded["rowdy"] = nil
	package.loaded["rowdy.transport"] = transport
	return require("rowdy")
end

test("discovers typed Model and Provider endpoint details without setup", function()
	local requests = {}
	local stop_count = 0
	local rowdy = load_rowdy({
		request = function(request, callback)
			table.insert(requests, request)
			callback(nil, {
				status = 200,
				body = vim.json.encode({
					data = {
						id = "openai/gpt-4o-mini",
						name = "OpenAI: GPT-4o-mini",
						unknown_model_field = true,
						endpoints = {
							{
								name = "OpenAI | openai/gpt-4o-mini",
								provider_name = "OpenAI",
								tag = "openai/us",
								context_length = 128000,
								pricing = { prompt = "0.00000015", completion = "0.0000006" },
								unknown_endpoint_field = "ignored",
							},
						},
					},
				}),
			})
			return function()
				stop_count = stop_count + 1
			end
		end,
	})
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret-at-call-time"

	local result
	local callback_was_scheduled = false
	local cancel = rowdy.get_model_endpoints({
		model = "openai/gpt-4o-mini",
		on_complete = function(value)
			result = value
			callback_was_scheduled = vim.in_fast_event() == false
		end,
		on_error = function(err)
			error(vim.inspect(err))
		end,
	})

	assert(result == nil, "completion callback ran before returning to the event loop")
	assert(
		vim.wait(100, function()
			return result ~= nil
		end),
		"completion callback did not run"
	)
	assert(callback_was_scheduled, "completion callback was not safe to call Neovim APIs")
	assert_equal({
		id = "openai/gpt-4o-mini",
		name = "OpenAI: GPT-4o-mini",
		endpoints = {
			{
				name = "OpenAI | openai/gpt-4o-mini",
				provider_name = "OpenAI",
				provider_slug = "openai/us",
				context_length = 128000,
				pricing = { prompt = "0.00000015", completion = "0.0000006" },
			},
		},
	}, result)
	assert_equal({
		model = "openai/gpt-4o-mini",
		api_key = "secret-at-call-time",
		connect_timeout = 10,
		total_timeout = 30,
		retry = {
			max_attempts = 3,
			delays = { 250, 1000 },
			max_retry_after = 5000,
		},
	}, requests[1])
	cancel()
	cancel()
	assert_equal(0, stop_count)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("rejects invalid options synchronously before starting transport", function()
	local request_count = 0
	local rowdy = load_rowdy({
		request = function()
			request_count = request_count + 1
			return function() end
		end,
	})
	local valid = {
		model = "openai/gpt-4o-mini",
		on_complete = function() end,
		on_error = function() end,
	}
	local missing_error = vim.deepcopy(valid)
	missing_error.on_error = nil
	local invalid_options = {
		vim.tbl_extend("force", valid, { typo = true }),
		vim.tbl_extend("force", valid, { model = "gpt-4o-mini" }),
		vim.tbl_extend("force", valid, { model = "openai/gpt 4o" }),
		vim.tbl_extend("force", valid, { model = "openai/team/gpt-4o" }),
		vim.tbl_extend("force", valid, { on_complete = "not a callback" }),
		missing_error,
	}

	for _, options in ipairs(invalid_options) do
		local ok, err = pcall(rowdy.get_model_endpoints, options)
		assert(not ok, "invalid options did not raise")
		assert(type(err) == "string" and err:match("get_model_endpoints"), "error lacked context")
	end
	assert_equal(0, request_count)
end)

test("reports a missing API key asynchronously without starting transport", function()
	local request_count = 0
	local rowdy = load_rowdy({
		request = function()
			request_count = request_count + 1
			return function() end
		end,
	})
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = nil
	local errors = {}

	local cancel = rowdy.get_model_endpoints({
		model = "openai/gpt-4o-mini",
		on_complete = function()
			error("unexpected completion")
		end,
		on_error = function(err)
			table.insert(errors, err)
		end,
	})
	assert_equal(0, #errors)
	cancel()
	assert(
		vim.wait(100, function()
			return #errors > 0
		end),
		"configuration error callback did not run"
	)
	assert_equal(1, #errors)
	assert_equal("configuration", errors[1].kind)
	assert(errors[1].message:match("OPENROUTER_API_KEY"), "error did not identify the missing key")
	assert_equal(0, request_count)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("cancels unfinished curl work exactly once and ignores later outcomes", function()
	local transport_callback
	local stop_count = 0
	local rowdy = load_rowdy({
		request = function(_, callback)
			transport_callback = callback
			return function()
				stop_count = stop_count + 1
			end
		end,
	})
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret"
	local completions = 0
	local errors = {}

	local cancel = rowdy.get_model_endpoints({
		model = "openai/gpt-4o-mini",
		on_complete = function()
			completions = completions + 1
		end,
		on_error = function(err)
			table.insert(errors, err)
		end,
	})
	cancel()
	cancel()
	assert(
		vim.wait(100, function()
			return #errors > 0
		end),
		"cancellation callback did not run"
	)
	assert_equal(1, stop_count)
	assert_equal(1, #errors)
	assert_equal("cancellation", errors[1].kind)

	transport_callback(nil, {
		status = 200,
		body = '{"data":{"id":"openai/gpt-4o-mini","endpoints":[]}}',
	})
	cancel()
	vim.wait(10)
	assert_equal(0, completions)
	assert_equal(1, #errors)
	assert_equal(1, stop_count)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("reports stable typed operational and response failures", function()
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret"
	local cases = {
		{
			name = "transport",
			error = { message = "curl exited with code 6" },
			expected = { kind = "transport" },
		},
		{
			name = "http",
			response = { status = 404, body = '{"not_an_error":true}' },
			expected = { kind = "http", status = 404 },
		},
		{
			name = "gateway",
			response = {
				status = 400,
				body = '{"error":{"message":"Unknown model","code":400}}',
			},
			expected = {
				kind = "gateway",
				status = 400,
				details = { message = "Unknown model", code = 400 },
			},
		},
		{
			name = "response decoding",
			response = { status = 200, body = "not JSON" },
			expected = { kind = "response_decoding", status = 200 },
		},
		{
			name = "missing Provider routing slug",
			response = {
				status = 200,
				body = '{"data":{"id":"openai/gpt-4o-mini","endpoints":[{}]}}',
			},
			expected = { kind = "response_decoding", status = 200 },
		},
		{
			name = "fractional integer field",
			response = {
				status = 200,
				body = '{"data":{"id":"openai/gpt-4o-mini","created":1.5,"endpoints":[]}}',
			},
			expected = { kind = "response_decoding", status = 200 },
		},
	}

	for _, case in ipairs(cases) do
		local rowdy = load_rowdy({
			request = function(_, callback)
				callback(case.error, case.response)
				callback(case.error, case.response)
				return function() end
			end,
		})
		local errors = {}
		rowdy.get_model_endpoints({
			model = "openai/gpt-4o-mini",
			on_complete = function()
				error("unexpected completion for " .. case.name)
			end,
			on_error = function(err)
				table.insert(errors, err)
			end,
		})
		assert(
			vim.wait(100, function()
				return #errors > 0
			end),
			case.name .. " callback did not run"
		)
		assert_equal(1, #errors)
		assert(type(errors[1].message) == "string" and errors[1].message ~= "", "missing message")
		for field, expected in pairs(case.expected) do
			assert_equal(expected, errors[1][field])
		end
	end

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("runs curl securely with bounded retries and discovery timeouts", function()
	local previous_path = vim.env.PATH
	local previous_key = vim.env.OPENROUTER_API_KEY
	local state = vim.fn.tempname()
	vim.env.PATH = vim.fn.getcwd() .. "/tests/fixtures:" .. previous_path
	vim.env.OPENROUTER_API_KEY = "secret-not-in-argv"
	vim.env.ROWDY_CURL_SCENARIO = "retry"
	vim.env.ROWDY_CURL_STATE = state
	local rowdy = load_rowdy(nil)
	local result
	local failure

	rowdy.get_model_endpoints({
		model = "openai/gpt-4o-mini",
		on_complete = function(value)
			result = value
		end,
		on_error = function(err)
			failure = err
		end,
	})
	assert(
		vim.wait(3000, function()
			return result ~= nil or failure ~= nil
		end),
		"curl retries did not settle"
	)
	assert(failure == nil, vim.inspect(failure))
	assert_equal("openai", result.endpoints[1].provider_slug)
	assert_equal({ "3" }, vim.fn.readfile(state))

	os.remove(state)
	vim.env.PATH = previous_path
	vim.env.OPENROUTER_API_KEY = previous_key
	vim.env.ROWDY_CURL_SCENARIO = nil
	vim.env.ROWDY_CURL_STATE = nil
end)

test("terminates a live curl process when cancelled", function()
	local previous_path = vim.env.PATH
	local previous_key = vim.env.OPENROUTER_API_KEY
	local state = vim.fn.tempname()
	vim.env.PATH = vim.fn.getcwd() .. "/tests/fixtures:" .. previous_path
	vim.env.OPENROUTER_API_KEY = "secret-not-in-argv"
	vim.env.ROWDY_CURL_SCENARIO = "cancel"
	vim.env.ROWDY_CURL_STATE = state
	local rowdy = load_rowdy(nil)
	local errors = {}

	local cancel = rowdy.get_model_endpoints({
		model = "openai/gpt-4o-mini",
		on_complete = function()
			error("unexpected completion")
		end,
		on_error = function(err)
			table.insert(errors, err)
		end,
	})
	assert(
		vim.wait(500, function()
			return vim.uv.fs_stat(state) ~= nil
		end),
		"fake curl did not start"
	)
	local pid = tonumber(vim.fn.readfile(state)[1])
	cancel()
	assert(
		vim.wait(500, function()
			return #errors == 1
		end),
		"cancellation callback did not run"
	)
	assert_equal("cancellation", errors[1].kind)
	assert(
		vim.wait(1000, function()
			return vim.uv.kill(pid, 0) == nil
		end),
		"curl process remained alive after cancellation"
	)

	os.remove(state)
	vim.env.PATH = previous_path
	vim.env.OPENROUTER_API_KEY = previous_key
	vim.env.ROWDY_CURL_SCENARIO = nil
	vim.env.ROWDY_CURL_STATE = nil
end)

test("cancels during a capped HTTP-date retry backoff", function()
	local previous_path = vim.env.PATH
	local previous_key = vim.env.OPENROUTER_API_KEY
	local state = vim.fn.tempname()
	vim.env.PATH = vim.fn.getcwd() .. "/tests/fixtures:" .. previous_path
	vim.env.OPENROUTER_API_KEY = "secret-not-in-argv"
	vim.env.ROWDY_CURL_SCENARIO = "backoff"
	vim.env.ROWDY_CURL_STATE = state
	vim.env.ROWDY_RETRY_AFTER = "Wed, 21 Oct 2099 07:28:00 GMT"
	local rowdy = load_rowdy(nil)
	local errors = {}

	local cancel = rowdy.get_model_endpoints({
		model = "openai/gpt-4o-mini",
		on_complete = function()
			error("unexpected completion")
		end,
		on_error = function(err)
			table.insert(errors, err)
		end,
	})
	assert(
		vim.wait(500, function()
			return vim.uv.fs_stat(state) ~= nil
		end),
		"fake curl did not start"
	)
	vim.wait(500)
	assert_equal({ "1" }, vim.fn.readfile(state))
	cancel()
	assert(
		vim.wait(500, function()
			return #errors == 1
		end),
		"cancellation callback did not run"
	)
	vim.wait(100)
	assert_equal({ "1" }, vim.fn.readfile(state))

	os.remove(state)
	vim.env.PATH = previous_path
	vim.env.OPENROUTER_API_KEY = previous_key
	vim.env.ROWDY_CURL_SCENARIO = nil
	vim.env.ROWDY_CURL_STATE = nil
	vim.env.ROWDY_RETRY_AFTER = nil
end)

return tests
