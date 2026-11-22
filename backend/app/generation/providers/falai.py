"""Adaptador fal.ai (Kling) para vídeo — somente no backend (D2).

Usa a Queue API: ``POST /{owner}/{app}`` devolve ``request_id`` + URLs de
status/resultado; o worker consulta ``status()`` e, ao terminar, ``result()``
baixa o arquivo de ``*.fal.media``. A chave nunca sai do servidor.

Nenhum endpoint da nossa API muda aqui: este módulo é a preparação da E5.
"""

from __future__ import annotations

import logging
import time
from urllib.parse import urlparse

import httpx

from app.generation.providers.language import compor_prompt_video
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

logger = logging.getLogger(__name__)

TEXT_MODEL = "fal-ai/kling-video/v3/pro/text-to-video"
IMAGE_MODEL = "fal-ai/kling-video/v3/pro/image-to-video"
_QUEUE_BASE = "https://queue.fal.run"
_MEDIA_HOST_SUFFIX = ".fal.media"
_MEDIA_HOST = "fal.media"
_RETRYABLE = frozenset({429, 500, 502, 503, 504})
_STATUSES = frozenset({"IN_QUEUE", "IN_PROGRESS", "COMPLETED"})


class FalVideoProvider(VideoProvider):
    """Fila do fal.ai com modelos Kling para texto→vídeo e imagem→vídeo."""

    name = "falai"

    def __init__(
        self,
        api_key: str,
        *,
        text_model: str = TEXT_MODEL,
        image_model: str = IMAGE_MODEL,
        timeout: float = 30.0,
        retries: int = 2,
        webhook_url: str = "",
        queue_base: str = _QUEUE_BASE,
        max_video_bytes: int = 200 * 1024 * 1024,
        transport: httpx.BaseTransport | None = None,
    ) -> None:
        if not api_key:
            raise VideoProviderUnavailable("FAL_API_KEY não configurada no servidor.")
        self._api_key = api_key
        self.text_model = text_model
        self.image_model = image_model
        self.timeout = timeout
        self.retries = max(0, retries)
        self.webhook_url = webhook_url
        self.queue_base = queue_base.rstrip("/")
        self.max_video_bytes = max_video_bytes
        self._transport = transport

    def _new_client(self) -> httpx.Client:
        if self._transport is None:
            return httpx.Client(timeout=self.timeout)
        return httpx.Client(timeout=self.timeout, transport=self._transport)

    @property
    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Key {self._api_key}",
            "Content-Type": "application/json",
        }

    def _guard_api_url(self, url: str) -> str:
        """Impede que uma resposta do provedor redirecione a chamada para outro host."""
        parsed = urlparse(url)
        allowed = urlparse(self.queue_base).hostname
        if parsed.scheme != "https" or not parsed.hostname or parsed.hostname != allowed:
            raise VideoProviderUnavailable("O provedor devolveu uma URL de fila inválida.")
        return url

    @staticmethod
    def _guard_media_url(url: str) -> str:
        parsed = urlparse(url)
        host = (parsed.hostname or "").lower()
        if parsed.scheme != "https" or not (
            host == _MEDIA_HOST or host.endswith(_MEDIA_HOST_SUFFIX)
        ):
            raise VideoProviderUnavailable("O provedor devolveu uma URL de mídia inválida.")
        return url

    @staticmethod
    def _compose_prompt(prompt: str | None, motion: str | None) -> str:
        return compor_prompt_video(prompt, motion)

    def _request_json(
        self,
        method: str,
        url: str,
        *,
        body: dict | None = None,
        params: dict | None = None,
    ) -> tuple[int, dict]:
        """Executa a chamada com retry em 429/5xx/timeout/erro de rede."""
        last_error: VideoProviderError = VideoProviderUnavailable(
            "O provedor de vídeo está temporariamente indisponível. Tente novamente."
        )
        with self._new_client() as client:
            for attempt in range(self.retries + 1):
                retry = False
                try:
                    response = client.request(
                        method,
                        url,
                        headers=self._headers,
                        json=body,
                        params=params,
                    )
                except httpx.TimeoutException as exc:
                    logger.warning("fal.ai timeout na tentativa %s", attempt + 1)
                    last_error = VideoProviderTimeout(
                        "O provedor de vídeo demorou para responder. Tente novamente."
                    )
                    retry = True
                except httpx.RequestError as exc:
                    logger.warning("fal.ai falha de rede: %s", type(exc).__name__)
                    last_error = VideoProviderUnavailable(
                        "Não foi possível conectar ao provedor de vídeo. Tente novamente."
                    )
                    retry = True
                else:
                    if 200 <= response.status_code < 300:
                        try:
                            return response.status_code, response.json()
                        except ValueError as exc:
                            raise VideoProviderUnavailable(
                                "O provedor devolveu uma resposta inesperada. Tente novamente."
                            ) from exc
                    if response.status_code in (401, 403):
                        raise VideoProviderUnavailable(
                            "O provedor de vídeo não está configurado corretamente no servidor."
                        )
                    if response.status_code == 400:
                        raise VideoProviderUnavailable(
                            "O provedor não aceitou os parâmetros do vídeo. Revise e tente novamente."
                        )
                    if response.status_code == 404:
                        raise VideoProviderUnavailable("O job de vídeo não foi encontrado no provedor.")
                    logger.warning("fal.ai HTTP %s em %s", response.status_code, url)
                    last_error = VideoProviderUnavailable(
                        "O provedor de vídeo está temporariamente indisponível. Tente novamente."
                    )
                    retry = response.status_code in _RETRYABLE

                if attempt < self.retries:
                    if not retry:
                        break
                    time.sleep(0.5 * (2**attempt))

        raise last_error

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
        if operation not in set(VideoOperation):
            raise VideoProviderUnavailable("Operação de vídeo não suportada.")
        if operation in (VideoOperation.IMAGE_TO_VIDEO, VideoOperation.ANIMATE_PHOTO) and not image_url:
            raise VideoProviderUnavailable("É necessária uma imagem para animar.")

        model = (
            self.image_model
            if operation in (VideoOperation.IMAGE_TO_VIDEO, VideoOperation.ANIMATE_PHOTO)
            else self.text_model
        )
        body: dict[str, object] = {
            "prompt": self._compose_prompt(prompt, motion),
            "duration": duration_seconds,
            "resolution": resolution,
        }
        if image_url:
            body["image_url"] = image_url

        params = {"fal_webhook": self.webhook_url} if self.webhook_url else None
        _, payload = self._request_json(
            "POST", f"{self.queue_base}/{model}", body=body, params=params
        )
        request_id = payload.get("request_id")
        if not isinstance(request_id, str) or not request_id:
            raise VideoProviderUnavailable("O provedor não devolveu um id de job.")

        # As URLs vêm na resposta; se faltarem, montamos só com owner/app.
        owner_app = "/".join(model.split("/")[:2])
        fallback = f"{self.queue_base}/{owner_app}/requests/{request_id}"
        status_url = self._guard_api_url(payload.get("status_url") or f"{fallback}/status")
        response_url = self._guard_api_url(payload.get("response_url") or fallback)
        return VideoJob(
            provider_request_id=request_id,
            status_url=status_url,
            response_url=response_url,
            provider=self.name,
        )

    def status(self, job: VideoJob) -> str:
        _, payload = self._request_json("GET", self._guard_api_url(job.status_url))
        value = str(payload.get("status", "")).upper()
        if value not in _STATUSES:
            raise VideoProviderUnavailable("O provedor devolveu um status de vídeo inesperado.")
        return value

    def result(self, job: VideoJob) -> GeneratedVideo:
        _, payload = self._request_json("GET", self._guard_api_url(job.response_url))
        error = payload.get("error")
        if error:
            raise VideoJobFailed("O provedor não conseguiu gerar o vídeo. Tente novamente.")

        candidate = payload.get("video")
        if candidate is None:
            videos = payload.get("videos")
            candidate = videos[0] if isinstance(videos, list) and videos else None
        url = candidate.get("url") if isinstance(candidate, dict) else candidate
        if not isinstance(url, str) or not url:
            raise VideoProviderUnavailable("O provedor não devolveu o arquivo de vídeo.")

        download_url = self._guard_media_url(url)
        chunks: list[bytes] = []
        total = 0
        content_type = "video/mp4"
        with self._new_client() as client:
            try:
                with client.stream("GET", download_url, headers={"Authorization": f"Key {self._api_key}"}) as response:
                    if response.status_code != 200:
                        raise VideoProviderUnavailable(
                            "Não foi possível baixar o vídeo gerado. Tente novamente."
                        )
                    header_type = response.headers.get("content-type", "").split(";")[0].strip()
                    if header_type.startswith("video/"):
                        content_type = header_type
                    for chunk in response.iter_bytes():
                        total += len(chunk)
                        if total > self.max_video_bytes:
                            raise VideoProviderUnavailable("O vídeo gerado excede o tamanho permitido.")
                        chunks.append(chunk)
            except httpx.TimeoutException as exc:
                raise VideoProviderTimeout(
                    "O download do vídeo demorou para responder. Tente novamente."
                ) from exc
            except httpx.RequestError as exc:
                raise VideoProviderUnavailable(
                    "Não foi possível baixar o vídeo gerado. Tente novamente."
                ) from exc

        if not chunks:
            raise VideoProviderUnavailable("O provedor devolveu um vídeo vazio.")
        content = b"".join(chunks)
        # O content-type vem do provedor; o magic bytes é a verdade do arquivo.
        # Um HTML de erro salvo como .mp4 quebraria a galeria do usuário.
        if len(content) < 12 or content[4:8] != b"ftyp":
            raise VideoProviderUnavailable("O provedor não devolveu um vídeo MP4 válido.")
        return GeneratedVideo(
            content=content,
            media_type=content_type,
            provider=self.name,
            extension="mp4",
        )
