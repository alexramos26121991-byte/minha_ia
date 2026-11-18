"""Configuração central via variáveis de ambiente (pydantic-settings)."""

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

_ROOT = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    """Todas as chaves de provedores ficam somente no backend."""

    # Aplicação
    app_env: str = "development"
    api_base_url: str = "http://localhost:8000"
    log_level: str = "INFO"
    jwt_secret: str = "trocar"

    # Banco e fila
    postgres_host: str = "localhost"
    postgres_port: int = 5432
    postgres_db: str = "minha_ia"
    postgres_user: str = "minha_ia"
    postgres_password: str = "trocar"
    redis_url: str = "redis://localhost:6379/0"

    # Autenticação (E2). "firebase" exige as credenciais abaixo; "dev" permite
    # fluxo local sem Firebase e é recusado quando app_env=production.
    auth_provider: str = "dev"

    # Feature flags (ADRs 0002/0004 — provisórios)
    credits_enforced: bool = True
    # Reservas órfãs (sem commit/estorno) são estornadas após este prazo.
    reconcile_stale_minutes: int = 30
    reconcile_interval_seconds: int = 300
    image_generation_enabled: bool = True
    video_generation_enabled: bool = False
    audio_generation_enabled: bool = False
    avatar_enabled: bool = False
    payments_enabled: bool = False

    # Firebase / Cloud Storage (preenchidos na E2 — dependem do usuário)
    firebase_project_id: str = ""
    firebase_service_account_json: str = ""
    fcm_server_key: str = ""
    gcs_bucket: str = ""
    gcs_cors_origins: str = "http://localhost"

    # Provedores de IA / pagamentos (somente backend)
    openai_api_key: str = ""
    fal_api_key: str = ""
    replicate_api_token: str = ""
    elevenlabs_api_key: str = ""
    synclabs_api_key: str = ""
    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    mercadopago_access_token: str = ""
    mercadopago_webhook_secret: str = ""

    # Geração de imagem (E4/D1). `auto` usa OpenAI quando há chave e mock em
    # desenvolvimento; `mock` é recusado em produção para nunca entregar PNG
    # sintético ao usuário final.
    image_provider: str = "auto"
    openai_image_model: str = "gpt-image-1"
    image_provider_timeout_seconds: float = 30.0
    image_gateway_timeout_seconds: float = 25.0
    image_provider_retries: int = 2
    media_root: str = str(_ROOT / "media")
    media_url_prefix: str = "/media"

    model_config = SettingsConfigDict(
        env_file=str(_ROOT.parent / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    @property
    def database_url(self) -> str:
        return (
            "postgresql+psycopg://"
            f"{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
