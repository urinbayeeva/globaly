from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    gemini_api_key: str = ""
    groq_api_key: str = ""
    resend_api_key: str = ""
    resend_from: str = "Globaly <onboarding@resend.dev>"
    firebase_credentials: str = ""
    cors_origins: str = "*"
    gemini_models: str = "gemini-flash-latest,gemini-2.5-flash,gemini-2.0-flash"
    groq_models: str = "llama-3.3-70b-versatile,llama-3.1-8b-instant"
    groq_vision_model: str = "meta-llama/llama-4-scout-17b-16e-instruct"
    currency_cache_ttl_seconds: int = 3600

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def gemini_model_list(self) -> list[str]:
        return [m.strip() for m in self.gemini_models.split(",") if m.strip()]

    @property
    def groq_model_list(self) -> list[str]:
        return [m.strip() for m in self.groq_models.split(",") if m.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
