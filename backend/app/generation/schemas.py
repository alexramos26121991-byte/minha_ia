"""Schemas de geração (ADR 0003 — custo em créditos no backend)."""

import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, HttpUrl


class ImageGenerationIn(BaseModel):
    prompt: str = Field(min_length=1, max_length=2000)
    style: str | None = Field(default=None, max_length=80)
    size: str = Field(default="1024x1024", pattern=r"^\d{3,4}x\d{3,4}$")
    idempotency_key: str = Field(min_length=8, max_length=128)


class VideoGenerationIn(BaseModel):
    prompt: str = Field(min_length=1, max_length=2000)
    duration_seconds: int = Field(default=5, ge=2, le=30)
    resolution: str = Field(default="720p", pattern=r"^(480p|720p|1080p)$")
    idempotency_key: str = Field(min_length=8, max_length=128)


class AnimatePhotoIn(BaseModel):
    image_url: HttpUrl
    motion: str | None = Field(default=None, max_length=80)
    idempotency_key: str = Field(min_length=8, max_length=128)


class UploadOut(BaseModel):
    """URL pública da imagem enviada ao backend para animar depois."""

    image_url: str
    media_type: str


class GenerationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    user_id: uuid.UUID
    type: str
    status: str
    provider: str | None = None
    cost_credits: int
    storage_path: str | None = None
    created_at: datetime
    # Campos derivados pelo serviço (não existem na tabela `generations`).
    media_url: str | None = None
    prompt: str | None = None
    error_message: str | None = None
    # 0..100. Vídeos em fila começam em 0; imagens concluídas em 100.
    progress: int = Field(default=0, ge=0, le=100)
