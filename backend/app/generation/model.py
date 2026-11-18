"""Modelo da tabela generations (tabelas criadas na migration da E3)."""

import uuid
from datetime import datetime

from sqlalchemy import JSON, DateTime, ForeignKey, Integer, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base
from app.credits.model import utcnow


class Generation(Base):
    __tablename__ = "generations"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    type: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), nullable=False, default="pending")
    provider: Mapped[str | None] = mapped_column(String(64), nullable=True)
    cost_credits: Mapped[int] = mapped_column(Integer, nullable=False)
    storage_path: Mapped[str | None] = mapped_column(String(512), nullable=True)
    idempotency_key: Mapped[str] = mapped_column(String(160), nullable=False, unique=True, index=True)
    prompt: Mapped[str | None] = mapped_column(Text, nullable=True)
    error_message: Mapped[str | None] = mapped_column(String(500), nullable=True)
    # Campos de jobs assíncronos (E5). `progress` é 0..100 e também vale para
    # imagens: 100 quando concluídas, 0 enquanto pendentes.
    request_payload: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    provider_request_id: Mapped[str | None] = mapped_column(String(160), nullable=True, index=True)
    provider_status_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    provider_response_url: Mapped[str | None] = mapped_column(String(512), nullable=True)
    progress: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=utcnow, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=utcnow,
        server_default=func.now(),
        onupdate=utcnow,
    )
