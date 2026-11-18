"""Rotas de geração — imagem (E4), vídeo/animação (E5), áudio/avatar (E6)."""

from typing import Literal

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import get_current_user
from app.core.errors import not_implemented
from app.generation.deps import get_image_provider, get_media_storage
from app.generation.providers.base import ImageProvider
from app.generation.schemas import (
    AnimatePhotoIn,
    GenerationOut,
    ImageGenerationIn,
    VideoGenerationIn,
)
from app.generation.service import GenerationService
from app.generation.storage import MediaStorage
from app.users.model import User

router = APIRouter(prefix="/generations", tags=["generations"])


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
async def generate_video(
    payload: VideoGenerationIn,
    user: User = Depends(get_current_user),
) -> GenerationOut:
    raise not_implemented("E5")


@router.post(
    "/animate-photo",
    response_model=GenerationOut,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id="animatePhoto",
    summary="Enfileira animação de fotografia",
)
async def animate_photo(
    payload: AnimatePhotoIn,
    user: User = Depends(get_current_user),
) -> GenerationOut:
    raise not_implemented("E5")


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
