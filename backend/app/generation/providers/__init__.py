"""Provedores de geração de imagem da E4.

Nenhuma chave de API é lida do cliente: a seleção do provedor é feita no
backend a partir das variáveis de ambiente.
"""

from app.generation.providers.base import (
    GeneratedImage,
    ImageProvider,
    ImageProviderError,
    ImageProviderTimeout,
    ImageProviderUnavailable,
)
from app.generation.providers.mock import MockImageProvider
from app.generation.providers.openai import OpenAIImageProvider

__all__ = [
    "GeneratedImage",
    "ImageProvider",
    "ImageProviderError",
    "ImageProviderTimeout",
    "ImageProviderUnavailable",
    "MockImageProvider",
    "OpenAIImageProvider",
]
