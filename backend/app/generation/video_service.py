"""Serviço de geração de vídeo e animação de foto (E5).

Fluxo:

1. ``enqueue`` valida o flag, o custo em ``cost_config`` e a URL de origem,
   reserva créditos com chave prefixada, grava a geração como ``queued`` e
   dispara o job. A resposta é 202 — o cliente não espera o vídeo.
2. ``process`` é o worker: ``submit`` → guarda o handle do provedor → faz
   polling de ``status`` → ``result`` → storage → ``commit``.
3. ``finalize_from_webhook`` é o caminho preferencial: o evento assinado só
   confirma que o job terminou; o vídeo é baixado e confirmado uma única vez.

Tanto o polling quanto o webhook convergem para ``_finalize_ready``, que é
idempotente por status e pelas chaves de reserva do ledger. Qualquer falha
estorna e marca ``failed`` com mensagem segura em pt-BR.
"""

from __future__ import annotations

import ipaddress
import logging
import socket
import time
import uuid
from collections.abc import Callable
from urllib.parse import urlparse

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.credits.service import CostNotConfigured, CreditService, InsufficientCredits
from app.generation.deps import get_media_storage, get_video_provider
from app.generation.model import Generation
from app.generation.providers.video_base import (
    VideoJob,
    VideoJobFailed,
    VideoOperation,
    VideoProvider,
    VideoProviderError,
)
from app.generation.schemas import AnimatePhotoIn, GenerationOut, VideoGenerationIn
from app.generation.service import _to_out
from app.generation.storage import MediaStorage
from app.users.model import User

logger = logging.getLogger(__name__)

JobDispatcher = Callable[[str], None]
WebhookDispatcher = Callable[[str, dict], None]

_TERMINAL = frozenset({"completed", "failed"})
_OPERATION_TYPE = {
    VideoOperation.TEXT_TO_VIDEO: "video",
    VideoOperation.IMAGE_TO_VIDEO: "animate_photo",
    VideoOperation.ANIMATE_PHOTO: "animate_photo",
}
_OPERATION_COST = {
    VideoOperation.TEXT_TO_VIDEO: "video",
    VideoOperation.IMAGE_TO_VIDEO: "animate_photo",
    VideoOperation.ANIMATE_PHOTO: "animate_photo",
}
_LOCAL_HOSTS = frozenset({"localhost", "127.0.0.1", "::1"})


def _unavailable(detail: str) -> HTTPException:
    return HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail=detail)


def _resolve_host(host: str) -> list[str]:
    """Resolve o host para checar para onde a URL aponta (injetável em testes)."""
    try:
        infos = socket.getaddrinfo(host, None, type=socket.SOCK_STREAM)
    except socket.gaierror as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A imagem de origem deve ser uma URL pública válida.",
        ) from exc
    return [str(info[4][0]) for info in infos]


def _is_public_address(address: str) -> bool:
    """Rejeita intervalos privados, loopback, link-local e metadados de cloud."""
    try:
        parsed = ipaddress.ip_address(address.split("%", 1)[0])
    except ValueError:
        return False
    return not (
        parsed.is_private
        or parsed.is_loopback
        or parsed.is_link_local
        or parsed.is_multicast
        or parsed.is_reserved
        or parsed.is_unspecified
    )


def _validate_source_image_url(raw: str) -> str:
    """Valida a imagem de origem antes de enviá-la ao provedor remoto (F0).

    Além do esquema e de credenciais embutidas, bloqueia hosts locais e
    endereços que resolvem para redes internas — inclusive o endpoint de
    metadados de cloud (169.254.169.254). A resolução é feita aqui, e não no
    download, porque quem busca a imagem é o provedor, não o nosso servidor.
    """
    parsed = urlparse(raw)
    host = (parsed.hostname or "").lower()
    if parsed.scheme not in {"http", "https"} or not host or parsed.username or parsed.password:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A imagem de origem deve ser uma URL pública válida.",
        )
    try:
        port = parsed.port
    except ValueError:
        port = None
    if port not in (None, 80, 443):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A imagem de origem deve usar uma porta HTTP padrão.",
        )
    if parsed.scheme == "http":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A imagem de origem precisa usar HTTPS.",
        )
    if host in _LOCAL_HOSTS or host.endswith(".localhost"):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Envie a imagem pelo upload do servidor antes de animar.",
        )

    literal = host.strip("[]")
    try:
        ipaddress.ip_address(literal)
        addresses = [literal]
    except ValueError:
        addresses = _resolve_host(host)
    if not addresses or not all(_is_public_address(address) for address in addresses):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A imagem de origem aponta para um endereço não público.",
        )
    return raw


def _find_job(db: Session, generation_id: str) -> Generation:
    try:
        parsed = uuid.UUID(generation_id)
    except (ValueError, AttributeError):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Geração não encontrada.")
    row = db.get(Generation, parsed)
    if row is None or row.type not in _OPERATION_TYPE.values():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Geração não encontrada.")
    return row


def _job_from_row(row: Generation, provider: str = "falai") -> VideoJob:
    return VideoJob(
        provider_request_id=row.provider_request_id or "",
        status_url=row.provider_status_url or "",
        response_url=row.provider_response_url or "",
        provider=row.provider or provider,
    )


def _operation_from_payload(row: Generation) -> VideoOperation:
    raw = (row.request_payload or {}).get("operation", "text_to_video")
    try:
        return VideoOperation(raw)
    except ValueError:
        return VideoOperation.TEXT_TO_VIDEO


class VideoGenerationService:
    """Enfileiramento, worker e finalização de vídeos (uma transação por ação)."""

    @staticmethod
    def enqueue(
        db: Session,
        *,
        user: User,
        operation: VideoOperation,
        payload: VideoGenerationIn | AnimatePhotoIn,
        provider: VideoProvider,
        storage: MediaStorage,
        dispatcher: JobDispatcher,
    ) -> GenerationOut:
        if not settings.video_generation_enabled:
            raise _unavailable(
                "A geração de vídeos está temporariamente indisponível. Tente novamente em instantes."
            )

        generation_type = _OPERATION_TYPE[operation]
        cost_key = _OPERATION_COST[operation]
        source_url: str | None = None
        if operation in (VideoOperation.IMAGE_TO_VIDEO, VideoOperation.ANIMATE_PHOTO):
            source_url = _validate_source_image_url(str(payload.image_url))  # type: ignore[attr-defined]

        reservation_key = f"{cost_key}:{user.id}:{payload.idempotency_key}"
        existing = db.execute(
            select(Generation).where(Generation.idempotency_key == reservation_key)
        ).scalar_one_or_none()
        if existing is not None:
            logger.info("Geração de vídeo idempotente %s", reservation_key)
            return _to_out(existing, storage)

        try:
            cost = CreditService.get_cost_credits(db, cost_key)
        except CostNotConfigured as exc:
            raise _unavailable("Os custos de geração ainda não foram configurados.") from exc

        try:
            CreditService.reserve(
                db,
                user.id,
                cost,
                reservation_key,
                reason=f"reserva para gerar {generation_type}",
            )
        except InsufficientCredits as exc:
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED, detail=str(exc)
            ) from exc

        request_payload: dict[str, object] = {"operation": operation.value}
        prompt: str | None = None
        if isinstance(payload, VideoGenerationIn):
            prompt = payload.prompt
            request_payload.update(
                {
                    "prompt": payload.prompt,
                    "duration_seconds": payload.duration_seconds,
                    "resolution": payload.resolution,
                }
            )
        else:
            request_payload.update({"image_url": source_url, "motion": payload.motion})

        generation = Generation(
            id=uuid.uuid4(),
            user_id=user.id,
            type=generation_type,
            status="queued",
            provider=provider.name,
            cost_credits=cost,
            idempotency_key=reservation_key,
            prompt=prompt,
            progress=0,
            request_payload=request_payload,
        )
        db.add(generation)
        db.commit()
        db.refresh(generation)

        try:
            dispatcher(str(generation.id))
        except Exception as exc:
            logger.exception("Falha ao enfileirar o job %s", generation.id)
            VideoGenerationService._fail_job(
                db,
                generation,
                "Não foi possível iniciar a geração. Seus créditos foram devolvidos.",
            )
            raise _unavailable("Não foi possível iniciar a geração. Tente novamente.") from exc

        return _to_out(generation, storage)

    @staticmethod
    def process(
        db: Session,
        *,
        generation_id: str,
        provider: VideoProvider | None = None,
        storage: MediaStorage | None = None,
    ) -> GenerationOut:
        """Worker de polling. Seguro para reexecução: estados terminais são no-op."""
        row = _find_job(db, generation_id)
        # O webhook pode ter finalizado o job entre o enfileiramento e aqui.
        db.refresh(row)
        if row.status in _TERMINAL:
            logger.info("Job %s já está %s — ignorando reexecução", row.id, row.status)
            return _to_out(row, storage or get_media_storage())

        active_provider = provider or get_video_provider()
        active_storage = storage or get_media_storage()
        data = row.request_payload or {}

        try:
            row.status = "processing"
            row.provider = active_provider.name
            db.commit()

            job = active_provider.submit(
                operation=_operation_from_payload(row),
                prompt=data.get("prompt"),
                image_url=data.get("image_url"),
                motion=data.get("motion"),
                duration_seconds=int(data.get("duration_seconds", 5)),
                resolution=str(data.get("resolution", "720p")),
            )
            row.provider_request_id = job.provider_request_id[:160]
            row.provider_status_url = job.status_url[:512]
            row.provider_response_url = job.response_url[:512]
            row.progress = 10
            db.commit()

            attempts = max(1, settings.video_poll_attempts)
            interval = max(0.0, settings.video_poll_interval_seconds)
            completed = False
            for attempt in range(attempts):
                # Se o webhook já confirmou, encerramos o polling sem baixar
                # duas vezes nem sobrescrever um estado terminal.
                db.refresh(row)
                if row.status in _TERMINAL:
                    return _to_out(row, active_storage)
                state = active_provider.status(job)
                if state == "COMPLETED":
                    completed = True
                    break
                row.progress = min(90, 10 + int(80 * (attempt + 1) / attempts))
                db.commit()
                if attempt + 1 < attempts and interval:
                    time.sleep(interval)
            if not completed:
                raise VideoProviderError(
                    "A geração do vídeo demorou mais do que o esperado. "
                    "Seus créditos foram devolvidos — tente novamente."
                )

            return VideoGenerationService._finalize_ready(
                db, row=row, job=job, provider=active_provider, storage=active_storage
            )
        except VideoJobFailed as exc:
            return VideoGenerationService._fail_job(db, row, str(exc))
        except VideoProviderError as exc:
            return VideoGenerationService._fail_job(db, row, str(exc))
        except Exception as exc:
            logger.exception("Falha inesperada no worker de vídeo %s", row.id)
            return VideoGenerationService._fail_job(
                db,
                row,
                "Não foi possível gerar o vídeo. Seus créditos foram devolvidos.",
            )

    @staticmethod
    def finalize_from_webhook(
        db: Session,
        *,
        request_id: str,
        payload: dict,
        provider: VideoProvider | None = None,
        storage: MediaStorage | None = None,
    ) -> bool:
        """Confirma um job concluído. Devolve ``True`` quando finalizou algo."""
        row = db.execute(
            select(Generation).where(Generation.provider_request_id == request_id)
        ).scalar_one_or_none()
        if row is None:
            logger.warning("Webhook de vídeo para job desconhecido: %s", request_id)
            return False
        if row.status in _TERMINAL:
            logger.info("Webhook duplicado para o job %s", row.id)
            return False

        status_value = str(payload.get("status", "")).upper()
        if status_value in {"FAILED", "ERROR", "CANCELLED"} or payload.get("error"):
            VideoGenerationService._fail_job(
                db, row, "O provedor não conseguiu gerar o vídeo. Seus créditos foram devolvidos."
            )
            return True
        if status_value not in {"COMPLETED", "OK", ""}:
            # IN_QUEUE/IN_PROGRESS: o polling continua; nada a finalizar ainda.
            return False

        active_provider = provider or get_video_provider()
        active_storage = storage or get_media_storage()
        job = _job_from_row(row, active_provider.name)
        try:
            VideoGenerationService._finalize_ready(
                db, row=row, job=job, provider=active_provider, storage=active_storage
            )
            return True
        except VideoJobFailed as exc:
            VideoGenerationService._fail_job(db, row, str(exc))
            return True
        except VideoProviderError as exc:
            VideoGenerationService._fail_job(db, row, str(exc))
            return True
        except Exception:
            logger.exception("Falha ao finalizar webhook do job %s", row.id)
            VideoGenerationService._fail_job(
                db, row, "Não foi possível salvar o vídeo. Seus créditos foram devolvidos."
            )
            return True

    @staticmethod
    def _finalize_ready(
        db: Session,
        *,
        row: Generation,
        job: VideoJob,
        provider: VideoProvider,
        storage: MediaStorage,
    ) -> GenerationOut:
        """Baixa, salva e confirma créditos — ponto único de sucesso."""
        # Última checagem no banco: polling e webhook podem correr em paralelo.
        db.refresh(row)
        if row.status == "completed":
            return _to_out(row, storage)

        video = provider.result(job)
        storage_path = storage.save(
            user_id=row.user_id,
            generation_id=row.id,
            content=video.content,
            extension=video.extension or "mp4",
        )
        row.storage_path = storage_path
        row.provider = video.provider or provider.name
        row.progress = 100
        row.status = "completed"
        row.error_message = None
        db.commit()
        db.refresh(row)

        CreditService.commit(db, row.idempotency_key)
        return _to_out(row, storage)

    @staticmethod
    def _fail_job(db: Session, row: Generation, message: str) -> GenerationOut:
        """Estorna e marca falha. Idempotente mesmo se chamado duas vezes."""
        if row.status in _TERMINAL:
            return _to_out(row, get_media_storage())

        try:
            CreditService.refund(db, row.idempotency_key, reason=f"estorno por falha: {message[:120]}")
        except Exception:  # nunca esconde a falha original
            logger.exception("Falha ao estornar a reserva %s", row.idempotency_key)

        row.status = "failed"
        row.progress = 0
        row.error_message = message[:500]
        db.commit()
        db.refresh(row)
        return _to_out(row, get_media_storage())
