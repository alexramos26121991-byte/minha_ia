"""Contrato dos provedores de vídeo (D2/E5).

Vídeo é assíncrono por natureza: o provedor recebe ``submit()``, devolve um
handle com ``request_id`` e URLs de status/resultado, e o worker consulta
``status()`` até ``COMPLETED`` antes de baixar com ``result()``. O mesmo handle
serve para o caminho de webhook (o evento só confirma que o job terminou).
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from enum import Enum


class VideoOperation(str, Enum):
    """Operações de vídeo suportadas pelo contrato."""

    TEXT_TO_VIDEO = "text_to_video"
    IMAGE_TO_VIDEO = "image_to_video"
    ANIMATE_PHOTO = "animate_photo"


@dataclass(frozen=True)
class VideoJob:
    """Handle devolvido pelo provedor após ``submit()``."""

    provider_request_id: str
    status_url: str
    response_url: str
    provider: str = "base"


@dataclass(frozen=True)
class GeneratedVideo:
    """Bytes do vídeo já prontos para o storage."""

    content: bytes
    media_type: str = "video/mp4"
    provider: str = "base"
    extension: str = "mp4"


class VideoProviderError(Exception):
    """Falha do provedor com mensagem segura para o usuário."""


class VideoProviderTimeout(VideoProviderError):
    """O provedor excedeu seu tempo limite."""


class VideoProviderUnavailable(VideoProviderError):
    """Provedor mal configurado, indisponível ou resposta inesperada."""


class VideoJobFailed(VideoProviderError):
    """O job terminou, mas o provedor reportou falha no resultado."""


class VideoProvider(ABC):
    """ABC que permite trocar fal.ai/mock sem tocar no worker da E5."""

    name: str = "base"

    @abstractmethod
    def submit(
        self,
        *,
        operation: VideoOperation,
        prompt: str | None,
        image_url: str | None,
        motion: str | None,
        duration_seconds: int,
        resolution: str,
    ) -> VideoJob:
        """Envia o job para a fila e devolve o handle (não espera o vídeo)."""

    @abstractmethod
    def status(self, job: VideoJob) -> str:
        """Devolve ``IN_QUEUE``, ``IN_PROGRESS`` ou ``COMPLETED``."""

    @abstractmethod
    def result(self, job: VideoJob) -> GeneratedVideo:
        """Baixa e valida o vídeo de um job ``COMPLETED``."""
