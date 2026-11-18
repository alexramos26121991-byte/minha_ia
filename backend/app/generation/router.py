"""Rotas de geração — imagem (E4), vídeo/animação (E5), áudio/avatar (E6)."""

from fastapi import APIRouter, Depends, Query, status

from app.core.errors import not_implemented
from app.core.security import get_current_user_id
from app.generation.schemas import (
    AnimatePhotoIn,
    GenerationOut,
    ImageGenerationIn,
    VideoGenerationIn,
)

router = APIRouter(prefix="/generations", tags=["generations"])


@router.post(
    "/image",
    response_model=GenerationOut,
    status_code=status.HTTP_201_CREATED,
    operation_id="generateImage",
    summary="Gera uma imagem (reserva 5+ créditos, commit/refund)",
)
async def generate_image(
    payload: ImageGenerationIn,
    user_id: str = Depends(get_current_user_id),
) -> GenerationOut:
    raise not_implemented("E4")


@router.post(
    "/video",
    response_model=GenerationOut,
    status_code=status.HTTP_202_ACCEPTED,
    operation_id="generateVideo",
    summary="Enfileira geração de vídeo (202 + job)",
)
async def generate_video(
    payload: VideoGenerationIn,
    user_id: str = Depends(get_current_user_id),
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
    user_id: str = Depends(get_current_user_id),
) -> GenerationOut:
    raise not_implemented("E5")


@router.get(
    "",
    response_model=list[GenerationOut],
    operation_id="listGenerations",
    summary="Lista o histórico de gerações (galeria)",
)
async def list_generations(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    user_id: str = Depends(get_current_user_id),
) -> list[GenerationOut]:
    raise not_implemented("E4")


@router.get(
    "/{generation_id}",
    response_model=GenerationOut,
    operation_id="getGeneration",
    summary="Retorna uma geração pelo id",
)
async def get_generation(
    generation_id: str,
    user_id: str = Depends(get_current_user_id),
) -> GenerationOut:
    raise not_implemented("E4")
