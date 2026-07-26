local transport = require("rowdy.transport")

---@class RowdyPricing
---@field prompt string
---@field completion string
---@field request? string
---@field image? string
---@field audio? string
---@field audio_output? string
---@field image_output? string
---@field image_token? string
---@field input_audio_cache? string
---@field input_cache_read? string
---@field input_cache_write? string
---@field input_cache_write_1h? string
---@field internal_reasoning? string
---@field web_search? string
---@field discount? number
---@field overrides? RowdyPricingOverride[]

---@class RowdyPricingOverride
---@field prompt? string
---@field completion? string
---@field audio? string
---@field input_audio_cache? string
---@field input_cache_read? string
---@field input_cache_write? string
---@field input_cache_write_1h? string
---@field min_prompt_tokens? number
---@field utc_start? number
---@field utc_end? number

---@class RowdyTopProvider
---@field context_length? integer
---@field max_completion_tokens? integer
---@field is_moderated boolean

---@class RowdyPerRequestLimits
---@field prompt_tokens? number
---@field completion_tokens? number

---@class RowdyDefaultParameters
---@field frequency_penalty? number
---@field presence_penalty? number
---@field repetition_penalty? number
---@field temperature? number
---@field top_k? integer
---@field top_p? number

---@class RowdyModelLinks
---@field details string

---@class RowdyModelAliasTarget
---@field slug string
---@field name string

---@class RowdyModelReasoning
---@field mandatory boolean
---@field default_enabled? boolean
---@field supports_max_tokens? boolean
---@field default_effort? string
---@field supported_efforts? (string|userdata)[]

---@class RowdyArtificialAnalysisBenchmarks
---@field intelligence_index? number
---@field coding_index? number
---@field agentic_index? number

---@class RowdyDesignArenaBenchmark
---@field arena string
---@field category string
---@field elo number
---@field win_rate number
---@field rank integer

---@class RowdyModelBenchmarks
---@field artificial_analysis? RowdyArtificialAnalysisBenchmarks
---@field design_arena RowdyDesignArenaBenchmark[]

---@class RowdyModelArchitecture
---@field tokenizer? string
---@field instruct_type? string
---@field modality? string
---@field input_modalities string[]
---@field output_modalities string[]

---@class RowdyProviderEndpoint
---@field name? string
---@field model_id? string
---@field model_name? string
---@field provider_name? string
---@field provider_slug string
---@field context_length? integer
---@field pricing? RowdyPricing
---@field quantization? string
---@field max_completion_tokens? integer
---@field max_prompt_tokens? integer
---@field supported_parameters? string[]
---@field status? integer
---@field uptime_last_30m? number

---@class RowdyModelEndpoints
---@field id string
---@field name? string
---@field created? integer
---@field description? string
---@field architecture? RowdyModelArchitecture
---@field endpoints RowdyProviderEndpoint[]

---@class RowdyModel
---@field id string
---@field canonical_slug string
---@field hugging_face_id? string
---@field name string
---@field created integer
---@field description? string
---@field context_length? integer
---@field expiration_date? string
---@field knowledge_cutoff? string
---@field architecture RowdyModelArchitecture
---@field pricing RowdyPricing
---@field top_provider RowdyTopProvider
---@field per_request_limits? RowdyPerRequestLimits
---@field default_parameters? RowdyDefaultParameters
---@field links RowdyModelLinks
---@field alias_target? RowdyModelAliasTarget
---@field reasoning? RowdyModelReasoning
---@field benchmarks? RowdyModelBenchmarks
---@field supported_parameters string[]
---@field supported_voices? string[]

---@class RowdyError
---@field kind 'configuration'|'cancellation'|'transport'|'http'|'gateway'|'response_decoding'
---@field message string
---@field status? integer
---@field details? table

---@class RowdyGetModelEndpointsOptions
---@field model string
---@field on_complete fun(result: RowdyModelEndpoints)
---@field on_error fun(error: RowdyError)

---@class RowdyGetModelsOptions
---@field on_complete fun(result: RowdyModel[])
---@field on_error fun(error: RowdyError)

local M = {}

local endpoint_model_field_types = {
	name = "string",
	created = "integer",
	description = "string",
}
local catalog_model_field_types = {
	canonical_slug = "string",
	hugging_face_id = "string",
	name = "string",
	created = "integer",
	description = "string",
	context_length = "integer",
	expiration_date = "string",
	knowledge_cutoff = "string",
}
local endpoint_field_types = {
	name = "string",
	model_id = "string",
	model_name = "string",
	provider_name = "string",
	context_length = "integer",
	quantization = "string",
	max_completion_tokens = "integer",
	max_prompt_tokens = "integer",
	status = "integer",
	uptime_last_30m = "number",
}
local architecture_field_types = {
	tokenizer = "string",
	instruct_type = "string",
	modality = "string",
}
local pricing_fields = {
	"prompt",
	"completion",
	"request",
	"image",
	"audio",
	"audio_output",
	"image_output",
	"image_token",
	"input_audio_cache",
	"input_cache_read",
	"input_cache_write",
	"input_cache_write_1h",
	"internal_reasoning",
	"web_search",
}
local pricing_override_field_types = {
	prompt = "string",
	completion = "string",
	audio = "string",
	input_audio_cache = "string",
	input_cache_read = "string",
	input_cache_write = "string",
	input_cache_write_1h = "string",
	min_prompt_tokens = "number",
	utc_start = "number",
	utc_end = "number",
}
local default_parameter_field_types = {
	frequency_penalty = "number",
	presence_penalty = "number",
	repetition_penalty = "number",
	temperature = "number",
	top_k = "integer",
	top_p = "number",
}

local option_fields = {
	model = true,
	on_complete = true,
	on_error = true,
}
local model_option_fields = {
	on_complete = true,
	on_error = true,
}

local function validate_options(opts)
	if type(opts) ~= "table" then
		error("get_model_endpoints: options must be a table", 3)
	end
	for field in pairs(opts) do
		if not option_fields[field] then
			error(("get_model_endpoints: unknown option %q"):format(tostring(field)), 3)
		end
	end
	if type(opts.model) ~= "string" or not opts.model:match("^[%w][%w._-]*/[%w][%w._:%-]*$") then
		error("get_model_endpoints: model must be a canonical Model ID", 3)
	end
	if type(opts.on_complete) ~= "function" then
		error("get_model_endpoints: on_complete must be a function", 3)
	end
	if type(opts.on_error) ~= "function" then
		error("get_model_endpoints: on_error must be a function", 3)
	end
end

local function validate_model_options(opts)
	if type(opts) ~= "table" then
		error("get_models: options must be a table", 3)
	end
	for field in pairs(opts) do
		if not model_option_fields[field] then
			error(("get_models: unknown option %q"):format(tostring(field)), 3)
		end
	end
	if type(opts.on_complete) ~= "function" then
		error("get_models: on_complete must be a function", 3)
	end
	if type(opts.on_error) ~= "function" then
		error("get_models: on_error must be a function", 3)
	end
end

local function is_present(value)
	return value ~= nil and value ~= vim.NIL
end

local function require_present_fields(source, fields, context, allow_null)
	if type(source) ~= "table" then
		return nil, context .. " must be a table"
	end
	for _, field in ipairs(fields) do
		if source[field] == nil or (not allow_null and source[field] == vim.NIL) then
			return nil, ("%s must contain field %q"):format(context, field)
		end
	end
	return true
end

local function copy_typed_fields(source, target, field_types)
	for field, expected_type in pairs(field_types) do
		local value = source[field]
		if is_present(value) then
			local valid = expected_type == "integer" and type(value) == "number" and value % 1 == 0
				or type(value) == expected_type
			if not valid then
				return nil, ("field %q must be a %s"):format(field, expected_type)
			end
			target[field] = value
		end
	end
	return true
end

local function copy_string_list(source, target, field)
	local value = source[field]
	if not is_present(value) then
		return true
	end
	if type(value) ~= "table" or not vim.islist(value) then
		return nil, ("field %q must be a list"):format(field)
	end
	for _, item in ipairs(value) do
		if type(item) ~= "string" then
			return nil, ("field %q must contain strings"):format(field)
		end
	end
	target[field] = value
	return true
end

local function copy_nullable_string_list(source, target, field)
	local value = source[field]
	if not is_present(value) then
		return true
	end
	if type(value) ~= "table" or not vim.islist(value) then
		return nil, ("field %q must be a list"):format(field)
	end
	for _, item in ipairs(value) do
		if type(item) ~= "string" and item ~= vim.NIL then
			return nil, ("field %q must contain strings or null"):format(field)
		end
	end
	target[field] = value
	return true
end

local function copy_typed_object(source, target, field, field_types)
	local value = source[field]
	if not is_present(value) then
		return true
	end
	if type(value) ~= "table" then
		return nil, ('field "%s" must be a table'):format(field)
	end
	local decoded = {}
	local ok, err = copy_typed_fields(value, decoded, field_types)
	if not ok then
		return nil, err
	end
	target[field] = decoded
	return true
end

local function copy_typed_object_list(source, target, field, field_types)
	local value = source[field]
	if not is_present(value) then
		return true
	end
	if type(value) ~= "table" or not vim.islist(value) then
		return nil, ('field "%s" must be a list'):format(field)
	end
	local decoded = {}
	for _, item in ipairs(value) do
		if type(item) ~= "table" then
			return nil, ('field "%s" must contain tables'):format(field)
		end
		local decoded_item = {}
		local ok, err = copy_typed_fields(item, decoded_item, field_types)
		if not ok then
			return nil, err
		end
		table.insert(decoded, decoded_item)
	end
	target[field] = decoded
	return true
end

local function decode_models(payload)
	if type(payload.data) ~= "table" or not vim.islist(payload.data) then
		return nil, "response data must contain a Model list"
	end
	local models = {}
	for _, data in ipairs(payload.data) do
		if type(data) ~= "table" or type(data.id) ~= "string" or data.id == "" then
			return nil, "each Model must contain a Model ID"
		end
		local ok, err = require_present_fields(data, {
			"canonical_slug",
			"name",
			"created",
			"architecture",
			"pricing",
			"top_provider",
			"supported_parameters",
			"links",
		}, "each Model")
		if not ok then
			return nil, err
		end
		ok, err = require_present_fields(
			data,
			{ "context_length", "per_request_limits", "default_parameters", "supported_voices" },
			"each Model",
			true
		)
		if not ok then
			return nil, err
		end
		local model = { id = data.id }
		ok, err = copy_typed_fields(data, model, catalog_model_field_types)
		if not ok then
			return nil, err
		end
		if is_present(data.architecture) then
			if type(data.architecture) ~= "table" then
				return nil, 'field "architecture" must be a table'
			end
			local architecture = {}
			ok, err = require_present_fields(
				data.architecture,
				{ "modality" },
				'field "architecture"',
				true
			)
			if not ok then
				return nil, err
			end
			ok, err = require_present_fields(
				data.architecture,
				{ "input_modalities", "output_modalities" },
				'field "architecture"'
			)
			if not ok then
				return nil, err
			end
			ok, err = copy_typed_fields(data.architecture, architecture, architecture_field_types)
			if not ok then
				return nil, err
			end
			for _, field in ipairs({ "input_modalities", "output_modalities" }) do
				ok, err = copy_string_list(data.architecture, architecture, field)
				if not ok then
					return nil, err
				end
			end
			model.architecture = architecture
		end
		if is_present(data.pricing) then
			if type(data.pricing) ~= "table" then
				return nil, 'field "pricing" must be a table'
			end
			local pricing = {}
			ok, err =
				require_present_fields(data.pricing, { "prompt", "completion" }, 'field "pricing"')
			if not ok then
				return nil, err
			end
			for _, field in ipairs(pricing_fields) do
				local value = data.pricing[field]
				if is_present(value) then
					if type(value) ~= "string" then
						return nil, ("pricing field %q must be a string"):format(field)
					end
					pricing[field] = value
				end
			end
			local discount = data.pricing.discount
			if is_present(discount) then
				if type(discount) ~= "number" then
					return nil, 'pricing field "discount" must be a number'
				end
				pricing.discount = discount
			end
			ok, err = copy_typed_object_list(
				data.pricing,
				pricing,
				"overrides",
				pricing_override_field_types
			)
			if not ok then
				return nil, err
			end
			model.pricing = pricing
		end
		if is_present(data.top_provider) then
			if type(data.top_provider) ~= "table" then
				return nil, 'field "top_provider" must be a table'
			end
			local top_provider = {}
			ok, err = require_present_fields(
				data.top_provider,
				{ "is_moderated" },
				'field "top_provider"'
			)
			if not ok then
				return nil, err
			end
			ok, err = copy_typed_fields(data.top_provider, top_provider, {
				context_length = "integer",
				max_completion_tokens = "integer",
				is_moderated = "boolean",
			})
			if not ok then
				return nil, err
			end
			model.top_provider = top_provider
		end
		if is_present(data.per_request_limits) then
			if type(data.per_request_limits) ~= "table" then
				return nil, 'field "per_request_limits" must be a table'
			end
			local limits = {}
			ok, err = require_present_fields(
				data.per_request_limits,
				{ "prompt_tokens", "completion_tokens" },
				'field "per_request_limits"'
			)
			if not ok then
				return nil, err
			end
			ok, err = copy_typed_fields(data.per_request_limits, limits, {
				prompt_tokens = "number",
				completion_tokens = "number",
			})
			if not ok then
				return nil, err
			end
			model.per_request_limits = limits
		end
		for field, field_types in pairs({
			default_parameters = default_parameter_field_types,
			links = { details = "string" },
			alias_target = { slug = "string", name = "string" },
			reasoning = {
				mandatory = "boolean",
				default_enabled = "boolean",
				supports_max_tokens = "boolean",
				default_effort = "string",
			},
		}) do
			if field == "links" then
				ok, err = require_present_fields(data.links, { "details" }, 'field "links"')
			elseif field == "alias_target" and is_present(data.alias_target) then
				ok, err = require_present_fields(
					data.alias_target,
					{ "slug", "name" },
					'field "alias_target"'
				)
			elseif field == "reasoning" and is_present(data.reasoning) then
				ok, err =
					require_present_fields(data.reasoning, { "mandatory" }, 'field "reasoning"')
			else
				ok = true
			end
			if not ok then
				return nil, err
			end
			ok, err = copy_typed_object(data, model, field, field_types)
			if not ok then
				return nil, err
			end
		end
		if model.reasoning then
			ok, err =
				copy_nullable_string_list(data.reasoning, model.reasoning, "supported_efforts")
			if not ok then
				return nil, err
			end
		end
		if is_present(data.benchmarks) then
			if type(data.benchmarks) ~= "table" then
				return nil, 'field "benchmarks" must be a table'
			end
			local benchmarks = {}
			ok, err =
				require_present_fields(data.benchmarks, { "design_arena" }, 'field "benchmarks"')
			if not ok then
				return nil, err
			end
			if is_present(data.benchmarks.artificial_analysis) then
				ok, err = require_present_fields(
					data.benchmarks.artificial_analysis,
					{ "intelligence_index", "coding_index", "agentic_index" },
					'field "artificial_analysis"',
					true
				)
				if not ok then
					return nil, err
				end
			end
			ok, err = copy_typed_object(data.benchmarks, benchmarks, "artificial_analysis", {
				intelligence_index = "number",
				coding_index = "number",
				agentic_index = "number",
			})
			if not ok then
				return nil, err
			end
			ok, err = copy_typed_object_list(data.benchmarks, benchmarks, "design_arena", {
				arena = "string",
				category = "string",
				elo = "number",
				win_rate = "number",
				rank = "integer",
			})
			if not ok then
				return nil, err
			end
			for _, entry in ipairs(data.benchmarks.design_arena) do
				ok, err = require_present_fields(
					entry,
					{ "arena", "category", "elo", "win_rate", "rank" },
					'each field "design_arena" entry'
				)
				if not ok then
					return nil, err
				end
			end
			model.benchmarks = benchmarks
		end
		for _, field in ipairs({ "supported_parameters", "supported_voices" }) do
			ok, err = copy_string_list(data, model, field)
			if not ok then
				return nil, err
			end
		end
		table.insert(models, model)
	end
	return models
end

local function decode(payload)
	local data = payload.data
	if type(data) ~= "table" or type(data.id) ~= "string" or data.id == "" then
		return nil, "response data must contain a Model ID"
	end
	if type(data.endpoints) ~= "table" or not vim.islist(data.endpoints) then
		return nil, "response data must contain an endpoint list"
	end
	local result = { id = data.id }
	local ok, err = copy_typed_fields(data, result, endpoint_model_field_types)
	if not ok then
		return nil, err
	end
	if is_present(data.architecture) then
		if type(data.architecture) ~= "table" then
			return nil, 'field "architecture" must be a table'
		end
		local architecture = {}
		ok, err = copy_typed_fields(data.architecture, architecture, architecture_field_types)
		if not ok then
			return nil, err
		end
		for _, field in ipairs({ "input_modalities", "output_modalities" }) do
			ok, err = copy_string_list(data.architecture, architecture, field)
			if not ok then
				return nil, err
			end
		end
		result.architecture = architecture
	end
	result.endpoints = {}
	for _, endpoint in ipairs(data.endpoints) do
		if type(endpoint) ~= "table" or type(endpoint.tag) ~= "string" or endpoint.tag == "" then
			return nil, "each endpoint must contain a Provider routing slug"
		end
		local decoded_endpoint = { provider_slug = endpoint.tag }
		ok, err = copy_typed_fields(endpoint, decoded_endpoint, endpoint_field_types)
		if not ok then
			return nil, err
		end
		ok, err = copy_string_list(endpoint, decoded_endpoint, "supported_parameters")
		if not ok then
			return nil, err
		end
		if is_present(endpoint.pricing) then
			if type(endpoint.pricing) ~= "table" then
				return nil, 'field "pricing" must be a table'
			end
			local pricing = {}
			for _, field in ipairs(pricing_fields) do
				local value = endpoint.pricing[field]
				if is_present(value) then
					if type(value) ~= "string" then
						return nil, ("pricing field %q must be a string"):format(field)
					end
					pricing[field] = value
				end
			end
			decoded_endpoint.pricing = pricing
		end
		table.insert(result.endpoints, decoded_endpoint)
	end
	return result
end

---@param opts RowdyGetModelsOptions
---@return fun()
function M.get_models(opts)
	validate_model_options(opts)
	local settled = false
	local cancel_transport = function() end

	local function settle(callback, value)
		if settled then
			return
		end
		settled = true
		vim.schedule(function()
			callback(value)
		end)
	end

	local api_key = vim.env.OPENROUTER_API_KEY
	if not api_key or api_key == "" then
		settle(opts.on_error, {
			kind = "configuration",
			message = "OPENROUTER_API_KEY is not set",
		})
		return function() end
	end
	if api_key:find("[%c]") then
		settle(opts.on_error, {
			kind = "configuration",
			message = "OPENROUTER_API_KEY contains invalid control characters",
		})
		return function() end
	end

	cancel_transport = transport.request({
		path = "/models",
		api_key = api_key,
		connect_timeout = 10,
		total_timeout = 30,
		retry = {
			max_attempts = 3,
			delays = { 250, 1000 },
			max_retry_after = 5000,
		},
	}, function(transport_error, response)
		if transport_error then
			settle(opts.on_error, {
				kind = "transport",
				message = transport_error.message or "curl transport failed",
			})
			return
		end
		if type(response) ~= "table" or type(response.status) ~= "number" then
			settle(opts.on_error, { kind = "transport", message = "curl returned no response" })
			return
		end

		local json_ok, payload = pcall(vim.json.decode, response.body)
		if json_ok and type(payload) == "table" and type(payload.error) == "table" then
			settle(opts.on_error, {
				kind = "gateway",
				message = type(payload.error.message) == "string" and payload.error.message
					or "Gateway rejected Model discovery",
				status = response.status,
				details = payload.error,
			})
			return
		end
		if response.status < 200 or response.status >= 300 then
			settle(opts.on_error, {
				kind = "http",
				message = ("Gateway returned HTTP status %d"):format(response.status),
				status = response.status,
			})
			return
		end
		if not json_ok or type(payload) ~= "table" then
			settle(opts.on_error, {
				kind = "response_decoding",
				message = "Gateway response was not valid JSON",
				status = response.status,
			})
			return
		end
		local result, decode_error = decode_models(payload)
		if not result then
			settle(opts.on_error, {
				kind = "response_decoding",
				message = "Gateway response could not be decoded: " .. decode_error,
				status = response.status,
			})
			return
		end
		settle(opts.on_complete, result)
	end)

	return function()
		if not settled then
			settle(opts.on_error, {
				kind = "cancellation",
				message = "Model discovery was cancelled",
			})
			cancel_transport()
		end
	end
end

---@param opts RowdyGetModelEndpointsOptions
---@return fun()
function M.get_model_endpoints(opts)
	validate_options(opts)
	local settled = false
	local cancel_transport = function() end

	local function settle(callback, value)
		if settled then
			return
		end
		settled = true
		vim.schedule(function()
			callback(value)
		end)
	end

	local api_key = vim.env.OPENROUTER_API_KEY
	if not api_key or api_key == "" then
		settle(opts.on_error, {
			kind = "configuration",
			message = "OPENROUTER_API_KEY is not set",
		})
		return function() end
	end
	if api_key:find("[%c]") then
		settle(opts.on_error, {
			kind = "configuration",
			message = "OPENROUTER_API_KEY contains invalid control characters",
		})
		return function() end
	end

	cancel_transport = transport.request({
		model = opts.model,
		api_key = api_key,
		connect_timeout = 10,
		total_timeout = 30,
		retry = {
			max_attempts = 3,
			delays = { 250, 1000 },
			max_retry_after = 5000,
		},
	}, function(transport_error, response)
		if transport_error then
			settle(opts.on_error, {
				kind = "transport",
				message = transport_error.message or "curl transport failed",
			})
			return
		end
		if type(response) ~= "table" or type(response.status) ~= "number" then
			settle(opts.on_error, { kind = "transport", message = "curl returned no response" })
			return
		end

		local json_ok, payload = pcall(vim.json.decode, response.body)
		if json_ok and type(payload) == "table" and type(payload.error) == "table" then
			settle(opts.on_error, {
				kind = "gateway",
				message = type(payload.error.message) == "string" and payload.error.message
					or "Gateway rejected Provider endpoint discovery",
				status = response.status,
				details = payload.error,
			})
			return
		end
		if response.status < 200 or response.status >= 300 then
			settle(opts.on_error, {
				kind = "http",
				message = ("Gateway returned HTTP status %d"):format(response.status),
				status = response.status,
			})
			return
		end
		if not json_ok or type(payload) ~= "table" then
			settle(opts.on_error, {
				kind = "response_decoding",
				message = "Gateway response was not valid JSON",
				status = response.status,
			})
			return
		end
		local result, decode_error = decode(payload)
		if not result then
			settle(opts.on_error, {
				kind = "response_decoding",
				message = "Gateway response could not be decoded: " .. decode_error,
				status = response.status,
			})
			return
		end
		settle(opts.on_complete, result)
	end)

	return function()
		if not settled then
			settle(opts.on_error, {
				kind = "cancellation",
				message = "Provider endpoint discovery was cancelled",
			})
			cancel_transport()
		end
	end
end

return M
