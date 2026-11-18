"""Adiciona display_name ao usuário (E2).

Revision ID: 0002_user_display_name
Revises: 0001_initial
Create Date: 2026-11-17
"""

import sqlalchemy as sa
from alembic import op

revision = "0002_user_display_name"
down_revision = "0001_initial"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column("display_name", sa.String(length=120), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("users", "display_name")
