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

test("discovers an unfiltered typed Model catalog without setup", function()
	local requests = {}
	local rowdy = load_rowdy({
		request = function(request, callback)
			table.insert(requests, request)
			callback(nil, {
				status = 200,
				body = vim.json.encode({
					data = {
						{
							id = "openai/gpt-4o-mini",
							canonical_slug = "openai/gpt-4o-mini-2024-07-18",
							name = "OpenAI: GPT-4o-mini",
							created = 1721433600,
							description = "A compact multimodal Model.",
							context_length = 128000,
							architecture = {
								modality = "text+image->text",
								input_modalities = { "text", "image" },
								output_modalities = { "text" },
								tokenizer = "GPT",
								instruct_type = "chatml",
							},
							pricing = {
								prompt = "0.00000015",
								completion = "0.0000006",
								input_cache_read = "0.000000075",
								discount = 0.1,
								overrides = {
									{ min_prompt_tokens = 200000, prompt = "0.0000003" },
								},
							},
							default_parameters = { temperature = 0.7, top_k = 40 },
							links = { details = "/api/v1/models/openai/gpt-4o-mini/endpoints" },
							alias_target = { slug = "openai/gpt-4o-mini", name = "GPT-4o mini" },
							reasoning = {
								mandatory = false,
								default_enabled = true,
								default_effort = "medium",
								supported_efforts = { "high", vim.NIL, "low" },
							},
							benchmarks = {
								artificial_analysis = {
									intelligence_index = 60.5,
									coding_index = 55.2,
									agentic_index = 42.1,
								},
								design_arena = {
									{
										arena = "models",
										category = "website",
										elo = 1385.2,
										win_rate = 62.5,
										rank = 5,
									},
								},
							},
							top_provider = {
								context_length = 128000,
								max_completion_tokens = 16384,
								is_moderated = true,
							},
							per_request_limits = {
								prompt_tokens = 100000,
								completion_tokens = 12000,
							},
							supported_parameters = { "temperature", "tools" },
							supported_voices = vim.NIL,
							unknown_model_field = "ignored",
						},
						{
							id = "openai/gpt-image-1",
							canonical_slug = "openai/gpt-image-1",
							name = "GPT Image 1",
							created = 1743465600,
							architecture = {
								modality = vim.NIL,
								input_modalities = { "text", "image" },
								output_modalities = { "image" },
							},
							pricing = { prompt = "0", completion = "0" },
							top_provider = { is_moderated = false },
							supported_parameters = {},
							links = { details = "/api/v1/models/openai/gpt-image-1/endpoints" },
							context_length = vim.NIL,
							default_parameters = vim.NIL,
							per_request_limits = vim.NIL,
							supported_voices = vim.NIL,
							unknown_model_field = true,
						},
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
	local callback_was_scheduled = false

	local cancel = rowdy.get_models({
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
		{
			id = "openai/gpt-4o-mini",
			canonical_slug = "openai/gpt-4o-mini-2024-07-18",
			name = "OpenAI: GPT-4o-mini",
			created = 1721433600,
			description = "A compact multimodal Model.",
			context_length = 128000,
			architecture = {
				modality = "text+image->text",
				input_modalities = { "text", "image" },
				output_modalities = { "text" },
				tokenizer = "GPT",
				instruct_type = "chatml",
			},
			pricing = {
				prompt = "0.00000015",
				completion = "0.0000006",
				input_cache_read = "0.000000075",
				discount = 0.1,
				overrides = {
					{ min_prompt_tokens = 200000, prompt = "0.0000003" },
				},
			},
			default_parameters = { temperature = 0.7, top_k = 40 },
			links = { details = "/api/v1/models/openai/gpt-4o-mini/endpoints" },
			alias_target = { slug = "openai/gpt-4o-mini", name = "GPT-4o mini" },
			reasoning = {
				mandatory = false,
				default_enabled = true,
				default_effort = "medium",
				supported_efforts = { "high", vim.NIL, "low" },
			},
			benchmarks = {
				artificial_analysis = {
					intelligence_index = 60.5,
					coding_index = 55.2,
					agentic_index = 42.1,
				},
				design_arena = {
					{
						arena = "models",
						category = "website",
						elo = 1385.2,
						win_rate = 62.5,
						rank = 5,
					},
				},
			},
			top_provider = {
				context_length = 128000,
				max_completion_tokens = 16384,
				is_moderated = true,
			},
			per_request_limits = {
				prompt_tokens = 100000,
				completion_tokens = 12000,
			},
			supported_parameters = { "temperature", "tools" },
		},
		{
			id = "openai/gpt-image-1",
			canonical_slug = "openai/gpt-image-1",
			name = "GPT Image 1",
			created = 1743465600,
			architecture = {
				input_modalities = { "text", "image" },
				output_modalities = { "image" },
			},
			pricing = { prompt = "0", completion = "0" },
			top_provider = { is_moderated = false },
			supported_parameters = {},
			links = { details = "/api/v1/models/openai/gpt-image-1/endpoints" },
		},
	}, result)
	assert_equal({
		path = "/models",
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

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("encodes documented categorical Model filters without implicit modalities", function()
	local requests = {}
	local rowdy = load_rowdy({
		request = function(request, callback)
			table.insert(requests, request)
			callback(nil, { status = 200, body = '{"data":[]}' })
			return function() end
		end,
	})
	local previous_key = vim.env.OPENROUTER_API_KEY
	vim.env.OPENROUTER_API_KEY = "secret"

	rowdy.get_models({
		search = "vision models",
		category = "programming",
		supported_parameters = { "tools", "response_format" },
		input_modalities = { "text", "image" },
		output_modalities = { "text" },
		architecture = "GPT",
		model_authors = { "openai", "anthropic" },
		providers = { "OpenAI", "Together AI" },
		distillable = false,
		zero_data_retention = true,
		region = "eu",
		on_complete = function() end,
		on_error = function(err)
			error(vim.inspect(err))
		end,
	})

	assert_equal(1, #requests)
	assert_equal(
		"/models?q=vision%20models&category=programming&supported_parameters=tools,response_format"
			.. "&input_modalities=text,image&output_modalities=text&arch=GPT"
			.. "&model_authors=openai,anthropic&providers=OpenAI,Together%20AI"
			.. "&distillable=false&zdr=true&region=eu",
		requests[1].path
	)

	rowdy.get_models({
		category = "marketing/seo",
		output_modalities = { "all" },
		on_complete = function() end,
		on_error = function(err)
			error(vim.inspect(err))
		end,
	})
	assert_equal("/models?category=marketing%2Fseo&output_modalities=all", requests[2].path)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("rejects invalid Model discovery options before starting transport", function()
	local request_count = 0
	local rowdy = load_rowdy({
		request = function()
			request_count = request_count + 1
			return function() end
		end,
	})
	local valid = {
		on_complete = function() end,
		on_error = function() end,
	}
	local missing_error = vim.deepcopy(valid)
	missing_error.on_error = nil
	local invalid_options = {
		vim.tbl_extend("force", valid, { unsupported_filter = true }),
		vim.tbl_extend("force", valid, { search = "" }),
		vim.tbl_extend("force", valid, { architecture = "GPT\nClaude" }),
		vim.tbl_extend("force", valid, { category = "chat" }),
		vim.tbl_extend("force", valid, { supported_parameters = "tools" }),
		vim.tbl_extend("force", valid, { supported_parameters = {} }),
		vim.tbl_extend("force", valid, { input_modalities = { "video" } }),
		vim.tbl_extend("force", valid, { output_modalities = { "all", "text" } }),
		vim.tbl_extend("force", valid, { model_authors = { "openai,anthropic" } }),
		vim.tbl_extend("force", valid, { providers = { "OpenAI", 7 } }),
		vim.tbl_extend("force", valid, { distillable = "true" }),
		vim.tbl_extend("force", valid, { zero_data_retention = false }),
		vim.tbl_extend("force", valid, { region = "us" }),
		vim.tbl_extend("force", valid, { on_complete = "not a callback" }),
		missing_error,
	}

	for _, options in ipairs(invalid_options) do
		local ok, err = pcall(rowdy.get_models, options)
		assert(not ok, "invalid options did not raise")
		assert(type(err) == "string" and err:match("get_models"), "error lacked context")
	end
	assert_equal(0, request_count)
end)

test("reports missing Model discovery authentication asynchronously", function()
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

	local cancel = rowdy.get_models({
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

test("cancels Model discovery exactly once and ignores later outcomes", function()
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
	local callback_was_scheduled = false

	local cancel = rowdy.get_models({
		on_complete = function()
			completions = completions + 1
		end,
		on_error = function(err)
			table.insert(errors, err)
			callback_was_scheduled = vim.in_fast_event() == false
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
	assert(callback_was_scheduled, "cancellation callback was not safe to call Neovim APIs")
	assert_equal(1, stop_count)
	assert_equal(1, #errors)
	assert_equal("cancellation", errors[1].kind)

	transport_callback(nil, { status = 200, body = '{"data":[]}' })
	cancel()
	vim.wait(10)
	assert_equal(0, completions)
	assert_equal(1, #errors)
	assert_equal(1, stop_count)

	vim.env.OPENROUTER_API_KEY = previous_key
end)

test("reports typed Model discovery failures exactly once", function()
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
			response = { status = 400, body = '{"error":{"message":"Invalid filters","code":400}}' },
			expected = {
				kind = "gateway",
				status = 400,
				details = { message = "Invalid filters", code = 400 },
			},
		},
		{
			name = "invalid JSON",
			response = { status = 200, body = "not JSON" },
			expected = { kind = "response_decoding", status = 200 },
		},
		{
			name = "incomplete Model",
			response = { status = 200, body = '{"data":[{"id":"openai/test"}]}' },
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
		rowdy.get_models({
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

return tests
