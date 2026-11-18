"""Serviço de geração de imagem — débito, provider, storage e estorno.

Regras (ADRs 0003/0004):

* custo vem sempre de ``cost_config``;
* a reserva usa uma chave prefixada ``image:<user_id>:<key>`` — o valor enviado
  pelo cliente nunca é usado diretamente no ledger;
* sucesso => ``commit``; falha/timeout => ``refund`` + erro amigável em pt-BR;
* repetir a mesma chave devolve a geração existente sem debitar duas vezes.
"""

from __future__ import annotations

import logging
import uuid
from concurrent.futures import ThreadPoolExecutor
from concurrent.futures import TimeoutError as FutureTimeout

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.credits.service import CostNotConfigured, CreditService, InsufficientCredits
from app.generation.model import Generation
from app.generation.providers.base import (
    GeneratedImage,
    ImageProvider,
    ImageProviderError,
    ImageProviderTimeout,
)
from app.generation.schemas import GenerationOut, ImageGenerationIn
from app.generation.storage import MediaStorage
from app.users.model import User

logger = logging.getLogger(__name__)

GENERATION_NOT_FOUND = "Geração não encontrada."


def _to_out(row: Generation, storage: MediaStorage) -> GenerationOut:
    """Converte o modelo em DTO, derivando campos que não existem no banco."""
    return GenerationOut.model_validate(row).model_copy(
        update={
            "media_url": storage.url_for(row.storage_path) if row.storage_path else None,
            "prompt": row.prompt,
            "error_message": row.error_message,
        }
    )


def _call_provider(provider: ImageProvider, payload: ImageGenerationIn) -> GeneratedImage:
    """Executa o provedor em thread separada com limite de gateway.

    O provedor tem timeout próprio (30s por padrão); o gateway limita a espera
    do cliente (25s por padrão). Ao estourar, a thread é abandonada para que o
    cliente não fique preso — o estorno acontece no chamador.
    """
    pool = ThreadPoolExecutor(max_workers=1, thread_name_prefix="image-provider")
    shut_down = False
    try:
        future = pool.submit(
            provider.generate,
            prompt=payload.prompt,
            style=payload.style,
            size=payload.size,
        )
        try:
            return future.result(timeout=settings.image_gateway_timeout_seconds)
        except (FutureTimeout, TimeoutError) as exc:
            pool.shutdown(wait=False, cancel_futures=True)
            shut_down = True
            raise ImageProviderTimeout(
                "A geração demorou mais do que o esperado. Seus créditos foram "
                "devolvidos — tente novamente."
            ) from exc
    finally:
        if not shut_down:
            pool.shutdown(wait=True)


def _fail(
    db: Session,
    generation: Generation,
    reservation_key: str,
    message: str,
    status_code: int,
) -> None:
    """Estorna, registra a falha e responde com erro amigável."""
    try:
        CreditService.refund(db, reservation_key, reason=f"estorno por falha: {message[:120]}")
    except Exception:  # nunca deixa o estorno esconder o erro original
        logger.exception("Falha ao estornar a reserva %s", reservation_key)
    generation.status = "failed"
    generation.error_message = message[:500]
    db.commit()
    db.refresh(generation)
    raise HTTPException(status_code=status_code, detail=message)


def _find_owned(
    db: Session, user: User, generation_id: str
) -> Generation:
    try:
        parsed = uuid.UUID(generation_id)
    except (ValueError, AttributeError):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=GENERATION_NOT_FOUND)
    row = db.execute(
        select(Generation).where(
            Generation.id == parsed,
            Generation.user_id == user.id,
        )
    ).scalar_one_or_none()
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=GENERATION_NOT_FOUND)
    return row


class GenerationService:
    """Operações sobre gerações — uma transação por ação do usuário."""

    @staticmethod
    def generate_image(
        db: Session,
        *,
        user: User,
        payload: ImageGenerationIn,
        provider: ImageProvider,
        storage: MediaStorage,
    ) -> GenerationOut:
        if not settings.image_generation_enabled:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="A geração de imagens está temporariamente indisponível. Tente novamente em instantes.",
            )

        reservation_key = f"image:{user.id}:{payload.idempotency_key}"
        existing = db.execute(
            select(Generation).where(Generation.idempotency_key == reservation_key)
        ).scalar_one_or_none()
        if existing is not None:
            logger.info("Geração idempotente %s", reservation_key)
            return _to_out(existing, storage)

        try:
            cost = CreditService.get_cost_credits(db, "image")
        except CostNotConfigured:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Os custos de geração ainda não foram configurados.",
            )
        try:
            CreditService.reserve(
                db,
                user.id,
                cost,
                reservation_key,
                reason="reserva para gerar imagem",
            )
        except InsufficientCredits as exc:
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED, detail=str(exc)
            ) from exc

        generation = Generation(
            id=uuid.uuid4(),
            user_id=user.id,
            type="image",
            status="pending",
            provider=provider.name,
            cost_credits=cost,
            idempotency_key=reservation_key,
            prompt=payload.prompt,
        )
        db.add(generation)
        db.commit()
        db.refresh(generation)

        try:
            image = _call_provider(provider, payload)
        except ImageProviderTimeout as exc:
            _fail(db, generation, reservation_key, str(exc), 504)
        except ImageProviderError as exc:
            _fail(db, generation, reservation_key, str(exc), 502)
        except Exception as exc:  # falha imprevista também estorna
            logger.exception("Falha inesperada no provedor de imagem")
            _fail(
                db,
                generation,
                reservation_key,
                "Não foi possível gerar a imagem. Seus créditos foram devolvidos.",
                502,
            )
            raise AssertionError("unreachable") from exc  # `_fail` sempre levanta

        try:
            storage_path = storage.save(
                user_id=user.id,
                generation_id=generation.id,
                content=image.content,
                extension=image.extension,
            )
        except Exception as exc:
            logger.exception("Falha ao salvar imagem gerada")
            _fail(
                db,
                generation,
                reservation_key,
                "Não foi possível salvar a imagem. Seus créditos foram devolvidos.",
                502,
            )
            raise AssertionError("unreachable") from exc  # pragma: no cover

        generation.status = "completed"
        generation.storage_path = storage_path
        generation.provider = image.provider or provider.name
        db.commit()
        db.refresh(generation)

        CreditService.commit(db, reservation_key)
        return _to_out(generation, storage)

    @staticmethod
    def list(
        db: Session,
        *,
        user: User,
        storage: MediaStorage,
        limit: int = 50,
        offset: int = 0,
        generation_type: str | None = None,
    ) -> list[GenerationOut]:
        statement = select(Generation).where(Generation.user_id == user.id)
        if generation_type is not None:
            statement = statement.where(Generation.type == generation_type)
        statement = (
            statement.order_by(Generation.created_at.desc(), Generation.id.desc())
            .limit(limit)
            .offset(offset)
        )
        rows = db.execute(statement).scalars().all()
        return [_to_out(row, storage) for row in rows]

    @staticmethod
    def get(
        db: Session, *, user: User, storage: MediaStorage, generation_id: str
    ) -> GenerationOut:
        return _to_out(_find_owned(db, user, generation_id), storage)

    @staticmethod
    def delete(
        db: Session, *, user: User, storage: MediaStorage, generation_id: str
    ) -> None:
        """Remove da galeria. Não estorna crédito: a geração foi entregue."""
        row = _find_owned(db, user, generation_id)
        storage_path = row.storage_path
        db.delete(row)
        db.commit()
        if storage_path:
            try:
                storage.delete(storage_path)
            except Exception:  # arquivo ausente não invalida a remoção do registro
                logger.warning("Não foi possível remover o arquivo %s", storage_path)
