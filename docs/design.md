# Rowdy v1 Design

Rowdy v1 is a typed Lua API for text generation through OpenRouter. It does not provide commands, windows, selection transforms, chat history, or a required setup call.

## Public API

`require("rowdy")` exposes three asynchronous functions:

- `generate(options)` starts one Generation Request.
- `get_models(options)` discovers Models from the Gateway catalog.
- `get_model_endpoints(options)` discovers Provider endpoints for one canonical Model ID.

Each function accepts one typed options table and returns an idempotent cancel function. Completion and error callbacks are required. `generate` also accepts an optional chunk callback.

All callbacks are scheduled onto Neovim's main loop so callers may safely use Neovim APIs. Each operation invokes exactly one terminal callback: completion or error. Cancelling an unfinished operation terminates curl and reports one typed cancellation error.

Invalid public arguments raise synchronously before curl starts. Operational failures, including a missing `OPENROUTER_API_KEY`, are reported asynchronously through the error callback.

## Generation

A Generation Request requires:

- One non-empty text Prompt
- One canonical Model ID
- One non-empty Provider slug
- Completion and error callbacks

Rowdy represents the Prompt to the Gateway as one user message. It requests that separate Model reasoning content be excluded from the response without disabling Model reasoning.

The Provider slug may identify a base Provider or a specific endpoint variant or region. Rowdy sends it as the only preferred Provider and disables Gateway fallbacks. It does not preflight Model and Provider compatibility; incompatibility is a Gateway error.

Streaming defaults to enabled and may be disabled per request. The first version exposes no model-tuning parameters and relies on Gateway and Model defaults.

For a streaming request, the optional chunk callback receives only ordered, non-empty final-content deltas. SSE comments, reasoning deltas, and metadata-only events remain internal. On success, the final Generated Text equals the concatenated final-content deltas and may be empty.

The completion callback receives a typed result containing the Generated Text, finish reason, request and Model identifiers, and available usage and cost metadata. Generated Text excludes separate reasoning content. If a stream fails after emitting text, only the error callback runs, and its typed error includes the accumulated partial text.

Generation Requests are never retried automatically.

## Model Discovery

`get_models` exposes every documented JSON query option on the Gateway's `GET /models` endpoint except the RSS presentation options. Inputs use typed enums and constrained values where the Gateway documents them. Unknown options and invalid combinations, such as an inverted price range, raise synchronously.

Unspecified filters are omitted so the Gateway owns their defaults. Rowdy does not implicitly restrict results to Models compatible with text Prompts. Callers may request text input or output modalities explicitly.

Rowdy automatically follows Gateway pagination. Its optional `limit` is a Rowdy-level maximum number of returned Models, not an HTTP page size. Without that limit, Rowdy collects all matching Models. A failure on any page fails the entire operation; an incomplete collection is never reported as success.

## Provider Endpoint Discovery

`get_model_endpoints` accepts one canonical Model ID and returns typed endpoint details from the Gateway. This supplies the Provider slugs required by `generate`; callers do not need to retain a full Model result.

## Read Reliability

Model and Provider endpoint discovery retry transport failures and HTTP 408, 429, and 5xx responses at most twice. The normal delays are 250 milliseconds and 1 second. A Gateway `Retry-After` value is honored but capped at 5 seconds per retry.

All operations use a 10-second connection timeout. Each individual discovery HTTP request has a 30-second total timeout. Generation has no total timeout and remains cancellable by the caller.

If any page or endpoint request still fails, the operation invokes its error callback without a partial success result.

## Errors

Asynchronous failures use a stable typed error object. Error kinds distinguish at least configuration, cancellation, transport, HTTP, Gateway, response decoding, and stream parsing failures. Errors include a human-readable message and preserve relevant status, Gateway details, and partial generated text when available.

Gateway responses are decoded into typed known fields while tolerating additive unknown response fields. Runtime validation is strict for caller-controlled inputs, not for forward-compatible Gateway additions.

## Authentication And Transport

Rowdy reads `OPENROUTER_API_KEY` at request time. It does not accept or store the key in setup or per-call options.

An internal curl module owns process execution, HTTP encoding, streaming parsing, cancellation, timeouts, and retry mechanics. API keys and Prompt content must never appear in curl process arguments or persistent secret files; sensitive headers and bodies travel through a non-argv channel.

Rowdy targets Neovim 0.11 or newer and may rely on its process, scheduling, and JSON APIs. The external `curl` executable is a runtime dependency.
