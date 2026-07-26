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
---@field kind 'configuration'|'cancellation'|'transport'|'http'|'gateway'|'response_decoding'|'stream_parsing'
---@field message string
---@field status? integer
---@field details? table
---@field partial_text? string

---@class RowdyPromptTokenDetails
---@field cached_tokens? number
---@field cache_write_tokens? number
---@field audio_tokens? number
---@field video_tokens? number

---@class RowdyCompletionTokenDetails
---@field reasoning_tokens? number
---@field audio_tokens? number
---@field image_tokens? number

---@class RowdyCostDetails
---@field upstream_inference_cost? number
---@field upstream_inference_prompt_cost? number
---@field upstream_inference_completions_cost? number

---@class RowdyServerToolUse
---@field web_search_requests? number

---@class RowdyGenerationUsage
---@field prompt_tokens? number
---@field completion_tokens? number
---@field total_tokens? number
---@field cost? number
---@field is_byok? boolean
---@field prompt_tokens_details? RowdyPromptTokenDetails
---@field completion_tokens_details? RowdyCompletionTokenDetails
---@field cost_details? RowdyCostDetails
---@field server_tool_use? RowdyServerToolUse

---@class RowdyGenerationResult
---@field text string
---@field finish_reason? string
---@field request_id string
---@field model_id string
---@field usage? RowdyGenerationUsage

---@class RowdyGenerateOptions
---@field prompt string
---@field model string
---@field provider string
---@field stream? boolean
---@field on_chunk? fun(chunk: string)
---@field on_complete fun(result: RowdyGenerationResult)
---@field on_error fun(error: RowdyError)

---@class RowdyGetModelEndpointsOptions
---@field model string
---@field on_complete fun(result: RowdyModelEndpoints)
---@field on_error fun(error: RowdyError)

---@class RowdyGetModelsOptions
---@field limit? integer
---@field search? string
---@field category? 'programming'|'roleplay'|'marketing'|'marketing/seo'|'technology'|'science'|'translation'|'legal'|'finance'|'health'|'trivia'|'academia'
---@field supported_parameters? string[]
---@field input_modalities? ('text'|'image'|'audio'|'file')[]
---@field output_modalities? ('text'|'image'|'audio'|'embeddings'|'all')[]
---@field architecture? string
---@field model_authors? string[]
---@field providers? string[]
---@field distillable? boolean
---@field zero_data_retention? true
---@field region? 'eu'
---@field sort? 'most-popular'|'newest'|'top-weekly'|'pricing-low-to-high'|'pricing-high-to-low'|'context-high-to-low'|'throughput-high-to-low'|'latency-low-to-high'|'intelligence-high-to-low'|'coding-high-to-low'|'agentic-high-to-low'|'design-arena-elo-high-to-low'
---@field minimum_context_length? integer
---@field minimum_input_price? number
---@field maximum_input_price? number
---@field minimum_output_price? number
---@field maximum_output_price? number
---@field minimum_age_days? integer
---@field maximum_age_days? integer
---@field minimum_intelligence_index? number
---@field maximum_intelligence_index? number
---@field minimum_coding_index? number
---@field maximum_coding_index? number
---@field minimum_agentic_index? number
---@field maximum_agentic_index? number
---@field minimum_tool_success_rate? number
---@field maximum_tool_success_rate? number
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
local generate_option_fields = {
	prompt = true,
	model = true,
	provider = true,
	stream = true,
	on_chunk = true,
	on_complete = true,
	on_error = true,
}
local model_option_fields = {
	limit = true,
	search = true,
	category = true,
	supported_parameters = true,
	input_modalities = true,
	output_modalities = true,
	architecture = true,
	model_authors = true,
	providers = true,
	distillable = true,
	zero_data_retention = true,
	region = true,
	sort = true,
	minimum_context_length = true,
	minimum_input_price = true,
	maximum_input_price = true,
	minimum_output_price = true,
	maximum_output_price = true,
	minimum_age_days = true,
	maximum_age_days = true,
	minimum_intelligence_index = true,
	maximum_intelligence_index = true,
	minimum_coding_index = true,
	maximum_coding_index = true,
	minimum_agentic_index = true,
	maximum_agentic_index = true,
	minimum_tool_success_rate = true,
	maximum_tool_success_rate = true,
	on_complete = true,
	on_error = true,
}

local model_categories = {
	programming = true,
	roleplay = true,
	marketing = true,
	["marketing/seo"] = true,
	technology = true,
	science = true,
	translation = true,
	legal = true,
	finance = true,
	health = true,
	trivia = true,
	academia = true,
}
local input_modalities = { text = true, image = true, audio = true, file = true }
local output_modalities = { text = true, image = true, audio = true, embeddings = true, all = true }
local model_sorts = {
	["most-popular"] = true,
	newest = true,
	["top-weekly"] = true,
	["pricing-low-to-high"] = true,
	["pricing-high-to-low"] = true,
	["context-high-to-low"] = true,
	["throughput-high-to-low"] = true,
	["latency-low-to-high"] = true,
	["intelligence-high-to-low"] = true,
	["coding-high-to-low"] = true,
	["agentic-high-to-low"] = true,
	["design-arena-elo-high-to-low"] = true,
}

local function validate_generate_options(opts)
	if type(opts) ~= "table" then
		error("generate: options must be a table", 3)
	end
	for field in pairs(opts) do
		if not generate_option_fields[field] then
			error(("generate: unknown option %q"):format(tostring(field)), 3)
		end
	end
	if type(opts.prompt) ~= "string" or opts.prompt == "" then
		error("generate: prompt must be a non-empty string", 3)
	end
	if type(opts.model) ~= "string" or not opts.model:match("^[%w][%w._-]*/[%w][%w._:%-]*$") then
		error("generate: model must be a canonical Model ID", 3)
	end
	if type(opts.provider) ~= "string" or not opts.provider:match("^[%w][%w._:/-]*$") then
		error("generate: provider must be a non-empty Provider slug", 3)
	end
	if opts.stream ~= nil and type(opts.stream) ~= "boolean" then
		error("generate: stream must be a boolean", 3)
	end
	if opts.on_chunk ~= nil and type(opts.on_chunk) ~= "function" then
		error("generate: on_chunk must be a function", 3)
	end
	if opts.stream == false and opts.on_chunk ~= nil then
		error("generate: on_chunk requires streaming", 3)
	end
	if type(opts.on_complete) ~= "function" then
		error("generate: on_complete must be a function", 3)
	end
	if type(opts.on_error) ~= "function" then
		error("generate: on_error must be a function", 3)
	end
end

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
	if
		opts.limit ~= nil
		and (type(opts.limit) ~= "number" or opts.limit % 1 ~= 0 or opts.limit < 1)
	then
		error("get_models: limit must be a positive integer", 3)
	end
	for _, field in ipairs({ "search", "architecture" }) do
		local value = opts[field]
		if value ~= nil and (type(value) ~= "string" or value == "" or value:find("[%c]")) then
			error(
				("get_models: %s must be a non-empty string without control characters"):format(
					field
				),
				3
			)
		end
	end
	if opts.category ~= nil and not model_categories[opts.category] then
		error("get_models: category is not supported", 3)
	end

	local function validate_list(field, allowed)
		local value = opts[field]
		if value == nil then
			return
		end
		if type(value) ~= "table" or not vim.islist(value) or #value == 0 then
			error(("get_models: %s must be a non-empty list"):format(field), 3)
		end
		local seen = {}
		for _, item in ipairs(value) do
			if
				type(item) ~= "string"
				or item == ""
				or item:find("[,%c]")
				or item:match("^%s")
				or item:match("%s$")
				or (field ~= "providers" and item:find("%s"))
			then
				error(("get_models: %s must contain non-empty comma-free values"):format(field), 3)
			end
			if allowed and not allowed[item] then
				error(("get_models: %s contains an unsupported value %q"):format(field, item), 3)
			end
			if seen[item] then
				error(("get_models: %s must not contain duplicate values"):format(field), 3)
			end
			seen[item] = true
		end
	end

	validate_list("supported_parameters")
	validate_list("input_modalities", input_modalities)
	validate_list("output_modalities", output_modalities)
	validate_list("model_authors")
	validate_list("providers")
	if opts.output_modalities and #opts.output_modalities > 1 then
		for _, modality in ipairs(opts.output_modalities) do
			if modality == "all" then
				error('get_models: output modality "all" cannot be combined with other values', 3)
			end
		end
	end
	if opts.distillable ~= nil and type(opts.distillable) ~= "boolean" then
		error("get_models: distillable must be a boolean", 3)
	end
	if opts.zero_data_retention ~= nil and opts.zero_data_retention ~= true then
		error("get_models: zero_data_retention must be true when specified", 3)
	end
	if opts.region ~= nil and opts.region ~= "eu" then
		error('get_models: region must be "eu"', 3)
	end
	if opts.sort ~= nil and not model_sorts[opts.sort] then
		error("get_models: sort is not supported", 3)
	end

	local function validate_number(field, integer, maximum)
		local value = opts[field]
		if value == nil then
			return
		end
		local valid = type(value) == "number"
			and value == value
			and value ~= math.huge
			and value ~= -math.huge
			and (not integer or value % 1 == 0)
			and value >= (field == "minimum_context_length" and 1 or 0)
			and (maximum == nil or value <= maximum)
		if not valid then
			local domain = field == "minimum_context_length" and "an integer of at least 1"
				or integer and "a non-negative integer"
				or maximum and "a finite number between 0 and 1"
				or "a finite non-negative number"
			error(("get_models: %s must be %s"):format(field, domain), 3)
		end
	end

	validate_number("minimum_context_length", true)
	for _, field in ipairs({ "minimum_age_days", "maximum_age_days" }) do
		validate_number(field, true)
	end
	for _, field in ipairs({
		"minimum_input_price",
		"maximum_input_price",
		"minimum_output_price",
		"maximum_output_price",
		"minimum_intelligence_index",
		"maximum_intelligence_index",
		"minimum_coding_index",
		"maximum_coding_index",
		"minimum_agentic_index",
		"maximum_agentic_index",
	}) do
		validate_number(field, false)
	end
	for _, field in ipairs({ "minimum_tool_success_rate", "maximum_tool_success_rate" }) do
		validate_number(field, false, 1)
	end

	for _, range in ipairs({
		{ "minimum_input_price", "maximum_input_price" },
		{ "minimum_output_price", "maximum_output_price" },
		{ "minimum_age_days", "maximum_age_days" },
		{ "minimum_intelligence_index", "maximum_intelligence_index" },
		{ "minimum_coding_index", "maximum_coding_index" },
		{ "minimum_agentic_index", "maximum_agentic_index" },
		{ "minimum_tool_success_rate", "maximum_tool_success_rate" },
	}) do
		local minimum, maximum = opts[range[1]], opts[range[2]]
		if minimum ~= nil and maximum ~= nil and minimum > maximum then
			error(("get_models: %s must not exceed %s"):format(range[1], range[2]), 3)
		end
	end
end

local function model_path(opts)
	local function encode(value)
		local encoded = tostring(value):gsub("([^%w%-._~])", function(character)
			return ("%%%02X"):format(character:byte())
		end)
		return encoded
	end
	local query = {}
	local function add(name, value)
		if value ~= nil then
			table.insert(query, name .. "=" .. encode(value))
		end
	end
	local function add_list(name, values)
		if values then
			local encoded = {}
			for _, value in ipairs(values) do
				table.insert(encoded, encode(value))
			end
			table.insert(query, name .. "=" .. table.concat(encoded, ","))
		end
	end

	add("q", opts.search)
	add("category", opts.category)
	add_list("supported_parameters", opts.supported_parameters)
	add_list("input_modalities", opts.input_modalities)
	add_list("output_modalities", opts.output_modalities)
	add("arch", opts.architecture)
	add_list("model_authors", opts.model_authors)
	add_list("providers", opts.providers)
	add("distillable", opts.distillable ~= nil and tostring(opts.distillable) or nil)
	add("zdr", opts.zero_data_retention and "true" or nil)
	add("region", opts.region)
	add("sort", opts.sort)
	add("context", opts.minimum_context_length)
	add("min_price", opts.minimum_input_price)
	add("max_price", opts.maximum_input_price)
	add("min_output_price", opts.minimum_output_price)
	add("max_output_price", opts.maximum_output_price)
	add("min_age_days", opts.minimum_age_days)
	add("max_age_days", opts.maximum_age_days)
	add("min_intelligence_index", opts.minimum_intelligence_index)
	add("max_intelligence_index", opts.maximum_intelligence_index)
	add("min_coding_index", opts.minimum_coding_index)
	add("max_coding_index", opts.maximum_coding_index)
	add("min_agentic_index", opts.minimum_agentic_index)
	add("max_agentic_index", opts.maximum_agentic_index)
	add("min_tool_success_rate", opts.minimum_tool_success_rate)
	add("max_tool_success_rate", opts.maximum_tool_success_rate)
	return #query > 0 and "/models?" .. table.concat(query, "&") or "/models"
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

local function decode_gateway_error(value)
	if type(value) ~= "table" then
		return nil, "Gateway error must be a table"
	end
	if type(value.code) ~= "number" then
		return nil, 'Gateway error field "code" must be a number'
	end
	if type(value.message) ~= "string" or value.message == "" then
		return nil, 'Gateway error field "message" must be a non-empty string'
	end
	local result = { code = value.code, message = value.message }
	if is_present(value.metadata) then
		if type(value.metadata) ~= "table" then
			return nil, 'Gateway error field "metadata" must be a table'
		end
		result.metadata = value.metadata
	end
	return result
end

local function decode_generation_usage(value)
	if type(value) ~= "table" then
		return nil, 'field "usage" must be a table'
	end
	local usage = {}
	local ok, err = copy_typed_fields(value, usage, {
		prompt_tokens = "number",
		completion_tokens = "number",
		total_tokens = "number",
		cost = "number",
		is_byok = "boolean",
	})
	if not ok then
		return nil, err
	end
	for field, field_types in pairs({
		prompt_tokens_details = {
			cached_tokens = "number",
			cache_write_tokens = "number",
			audio_tokens = "number",
			video_tokens = "number",
		},
		completion_tokens_details = {
			reasoning_tokens = "number",
			audio_tokens = "number",
			image_tokens = "number",
		},
		cost_details = {
			upstream_inference_cost = "number",
			upstream_inference_prompt_cost = "number",
			upstream_inference_completions_cost = "number",
		},
		server_tool_use = { web_search_requests = "number" },
	}) do
		ok, err = copy_typed_object(value, usage, field, field_types)
		if not ok then
			return nil, err
		end
	end
	return usage
end

local function decode_generation(payload)
	if type(payload.id) ~= "string" or payload.id == "" then
		return nil, "response must contain a request ID"
	end
	if type(payload.model) ~= "string" or payload.model == "" then
		return nil, "response must contain a Model ID"
	end
	if
		type(payload.choices) ~= "table"
		or not vim.islist(payload.choices)
		or #payload.choices == 0
	then
		return nil, "response must contain at least one generation choice"
	end
	local choice = payload.choices[1]
	if type(choice) ~= "table" then
		return nil, "first generation choice must be a table"
	end
	if is_present(choice.error) then
		local gateway_error, err = decode_gateway_error(choice.error)
		if not gateway_error then
			return nil, "generation choice error could not be decoded: " .. err
		end
		return nil,
			nil,
			{
				message = gateway_error.message,
				details = gateway_error,
				partial_text = type(choice.text) == "string" and choice.text or nil,
			}
	end
	if type(choice.text) ~= "string" then
		return nil, "first generation choice must contain text"
	end
	local result = {
		text = choice.text,
		request_id = payload.id,
		model_id = payload.model,
	}
	if is_present(choice.finish_reason) then
		if type(choice.finish_reason) ~= "string" then
			return nil, 'field "finish_reason" must be a string or null'
		end
		result.finish_reason = choice.finish_reason
	end
	if is_present(payload.usage) then
		local usage, err = decode_generation_usage(payload.usage)
		if not usage then
			return nil, err
		end
		result.usage = usage
	end
	return result
end

---@param opts RowdyGenerateOptions
---@return fun()
function M.generate(opts)
	validate_generate_options(opts)
	local settled = false
	local cancel_transport = function() end
	local streaming = opts.stream ~= false
	local stream_buffer = ""
	local event_data = {}
	local stream_done = false
	local generated_text = ""
	local partial_text = ""
	local stream_result = {}
	local chunks_active = true

	local function settle(callback, value)
		if settled then
			return
		end
		if value.kind ~= nil then
			chunks_active = false
			local accumulated_text = value.kind == "cancellation" and partial_text or generated_text
			if streaming and accumulated_text ~= "" then
				value.partial_text = accumulated_text
			end
		end
		settled = true
		vim.schedule(function()
			callback(value)
		end)
	end

	local function stream_error(message, gateway_error)
		local err = {
			kind = gateway_error and "gateway" or "stream_parsing",
			message = message,
			partial_text = partial_text ~= "" and partial_text or nil,
		}
		if gateway_error then
			err.status = gateway_error.code
			err.details = gateway_error
		end
		settle(opts.on_error, err)
		cancel_transport()
	end

	local function merge_usage(usage)
		stream_result.usage = vim.tbl_deep_extend("force", stream_result.usage or {}, usage)
	end

	local function decode_stream_event(data)
		if data == "[DONE]" then
			stream_done = true
			stream_buffer = ""
			event_data = {}
			return
		end
		local ok, payload = pcall(vim.json.decode, data)
		if not ok or type(payload) ~= "table" then
			stream_error("Gateway stream contained invalid JSON")
			return
		end
		if is_present(payload.error) then
			local gateway_error, err = decode_gateway_error(payload.error)
			if not gateway_error then
				stream_error("Gateway stream error could not be decoded: " .. err)
				return
			end
			stream_error(gateway_error.message, gateway_error)
			return
		end
		for _, target in ipairs({
			{ payload.id, "request_id", "request ID" },
			{ payload.model, "model_id", "Model ID" },
		}) do
			local value = target[1]
			if is_present(value) then
				if type(value) ~= "string" or value == "" then
					stream_error("Gateway stream " .. target[3] .. " must be a non-empty string")
					return
				end
				stream_result[target[2]] = value
			end
		end
		if is_present(payload.usage) then
			local usage, err = decode_generation_usage(payload.usage)
			if not usage then
				stream_error("Gateway stream could not decode usage: " .. err)
				return
			end
			merge_usage(usage)
		end
		if not is_present(payload.choices) then
			return
		end
		if type(payload.choices) ~= "table" or not vim.islist(payload.choices) then
			stream_error("Gateway stream choices must be a list")
			return
		end
		if #payload.choices == 0 then
			return
		end
		local choice = payload.choices[1]
		if type(choice) ~= "table" then
			stream_error("Gateway stream choice must be a table")
			return
		end
		if is_present(choice.error) then
			local gateway_error, err = decode_gateway_error(choice.error)
			if not gateway_error then
				stream_error("Gateway stream choice error could not be decoded: " .. err)
				return
			end
			stream_error(gateway_error.message, gateway_error)
			return
		end
		if is_present(choice.finish_reason) then
			if type(choice.finish_reason) ~= "string" then
				stream_error('Gateway stream field "finish_reason" must be a string or null')
				return
			end
			stream_result.finish_reason = choice.finish_reason
		end
		if not is_present(choice.delta) then
			return
		end
		if type(choice.delta) ~= "table" then
			stream_error("Gateway stream choice delta must be a table")
			return
		end
		local content = choice.delta.content
		if not is_present(content) then
			return
		end
		if type(content) ~= "string" then
			stream_error("Gateway stream text delta must be a string")
			return
		end
		if content ~= "" then
			generated_text = generated_text .. content
			if opts.on_chunk then
				vim.schedule(function()
					if not chunks_active then
						return
					end
					partial_text = partial_text .. content
					opts.on_chunk(content)
				end)
			else
				partial_text = generated_text
			end
		end
	end

	local function receive_stream_data(data)
		if settled or stream_done then
			return
		end
		stream_buffer = stream_buffer .. data
		while true do
			local newline = stream_buffer:find("[\r\n]")
			if
				not newline
				or (newline == #stream_buffer and stream_buffer:sub(newline, newline) == "\r")
			then
				return
			end
			local delimiter_length = stream_buffer:sub(newline, newline + 1) == "\r\n" and 2 or 1
			local line = stream_buffer:sub(1, newline - 1)
			stream_buffer = stream_buffer:sub(newline + delimiter_length)
			if line == "" then
				if #event_data > 0 then
					local data_lines = table.concat(event_data, "\n")
					event_data = {}
					decode_stream_event(data_lines)
					if settled or stream_done then
						return
					end
				end
			elseif line:sub(1, 1) ~= ":" then
				local field, value = line:match("^([^:]+): ?(.*)$")
				if not field then
					field, value = line, ""
				end
				if field == "data" then
					table.insert(event_data, value)
				end
			end
		end
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

	local request = {
		method = "POST",
		path = "/chat/completions",
		api_key = api_key,
		connect_timeout = 10,
		body = vim.json.encode({
			prompt = opts.prompt,
			model = opts.model,
			provider = {
				order = { opts.provider },
				allow_fallbacks = false,
			},
			stream = streaming,
		}),
	}
	if streaming then
		request.on_data = receive_stream_data
	end
	cancel_transport = transport.request(request, function(transport_error, response)
		if settled then
			return
		end
		if transport_error then
			settle(opts.on_error, {
				kind = "transport",
				message = transport_error.message or "curl transport failed",
				partial_text = partial_text ~= "" and partial_text or nil,
			})
			return
		end
		if type(response) ~= "table" or type(response.status) ~= "number" then
			settle(opts.on_error, { kind = "transport", message = "curl returned no response" })
			return
		end

		local json_ok, payload = pcall(vim.json.decode, response.body)
		if json_ok and type(payload) == "table" and is_present(payload.error) then
			local gateway_error, decode_error = decode_gateway_error(payload.error)
			if not gateway_error then
				settle(opts.on_error, {
					kind = "response_decoding",
					message = "Gateway response could not be decoded: " .. decode_error,
					status = response.status,
				})
				return
			end
			settle(opts.on_error, {
				kind = "gateway",
				message = gateway_error.message,
				status = response.status,
				details = gateway_error,
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
		if streaming then
			if stream_buffer:sub(-1) == "\r" then
				receive_stream_data("\n")
			end
			if stream_buffer ~= "" or #event_data > 0 then
				stream_error("Gateway stream ended with incomplete event framing")
				return
			end
			if not stream_done then
				stream_error("Gateway stream ended without a terminal marker")
				return
			end
			if not stream_result.request_id or not stream_result.model_id then
				stream_error("Gateway stream did not contain request and Model identifiers")
				return
			end
			stream_result.text = generated_text
			settle(opts.on_complete, stream_result)
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
		local result, decode_error, generation_error = decode_generation(payload)
		if generation_error then
			settle(opts.on_error, {
				kind = "gateway",
				message = generation_error.message,
				status = response.status,
				details = generation_error.details,
				partial_text = generation_error.partial_text,
			})
			return
		end
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
				message = "Generation Request was cancelled",
				partial_text = partial_text ~= "" and partial_text or nil,
			})
			cancel_transport()
		end
	end
end

---@param opts RowdyGetModelsOptions
---@return fun()
function M.get_models(opts)
	validate_model_options(opts)
	local settled = false
	local cancel_transport = function() end
	local models = {}
	local request_number = 0

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

	local request_page
	request_page = function(path)
		request_number = request_number + 1
		local this_request = request_number
		local callback_ran = false
		local cancel = transport.request({
			path = path,
			api_key = api_key,
			connect_timeout = 10,
			total_timeout = 30,
			retry = {
				max_attempts = 3,
				delays = { 250, 1000 },
				max_retry_after = 5000,
			},
		}, function(transport_error, response)
			callback_ran = true
			if settled then
				return
			end
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
			local page, decode_error = decode_models(payload)
			if not page then
				settle(opts.on_error, {
					kind = "response_decoding",
					message = "Gateway response could not be decoded: " .. decode_error,
					status = response.status,
				})
				return
			end
			local next_page
			if type(payload.links) ~= "table" then
				decode_error = 'response field "links" must be a table'
			elseif payload.links.next ~= vim.NIL then
				if type(payload.links.next) ~= "string" or payload.links.next == "" then
					decode_error = 'response field "links.next" must be a URL or null'
				else
					next_page = payload.links.next:match("^/api/v1(/models%?.+)$")
					if not next_page then
						decode_error = 'response field "links.next" must identify a Models page'
					end
				end
			end
			if decode_error then
				settle(opts.on_error, {
					kind = "response_decoding",
					message = "Gateway response could not be decoded: " .. decode_error,
					status = response.status,
				})
				return
			end
			vim.list_extend(models, page)
			if opts.limit and #models >= opts.limit then
				while #models > opts.limit do
					table.remove(models)
				end
				settle(opts.on_complete, models)
				return
			end
			if next_page then
				request_page(next_page)
			else
				settle(opts.on_complete, models)
			end
		end)
		if not callback_ran and not settled and request_number == this_request then
			cancel_transport = cancel
		end
	end

	request_page(model_path(opts))

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
