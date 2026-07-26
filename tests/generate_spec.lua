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

local function options(overrides)
	return vim.tbl_extend("force", {
		prompt = "Explain explicit routing.",
		model = "openai/gpt-4o-mini",
		provider = "openai",
		stream = false,
		on_complete = function() end,
		on_error = function() end,
	}, overrides or {})
end

test("generates final text through exactly one Provider without setup", function()
	local requests = {}
	local rowdy = load_rowdy({
		request = function(request, callback)
			table.insert(requests, request)
			callback(nil, {
				status = 200,
				body = vim.json.encode({
					id = "gen-123",
					model = "openai/gpt-4o-mini-2024-07-18",
					choices = {
						{
							text = "Routing is explicit.",
							finish_reason = "stop",
							native_finish_reason = "stop",
							unknown_choice_field = true,
						},
					},
					usage = {
						prompt_tokens = 5,
						completion_tokens = 4,
						total_tokens = 9,
						cost = 0.00001,
						is_byok = false,
						prompt_tokens_details = { cached_tokens = 2, cache_write_tokens = 1 },
						completion_tokens_details = { reasoning_tokens = 3 },
						cost_details = {
							upstream_inference_cost = 0.000009,
							upstream_inference_prompt_cost = 0.000003,
							upstream_inference_completions_cost = 0.000006,
						},
						server_tool_use = { web_search_requests = 1 },
						unknown_usage_field = "ignored",
					},
					unknown_response_field = true,
				}),
			})
			return function() end
		end,
	})
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret-at-call-time"
	local result
	local scheduled = false

	local cancel = rowdy.generate(options({
		on_complete = function(value)
			result = value
			scheduled = vim.in_fast_event() == false
		end,
		on_error = function(err)
			error(vim.inspect(err))
		end,
	}))

	assert(result == nil, "completion callback ran before returning to the event loop")
	assert(
		vim.wait(100, function()
			return result ~= nil
		end),
		"completion callback did not run"
	)
	assert(scheduled, "completion callback was not safe to call Neovim APIs")
	assert_equal({
		text = "Routing is explicit.",
		finish_reason = "stop",
		request_id = "gen-123",
		model_id = "openai/gpt-4o-mini-2024-07-18",
		usage = {
			prompt_tokens = 5,
			completion_tokens = 4,
			total_tokens = 9,
			cost = 0.00001,
			is_byok = false,
			prompt_tokens_details = { cached_tokens = 2, cache_write_tokens = 1 },
			completion_tokens_details = { reasoning_tokens = 3 },
			cost_details = {
				upstream_inference_cost = 0.000009,
				upstream_inference_prompt_cost = 0.000003,
				upstream_inference_completions_cost = 0.000006,
			},
			server_tool_use = { web_search_requests = 1 },
		},
	}, result)
	assert_equal({
		method = "POST",
		path = "/chat/completions",
		api_key = "secret-at-call-time",
		connect_timeout = 10,
		body = vim.json.encode({
			model = "openai/gpt-4o-mini",
			prompt = "Explain explicit routing.",
			provider = { order = { "openai" }, allow_fallbacks = false },
			stream = false,
		}),
	}, requests[1])
	cancel()

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("passes base and endpoint Provider slugs directly to the Gateway", function()
	local providers = {}
	local rowdy = load_rowdy({
		request = function(request, callback)
			table.insert(providers, vim.json.decode(request.body).provider.order[1])
			callback(nil, {
				status = 200,
				body = '{"id":"gen-1","model":"author/model","choices":[{"text":"ok","finish_reason":"stop"}]}',
			})
			return function() end
		end,
	})
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret"

	for _, provider in ipairs({ "google-vertex", "google-vertex/us-east5", "deepinfra/turbo" }) do
		rowdy.generate(options({ provider = provider }))
	end
	assert_equal({ "google-vertex", "google-vertex/us-east5", "deepinfra/turbo" }, providers)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("tolerates absent optional generation metadata", function()
	local rowdy = load_rowdy({
		request = function(_, callback)
			callback(nil, {
				status = 200,
				body = '{"id":"gen-1","model":"author/model","choices":[{"text":"ok","finish_reason":null}]}',
			})
			return function() end
		end,
	})
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret"
	local result

	rowdy.generate(options({
		on_complete = function(value)
			result = value
		end,
	}))
	assert(
		vim.wait(100, function()
			return result ~= nil
		end),
		"completion callback did not run"
	)
	assert_equal({ text = "ok", request_id = "gen-1", model_id = "author/model" }, result)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("rejects malformed generation options before starting transport", function()
	local request_count = 0
	local rowdy = load_rowdy({
		request = function()
			request_count = request_count + 1
			return function() end
		end,
	})
	local valid = options()
	local missing_error = vim.deepcopy(valid)
	missing_error.on_error = nil
	local invalid_options = {
		vim.tbl_extend("force", valid, { typo = true }),
		vim.tbl_extend("force", valid, { prompt = "" }),
		vim.tbl_extend("force", valid, { prompt = 7 }),
		vim.tbl_extend("force", valid, { model = "gpt-4o-mini" }),
		vim.tbl_extend("force", valid, { provider = "" }),
		vim.tbl_extend("force", valid, { provider = "open ai" }),
		vim.tbl_extend("force", valid, { stream = true }),
		vim.tbl_extend("force", valid, { on_complete = "callback" }),
		missing_error,
	}

	local ok, err = pcall(rowdy.generate, nil)
	assert(not ok, "nil generation options did not raise")
	assert(type(err) == "string" and err:match("generate"), "error lacked context")
	for _, invalid in ipairs(invalid_options) do
		ok, err = pcall(rowdy.generate, invalid)
		assert(not ok, "invalid generation options did not raise")
		assert(type(err) == "string" and err:match("generate"), "error lacked context")
	end
	assert_equal(0, request_count)
end)

test("reports missing generation authentication asynchronously", function()
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

	rowdy.generate(options({
		on_error = function(err)
			table.insert(errors, err)
		end,
	}))
	assert_equal(0, #errors)
	assert(
		vim.wait(100, function()
			return #errors == 1
		end),
		"configuration callback did not run"
	)
	assert_equal("configuration", errors[1].kind)
	assert(errors[1].message:match("OPENROUTER_API_KEY"), "error did not identify the key")
	assert_equal(0, request_count)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("reports typed generation failures exactly once without retries", function()
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret"
	local cases = {
		{ error = { message = "curl exited with code 6" }, expected = { kind = "transport" } },
		{
			response = { status = 502, body = '{"not_an_error":true}' },
			expected = { kind = "http", status = 502 },
		},
		{
			response = {
				status = 400,
				body = '{"error":{"message":"No endpoints found","code":404,"metadata":{"provider":"openai"}}}',
			},
			expected = {
				kind = "gateway",
				status = 400,
				details = {
					message = "No endpoints found",
					code = 404,
					metadata = { provider = "openai" },
				},
			},
		},
		{
			response = {
				status = 200,
				body = '{"id":"gen-1","model":"author/model","choices":[{"text":"partial","finish_reason":"error","error":{"code":502,"message":"Provider failed","metadata":{"provider":"openai"}}}]}',
			},
			expected = {
				kind = "gateway",
				status = 200,
				partial_text = "partial",
				details = {
					code = 502,
					message = "Provider failed",
					metadata = { provider = "openai" },
				},
			},
		},
		{
			response = { status = 400, body = '{"error":{"message":"missing code"}}' },
			expected = { kind = "response_decoding", status = 400 },
		},
		{
			response = { status = 200, body = "not JSON" },
			expected = { kind = "response_decoding", status = 200 },
		},
		{
			response = { status = 200, body = '{"id":"gen-1","model":"author/model","choices":[]}' },
			expected = { kind = "response_decoding", status = 200 },
		},
	}

	for _, case in ipairs(cases) do
		local request_count = 0
		local rowdy = load_rowdy({
			request = function(request, callback)
				request_count = request_count + 1
				assert(request.retry == nil, "generation enabled transport retries")
				callback(case.error, case.response)
				callback(case.error, case.response)
				return function() end
			end,
		})
		local errors = {}
		rowdy.generate(options({
			on_complete = function()
				error("unexpected completion")
			end,
			on_error = function(err)
				table.insert(errors, err)
			end,
		}))
		assert(
			vim.wait(100, function()
				return #errors == 1
			end),
			"error callback did not run"
		)
		assert_equal(1, request_count)
		assert(type(errors[1].message) == "string" and errors[1].message ~= "", "missing message")
		for field, expected in pairs(case.expected) do
			assert_equal(expected, errors[1][field])
		end
	end

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("cancels unfinished generation exactly once on Neovim's main loop", function()
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
	local scheduled = false

	local cancel = rowdy.generate(options({
		on_complete = function()
			completions = completions + 1
		end,
		on_error = function(err)
			table.insert(errors, err)
			scheduled = vim.in_fast_event() == false
		end,
	}))
	cancel()
	cancel()
	assert(
		vim.wait(100, function()
			return #errors == 1
		end),
		"cancellation callback did not run"
	)
	assert(scheduled, "cancellation callback was not safe to call Neovim APIs")
	assert_equal(1, stop_count)
	assert_equal("cancellation", errors[1].kind)

	transport_callback(nil, {
		status = 200,
		body = '{"id":"gen-1","model":"author/model","choices":[{"text":"late","finish_reason":"stop"}]}',
	})
	cancel()
	vim.wait(10)
	assert_equal(0, completions)
	assert_equal(1, #errors)
	assert_equal(1, stop_count)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("runs non-streaming curl without sensitive argv, retries, or a total timeout", function()
	local previous_path = vim.env.PATH
	local previous_key = vim.env.OPENROUTER_API_KEY
	local state = vim.fn.tempname()
	vim.env.PATH = vim.fn.getcwd() .. "/tests/fixtures:" .. previous_path
	vim.env.OPENROUTER_API_KEY = "generation-secret-not-in-argv"
	vim.env.ROWDY_CURL_SCENARIO = "generate"
	vim.env.ROWDY_CURL_STATE = state
	local rowdy = load_rowdy(nil)
	local result
	local failure

	rowdy.generate(options({
		prompt = "sensitive prompt not in argv or files",
		provider = "deepinfra/turbo",
		on_complete = function(value)
			result = value
		end,
		on_error = function(err)
			failure = err
		end,
	}))
	assert(
		vim.wait(1000, function()
			return result ~= nil or failure ~= nil
		end),
		"generation curl did not settle"
	)
	assert(failure == nil, vim.inspect(failure))
	assert_equal("secure", result.text)
	assert_equal({ "1" }, vim.fn.readfile(state))

	os.remove(state)
	vim.env.PATH = previous_path
	vim.env.OPENROUTER_API_KEY = previous_key
	vim.env.ROWDY_CURL_SCENARIO = nil
	vim.env.ROWDY_CURL_STATE = nil
end)

return tests
