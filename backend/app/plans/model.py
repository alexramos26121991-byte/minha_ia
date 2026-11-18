"""Modelo da tabela plans (seed dos 4 planos do PRD)."""

import uuid
from decimal import Decimal

from sqlalchemy import Boolean, Integer, Numeric, String
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Plan(Base):
    __tablename__ = "plans"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(80))
    monthly_credits: Mapped[int] = mapped_column(Integer)
    price_brl: Mapped[Decimal] = mapped_column(Numeric(10, 2))
    recurrence: Mapped[str] = mapped_column(String(16), default="monthly")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    sort_order: Mapped[int] = mapped_column(Integer, default=0)
