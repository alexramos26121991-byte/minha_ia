"""Dependencies de geração — seleção de provedor e storage no backend."""

from __future__ import annotations

from app.core.config import settings
from app.generation.providers.base import ImageProvider
from app.generation.providers.mock import MockImageProvider
from app.generation.providers.openai import OpenAIImageProvider
from app.generation.storage import LocalMediaStorage, MediaStorage


def get_image_provider() -> ImageProvider:
    """OpenAI quando há chave; mock local caso contrário."""
    if settings.openai_api_key:
        return OpenAIImageProvider(
            settings.openai_api_key,
            model=settings.openai_image_model,
            timeout=settings.image_provider_timeout_seconds,
            retries=settings.image_provider_retries,
        )
    return MockImageProvider()


def get_media_storage() -> MediaStorage:
    return LocalMediaStorage(
        settings.media_root,
        url_prefix=settings.media_url_prefix,
    )
