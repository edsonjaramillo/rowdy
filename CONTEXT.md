# Rowdy

Rowdy is a Neovim interface for requesting text generation through OpenRouter while making model routing explicit.

## Language

**Gateway**:
The OpenRouter API through which Rowdy discovers Models and requests generation.
_Avoid_: Provider

**Provider**:
The sole upstream inference host selected to serve a Generation Request routed through the Gateway. A request is not served by a fallback Provider.
_Avoid_: Gateway, model author

**Model**:
A named text-generation model available through the Gateway.
_Avoid_: Provider

**Model Author**:
The organization that created a Model, whether or not it serves that Model as a Provider.
_Avoid_: Provider

**Generation Request**:
A request to generate text from one text Prompt, naming one Model and exactly one Provider for that invocation.
_Avoid_: Query, completion

**Prompt**:
The single text input supplied to a Generation Request.
_Avoid_: Conversation, message history

**Generated Text**:
The Gateway-normalized final text produced by a Generation Request. It may be empty and excludes separate Model reasoning content.
_Avoid_: Raw output, reasoning
