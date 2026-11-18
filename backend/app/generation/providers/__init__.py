"""Provedores de geração da E4/E5.

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
from app.generation.providers.falai import FalVideoProvider
from app.generation.providers.mock import MockImageProvider
from app.generation.providers.mock_video import MockVideoProvider
from app.generation.providers.openai import OpenAIImageProvider
from app.generation.providers.video_base import (
    GeneratedVideo,
    VideoJob,
    VideoJobFailed,
    VideoOperation,
    VideoProvider,
    VideoProviderError,
    VideoProviderTimeout,
    VideoProviderUnavailable,
)

__all__ = [
    "FalVideoProvider",
    "GeneratedImage",
    "GeneratedVideo",
    "ImageProvider",
    "ImageProviderError",
    "ImageProviderTimeout",
    "ImageProviderUnavailable",
    "MockImageProvider",
    "MockVideoProvider",
    "OpenAIImageProvider",
    "VideoJob",
    "VideoJobFailed",
    "VideoOperation",
    "VideoProvider",
    "VideoProviderError",
    "VideoProviderTimeout",
    "VideoProviderUnavailable",
]
