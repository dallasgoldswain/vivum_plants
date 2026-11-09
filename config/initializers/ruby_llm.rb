# AI provider keys from credentials (ai.anthropic_api_key, ai.openai_api_key).
# Per PRD D23: Claude Haiku for DM/request extraction, Claude Sonnet for care
# suggestions, OpenAI as fallback. Models are chosen per use case when built.
RubyLLM.configure do |config|
  config.anthropic_api_key = Rails.application.credentials.dig(:ai, :anthropic_api_key)
  config.openai_api_key = Rails.application.credentials.dig(:ai, :openai_api_key)
end
