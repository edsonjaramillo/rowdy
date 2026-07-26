# Require one Provider without fallback

Every Generation Request must name exactly one Provider, and Rowdy disables Gateway fallback routing. This trades OpenRouter's default availability behavior for explicit, predictable routing: if the selected Provider cannot serve the chosen Model, the request fails rather than being served by a different Provider.
