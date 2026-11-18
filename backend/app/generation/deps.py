"""Dependencies de geração — seleção de provedor e storage no backend."""

from __future__ import annotations

from fastapi import HTTPException, status

from app.core.config import settings
from app.generation.providers.base import ImageProvider
from app.generation.providers.mock import MockImageProvider
from app.generation.providers.openai import OpenAIImageProvider
from app.generation.storage import LocalMediaStorage, MediaStorage

_PROVIDERS = frozenset({"auto", "openai", "mock"})


def _unavailable(detail: str) -> HTTPException:
    """Erro de configuração do provedor, seguro para o cliente."""
    return HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=detail)


def get_image_provider() -> ImageProvider:
    """Seleciona o provedor de imagem (D1: OpenAI GPT Image).

    ``auto`` prefere OpenAI quando a chave existe; sem chave, só permite o mock
    fora de produção. Em produção a ausência de chave falha fechado com 503.
    """
    mode = settings.image_provider.strip().lower()
    if mode not in _PROVIDERS:
        raise _unavailable("Provedor de imagem inválido no servidor.")

    if mode == "auto":
        mode = "openai" if settings.openai_api_key.strip() else "mock"

    if mode == "mock":
        if settings.app_env.strip().lower() == "production":
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


def get_media_storage() -> MediaStorage:
    return LocalMediaStorage(
        settings.media_root,
        url_prefix=settings.media_url_prefix,
    )
