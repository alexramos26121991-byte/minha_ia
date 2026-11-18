"""Dependencies de geração — seleção de provedor, webhook e storage no backend."""

from __future__ import annotations

from fastapi import HTTPException, status

from app.core.config import settings
from app.generation.providers.base import ImageProvider
from app.generation.providers.falai import FalVideoProvider
from app.generation.providers.mock import MockImageProvider
from app.generation.providers.mock_video import MockVideoProvider
from app.generation.providers.openai import OpenAIImageProvider
from app.generation.providers.video_base import VideoProvider
from app.generation.storage import LocalMediaStorage, MediaStorage
from app.generation.webhook import FalWebhookVerifier

_IMAGE_PROVIDERS = frozenset({"auto", "openai", "mock"})
_VIDEO_PROVIDERS = frozenset({"auto", "falai", "mock"})


def _unavailable(detail: str) -> HTTPException:
    """Erro de configuração do provedor, seguro para o cliente."""
    return HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=detail)


def _is_production() -> bool:
    return settings.app_env.strip().lower() == "production"


def get_image_provider() -> ImageProvider:
    """Seleciona o provedor de imagem (D1: OpenAI GPT Image).

    ``auto`` prefere OpenAI quando a chave existe; sem chave, só permite o mock
    fora de produção. Em produção a ausência de chave falha fechado com 503.
    """
    mode = settings.image_provider.strip().lower()
    if mode not in _IMAGE_PROVIDERS:
        raise _unavailable("Provedor de imagem inválido no servidor.")

    if mode == "auto":
        mode = "openai" if settings.openai_api_key.strip() else "mock"

    if mode == "mock":
        if _is_production():
            raise _unavailable("Provedor de imagem não configurado para produção.")
        return MockImageProvider()

    if not settings.openai_api_key.strip():
        raise _unavailable("OPENAI_API_KEY não configurada no servidor.")

    return OpenAIImageProvider(
        settings.openai_api_key,
        model=settings.openai_image_model,
        timeout=settings.image_provider_timeout_seconds,
        retries=settings.image_provider_retries,
    )


def get_video_provider() -> VideoProvider:
    """Seleciona o provedor de vídeo (D2: fal.ai + Kling).

    Ainda não injetado nas rotas: a E5 liga esta dependency ao worker. A regra
    é a mesma da imagem — mock nunca chega a produção.
    """
    mode = settings.video_provider.strip().lower()
    if mode not in _VIDEO_PROVIDERS:
        raise _unavailable("Provedor de vídeo inválido no servidor.")

    if mode == "auto":
        mode = "falai" if settings.fal_api_key.strip() else "mock"

    if mode == "mock":
        if _is_production():
            raise _unavailable("Provedor de vídeo não configurado para produção.")
        return MockVideoProvider()

    if not settings.fal_api_key.strip():
        raise _unavailable("FAL_API_KEY não configurada no servidor.")

    return FalVideoProvider(
        settings.fal_api_key,
        text_model=settings.fal_video_text_model,
        image_model=settings.fal_video_image_model,
        timeout=settings.video_provider_timeout_seconds,
        retries=settings.video_provider_retries,
        webhook_url=settings.fal_webhook_url,
    )


def get_fal_webhook_verifier() -> FalWebhookVerifier:
    """Verificador de assinatura do webhook do fal.ai (JWKS Ed25519)."""
    return FalWebhookVerifier(
        jwks_url=settings.fal_jwks_url,
        leeway_seconds=settings.webhook_signature_leeway_seconds,
        cache_ttl_seconds=settings.jwks_cache_ttl_seconds,
        expected_user_id=settings.fal_webhook_user_id,
    )


def get_media_storage() -> MediaStorage:
    return LocalMediaStorage(
        settings.media_root,
        url_prefix=settings.media_url_prefix,
    )
