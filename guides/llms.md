<!-- status: draft — delete this line once you've reviewed it -->
**What it's for:** calling large language models from R and building tools around them.

- **ellmer** is one consistent client for many providers (OpenAI, Anthropic, Azure OpenAI, Google, local models via Ollama, …). It supports tool calling and structured output (e.g. extract fields from free text into a data frame).
- **mcptools** speaks the Model Context Protocol: it lets an AI assistant run R code in your session, or lets R use MCP tools.
- **shinychat** is a chat UI component for Shiny apps.

On an internal or air-gapped network these only work against an *approved* endpoint (e.g. an organisational Azure OpenAI deployment via `ellmer::chat_azure_openai()`). Never send confidential data to public services.

**Pick:** ellmer as the base; the others when building assistants or apps.
