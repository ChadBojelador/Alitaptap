from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = 'ALITAPTAP API'
    app_env: str = 'dev'
    app_port: int = 8000

    mongodb_uri: str = 'mongodb://localhost:27017'
    mongodb_db_name: str = 'alitaptap'

    huggingface_model_name: str = 'sentence-transformers/all-MiniLM-L6-v2'

    # ---------------------------------------------------------------------------
    # AI Integration Keys (leave empty until integrating)
    # ---------------------------------------------------------------------------

    # Option A: OpenAI — for title suggestions and issue validation.
    # Get key from https://platform.openai.com/api-keys
    # Add to .env: OPENAI_API_KEY=sk-...
    openai_api_key: str = ''

    # Option B: HuggingFace Inference API — for SDG tagging and zero-shot classification.
    # Get key from https://huggingface.co/settings/tokens
    # Add to .env: HUGGINGFACE_API_KEY=hf_...
    huggingface_api_key: str = ''

    # NewsAPI key — for fetching news articles.
    # Get key from https://newsapi.org
    # Add to .env: NEWSAPI_KEY=...
    newsapi_key: str = ''

    # AI feature flags — set to True in .env to enable each AI service.
    # When False, services fall back to stubs/heuristics.
    # Add to .env: AI_TITLE_SUGGESTIONS_ENABLED=true
    ai_title_suggestions_enabled: bool = False
    ai_sdg_tagging_enabled: bool = False
    ai_issue_validation_enabled: bool = False

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore',
    )


settings = Settings()
