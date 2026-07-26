local transport = require("rowdy.transport")

---@class RowdyPricing
---@field prompt? string
---@field completion? string
---@field request? string
---@field image? string
---@field input_cache_read? string
---@field input_cache_write? string

---@class RowdyModelArchitecture
---@field tokenizer? string
---@field instruct_type? string
---@field modality? string
---@field input_modalities? string[]
---@field output_modalities? string[]

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

---@class RowdyError
---@field kind 'configuration'|'cancellation'|'transport'|'http'|'gateway'|'response_decoding'
---@field message string
---@field status? integer
---@field details? table

---@class RowdyGetModelEndpointsOptions
---@field model string
---@field on_complete fun(result: RowdyModelEndpoints)
---@field on_error fun(error: RowdyError)

local M = {}

local model_field_types = {
	name = "string",
	created = "integer",
	description = "string",
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
	"input_cache_read",
	"input_cache_write",
}

local option_fields = {
	model = true,
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

local function is_present(value)
	return value ~= nil and value ~= vim.NIL
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

local function decode(payload)
	local data = payload.data
	if type(data) ~= "table" or type(data.id) ~= "string" or data.id == "" then
		return nil, "response data must contain a Model ID"
	end
	if type(data.endpoints) ~= "table" or not vim.islist(data.endpoints) then
		return nil, "response data must contain an endpoint list"
	end
	local result = { id = data.id }
	local ok, err = copy_typed_fields(data, result, model_field_types)
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
