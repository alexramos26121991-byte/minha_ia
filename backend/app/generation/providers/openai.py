"""Provedor OpenAI de geração de imagem via httpx (somente no backend)."""

from __future__ import annotations

import base64
import logging
import time

import httpx

from app.generation.providers.base import (
    GeneratedImage,
    ImageProvider,
    ImageProviderTimeout,
    ImageProviderUnavailable,
)

logger = logging.getLogger(__name__)

SUPPORTED_SIZES = frozenset({"1024x1024", "1024x1536", "1536x1024"})
_RETRYABLE = frozenset({429, 500, 502, 503, 504})


class OpenAIImageProvider(ImageProvider):
    """Chama ``POST /v1/images/generations`` com resposta ``b64_json``."""

    name = "openai"

    def __init__(
        self,
        api_key: str,
        *,
        model: str = "gpt-image-1",
        timeout: float = 30.0,
        retries: int = 2,
        base_url: str = "https://api.openai.com/v1",
    ) -> None:
        if not api_key:
            raise ImageProviderUnavailable("OPENAI_API_KEY não configurada no servidor.")
        self._api_key = api_key
        self.model = model
        self.timeout = timeout
        self.retries = max(0, retries)
        self.base_url = base_url.rstrip("/")

    def generate(self, *, prompt: str, style: str | None, size: str) -> GeneratedImage:
        if size not in SUPPORTED_SIZES:
            raise ImageProviderUnavailable(
                "Tamanho não suportado. Escolha 1024x1024, 1024x1536 ou 1536x1024."
            )

        body: dict[str, object] = {
            "model": self.model,
            "prompt": prompt if not style else f"{prompt}. Estilo: {style}",
            "n": 1,
            "size": size,
        }
        headers = {
            "Authorization": f"Bearer {self._api_key}",
            "Content-Type": "application/json",
        }

        last_error: ImageProviderError = ImageProviderUnavailable(
            "Não foi possível gerar a imagem. Tente novamente."
        )
        for attempt in range(self.retries + 1):
            try:
                with httpx.Client(timeout=self.timeout) as client:
                    response = client.post(
                        f"{self.base_url}/images/generations",
                        headers=headers,
                        json=body,
                    )
            except httpx.TimeoutException as exc:
                logger.warning("OpenAI timeout na tentativa %s", attempt + 1)
                last_error = ImageProviderTimeout(
                    "O provedor demorou para responder. Tente novamente."
                )
            except httpx.RequestError as exc:
                logger.warning("OpenAI falha de rede: %s", type(exc).__name__)
                last_error = ImageProviderUnavailable(
                    "Não foi possível conectar ao provedor. Tente novamente."
                )
            else:
                if response.status_code == 200:
                    try:
                        encoded = response.json()["data"][0]["b64_json"]
                        content = base64.b64decode(encoded, validate=True)
                    except (KeyError, IndexError, TypeError, ValueError) as exc:
                        logger.warning("OpenAI resposta inesperada: %s", type(exc).__name__)
                        last_error = ImageProviderUnavailable(
                            "O provedor devolveu uma resposta inesperada. Tente novamente."
                        )
                    else:
                        return GeneratedImage(
                            content=content,
                            media_type="image/png",
                            provider=self.name,
                            extension="png",
                        )
                else:
                    logger.warning("OpenAI HTTP %s", response.status_code)
                    last_error = ImageProviderUnavailable(
                        "O provedor não conseguiu gerar a imagem. Revise o prompt e tente novamente."
                        if response.status_code == 400
                        else "O provedor está temporariamente indisponível. Tente novamente."
                    )
                    if response.status_code in _RETRYABLE:
                        if attempt < self.retries:
                            time.sleep(0.5 * (2**attempt))
                            continue
                        if response.status_code == 429:
                            last_error = ImageProviderUnavailable(
                                "O provedor está com tráfego elevado. Tente novamente em instantes."
                            )

            if attempt < self.retries and isinstance(last_error, ImageProviderTimeout):
                time.sleep(0.5 * (2**attempt))

        raise last_error
