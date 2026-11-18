"""Rotas de geração — imagem (E4), vídeo/animação (E5), áudio/avatar (E6)."""

import uuid
from typing import Literal

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.deps import get_current_user
from app.generation.deps import (
    get_image_provider,
    get_media_storage,
    get_video_job_dispatcher,
    get_video_provider,
)
from app.generation.providers.base import ImageProvider
from app.generation.providers.video_base import VideoOperation, VideoProvider
from app.generation.schemas import (
    AnimatePhotoIn,
    GenerationOut,
    ImageGenerationIn,
    UploadOut,
    VideoGenerationIn,
)
from app.generation.service import GenerationService
from app.generation.storage import MediaStorage
from app.generation.video_service import JobDispatcher, VideoGenerationService
from app.users.model import User

router = APIRouter(prefix="/generations", tags=["generations"])

# MIME declarado + assinatura real do arquivo: um HTML renomeado não vira imagem.
_ALLOWED_UPLOADS: dict[str, tuple[bytes, str]] = {
    "image/png": (b"\x89PNG\r\n\x1a\n", "png"),
    "image/jpeg": (b"\xff\xd8\xff", "jpg"),
    "image/webp": (b"RIFF", "webp"),
}


def _upload_extension(media_type: str, content: bytes) -> str:
    allowed = _ALLOWED_UPLOADS.get(media_type)
    if allowed is None:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="Use uma imagem PNG, JPEG ou WebP.",
        )
    magic, extension = allowed
    if not content.startswith(magic):
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="O arquivo não é uma imagem válida.",
        )
    if extension == "webp" and content[8:12] != b"WEBP":
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail="O arquivo não é uma imagem válida.",
        )
    return extension


@router.post(
    "/image",
    response_model=GenerationOut,
    status_code=status.HTTP_201_CREATED,
    operation_id="generateImage",
    summary="Gera uma imagem (reserva, confirma ou estorna créditos)",
)
def generate_image(
    payload: ImageGenerationIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    provider: ImageProvider = Depends(get_image_provider),
    storage: MediaStorage = Depends(get_media_storage),
) -> GenerationOut:
    return GenerationService.generate_image(
        db, user=user, payload=payload, provider=provider, storage=storage
    )


@router.post(
    "/video",
    response_model=GenerationOut,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id="generateVideo",
    summary="Enfileira geração de vídeo (202 + job)",
)
def generate_video(
    payload: VideoGenerationIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    provider: VideoProvider = Depends(get_video_provider),
    storage: MediaStorage = Depends(get_media_storage),
    dispatcher: JobDispatcher = Depends(get_video_job_dispatcher),
) -> GenerationOut:
    return VideoGenerationService.enqueue(
        db,
        user=user,
        operation=VideoOperation.TEXT_TO_VIDEO,
        payload=payload,
        provider=provider,
        storage=storage,
        dispatcher=dispatcher,
    )


@router.post(
    "/animate-photo",
    response_model=GenerationOut,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id="animatePhoto",
    summary="Enfileira animação de fotografia",
)
def animate_photo(
    payload: AnimatePhotoIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    provider: VideoProvider = Depends(get_video_provider),
    storage: MediaStorage = Depends(get_media_storage),
    dispatcher: JobDispatcher = Depends(get_video_job_dispatcher),
) -> GenerationOut:
    return VideoGenerationService.enqueue(
        db,
        user=user,
        operation=VideoOperation.ANIMATE_PHOTO,
        payload=payload,
        provider=provider,
        storage=storage,
        dispatcher=dispatcher,
    )


@router.post(
    "/uploads",
    response_model=UploadOut,
    status_code=status.HTTP_201_CREATED,
    operation_id="uploadGenerationImage",
    summary="Envia uma imagem para animar (MIME/tamanho validados no backend)",
)
async def upload_generation_image(
    file: UploadFile = File(..., description="PNG, JPEG ou WebP"),
    user: User = Depends(get_current_user),
    storage: MediaStorage = Depends(get_media_storage),
) -> UploadOut:
    content = await file.read(settings.upload_max_bytes + 1)
    if len(content) > settings.upload_max_bytes:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="A imagem deve ter no máximo 10 MB.",
        )
    extension = _upload_extension(file.content_type or "", content)
    path = storage.save(
        user_id=user.id,
        generation_id=uuid.uuid4(),
        content=content,
        extension=extension,
    )
    return UploadOut(image_url=storage.url_for(path), media_type=file.content_type or "")


@router.get(
    "",
    response_model=list[GenerationOut],
    operation_id="listGenerations",
    summary="Lista o histórico de gerações (galeria)",
)
def list_generations(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    generation_type: Literal["image", "video", "animate_photo"] | None = Query(
        default=None,
        alias="type",
        description="Filtra a galeria por tipo de geração.",
    ),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: MediaStorage = Depends(get_media_storage),
) -> list[GenerationOut]:
    return GenerationService.list(
        db,
        user=user,
        storage=storage,
        limit=limit,
        offset=offset,
        generation_type=generation_type,
    )


@router.get(
    "/{generation_id}",
    response_model=GenerationOut,
    operation_id="getGeneration",
    summary="Retorna uma geração pelo id",
)
def get_generation(
    generation_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: MediaStorage = Depends(get_media_storage),
) -> GenerationOut:
    return GenerationService.get(db, user=user, storage=storage, generation_id=generation_id)


@router.delete(
    "/{generation_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    operation_id="deleteGeneration",
    summary="Remove uma geração da galeria (sem estorno de crédito)",
)
def delete_generation(
    generation_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    storage: MediaStorage = Depends(get_media_storage),
) -> None:
    GenerationService.delete(db, user=user, storage=storage, generation_id=generation_id)
