"""Provedor local de vídeo para desenvolvimento — sem rede, sem chave.

Não gera um vídeo reproduzível: devolve um cabeçalho MP4 válido o suficiente
para validar fila, storage, galeria e estorno sem custo. É recusado em produção
pela dependency, exatamente como o provedor de imagem.
"""

from __future__ import annotations

import hashlib

from app.generation.providers.video_base import (
    GeneratedVideo,
    VideoJob,
    VideoOperation,
    VideoProvider,
)

# Boxes ISO BMFF mínimos (ftyp + free). Dev-only: não é um vídeo assistível.
_PLACEHOLDER_MP4 = (
    b"\x00\x00\x00\x18ftypmp42\x00\x00\x00\x00mp42isom"
    b"\x00\x00\x00\x08free"
)


class MockVideoProvider(VideoProvider):
    """Job instantâneo e bytes determinísticos para testes locais."""

    name = "mock"

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
        seed = "|".join(
            [
                operation.value,
                prompt or "",
                image_url or "",
                motion or "",
                str(duration_seconds),
                resolution,
            ]
        )
        request_id = hashlib.sha256(seed.encode("utf-8")).hexdigest()[:24]
        return VideoJob(
            provider_request_id=request_id,
            status_url=f"mock://video/{request_id}/status",
            response_url=f"mock://video/{request_id}/result",
            provider=self.name,
        )

    def status(self, job: VideoJob) -> str:
        return "COMPLETED"

    def result(self, job: VideoJob) -> GeneratedVideo:
        return GeneratedVideo(
            content=_PLACEHOLDER_MP4,
            media_type="video/mp4",
            provider=self.name,
            extension="mp4",
        )
