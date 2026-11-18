"""Contrato dos provedores de geração de imagem (E4)."""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass(frozen=True)
class GeneratedImage:
    """Resultado binário de um provedor — já pronto para persistência."""

    content: bytes
    media_type: str = "image/png"
    provider: str = "mock"
    extension: str = "png"


class ImageProviderError(Exception):
    """Falha do provedor com mensagem segura para o usuário."""


class ImageProviderTimeout(ImageProviderError):
    """O provedor excedeu seu tempo limite."""


class ImageProviderUnavailable(ImageProviderError):
    """Provedor indisponível, mal configurado ou resposta inesperada."""


class ImageProvider(ABC):
    """ABC que permite trocar mock/OpenAI sem tocar no serviço de geração."""

    name: str = "base"

    @abstractmethod
    def generate(self, *, prompt: str, style: str | None, size: str) -> GeneratedImage:
        """Gera uma imagem. Implementações podem ser síncronas (threadpool)."""
