"""Configuração central via variáveis de ambiente (pydantic-settings)."""

from functools import lru_cache
from pathlib import Path

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_ROOT = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    """Todas as chaves de provedores ficam somente no backend."""

    # Aplicação
    app_env: str = "development"
    api_base_url: str = "http://localhost:8000"
    log_level: str = "INFO"

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
    # Limites do worker (F0): um job preso não pode ocupar o consumidor para sempre.
    worker_soft_timeout_seconds: int = 900
    worker_hard_timeout_seconds: int = 960
    image_generation_enabled: bool = True
    # E5: endpoints de vídeo implementados. Em produção, sem FAL_API_KEY o
    # próprio `get_video_provider` falha com 503 — o flag não entrega mock.
    video_generation_enabled: bool = True
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

    # Geração de imagem (E4/D1). `auto` exige OpenAI: sem OPENAI_API_KEY a
    # seleção falha com 503 em qualquer ambiente. `mock` precisa de opt-in
    # explícito (ALLOW_MOCK_PROVIDERS=true) e é recusado em produção para nunca
    # entregar PNG sintético como se fosse resultado real.
    image_provider: str = "auto"
    openai_image_model: str = "gpt-image-1"
    image_provider_timeout_seconds: float = 30.0
    image_gateway_timeout_seconds: float = 25.0
    image_provider_retries: int = 2

    # Geração de vídeo (E5/D2). `auto` exige fal.ai: sem FAL_API_KEY a seleção
    # falha com 503 em qualquer ambiente. `mock` também depende de opt-in
    # explícito e nunca roda em produção. Webhook é preferencial; polling é
    # o fallback quando FAL_WEBHOOK_URL não está configurada.
    video_provider: str = "auto"
    fal_video_text_model: str = "fal-ai/kling-video/v3/pro/text-to-video"
    fal_video_image_model: str = "fal-ai/kling-video/v3/pro/image-to-video"
    fal_webhook_url: str = ""
    fal_webhook_user_id: str = ""
    fal_jwks_url: str = "https://rest.fal.ai/.well-known/jwks.json"
    video_provider_timeout_seconds: float = 30.0
    video_provider_retries: int = 2
    video_max_duration_seconds: int = 30
    # Polling é fallback: o webhook é preferencial quando FAL_WEBHOOK_URL existe.
    video_poll_attempts: int = 60
    video_poll_interval_seconds: float = 2.0
    webhook_signature_leeway_seconds: int = 300
    jwks_cache_ttl_seconds: int = 3600

    # Upload de imagem para animar foto (E5): validação MIME/tamanho no backend.
    upload_max_bytes: int = 10 * 1024 * 1024

    media_root: str = str(_ROOT / "media")
    media_url_prefix: str = "/media"

    # F0 — honestidade operacional. Mocks de mídia NÃO são o modo padrão do
    # ambiente de desenvolvimento: precisam ser ligados explicitamente e nunca
    # funcionam em produção. Sentry só é ativado quando a DSN existe.
    allow_mock_providers: bool = False
    sentry_dsn: str = ""
    sentry_traces_sample_rate: float = 0.0

    model_config = SettingsConfigDict(
        env_file=str(_ROOT.parent / ".env"),
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    @model_validator(mode="after")
    def _require_production_configuration(self) -> "Settings":
        """Falha na inicialização se produção estiver incompleta ou insegura.

        O objetivo é impedir que um deploy com senhas fracas, auth de
        desenvolvimento, provedores simulados ou webhook sem identidade
        conhecida chegue a aceitar usuários reais. Em desenvolvimento os
        defaults permanecem permissivos para permitir testes sem credenciais.
        """
        if self.app_env.strip().lower() != "production":
            return self

        weak_values = {
            "",
            "trocar",
            "changeme",
            "change-me",
            "secret",
            "password",
            "admin",
        }
        problems: list[str] = []
        if self.auth_provider.strip().lower() != "firebase":
            problems.append("AUTH_PROVIDER=firebase é obrigatório")
        # Sem HMAC próprio: security.py valida ID tokens do Firebase. Exigir um
        # JWT_SECRET no guard daria falsa sensação de segurança (config morta).
        if self.postgres_password.strip().lower() in weak_values:
            problems.append("POSTGRES_PASSWORD não pode ser um valor padrão")
        if not self.firebase_project_id.strip():
            problems.append("FIREBASE_PROJECT_ID é obrigatório")
        if not self.firebase_service_account_json.strip():
            problems.append("FIREBASE_SERVICE_ACCOUNT_JSON é obrigatório")
        if self.allow_mock_providers:
            problems.append("ALLOW_MOCK_PROVIDERS deve ser false")
        if not self.openai_api_key.strip():
            problems.append("OPENAI_API_KEY é obrigatório")
        if not self.fal_api_key.strip():
            problems.append("FAL_API_KEY é obrigatório")
        if not self.fal_webhook_user_id.strip():
            problems.append("FAL_WEBHOOK_USER_ID é obrigatório")
        if problems:
            raise ValueError(
                "Configuração de produção inválida: " + "; ".join(problems)
            )
        return self

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
