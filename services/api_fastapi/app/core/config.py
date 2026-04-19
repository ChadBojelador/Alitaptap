from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = 'ALITAPTAP API'
    app_env: str = 'dev'
    app_port: int = 8000

    firebase_project_id: str = ''
    firebase_service_account_path: str = ''

    model_config = SettingsConfigDict(
        env_file='.env',
        env_file_encoding='utf-8',
        extra='ignore',
    )


settings = Settings()
