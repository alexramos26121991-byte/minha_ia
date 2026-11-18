"""Adiciona colunas de jobs assíncronos à tabela ``generations`` (E5).

Revision ID: 0004_video_generation_jobs
Revises: 0003_credits_engine
Create Date: 2026-11-17

O endpoint de vídeo responde 202 com o registro em ``queued``. O worker
precisava persistir o handle do provedor (``request_id`` + URLs), os parâmetros
originais e o progresso para que o app acompanhe o job por polling ou webhook.
Todas as colunas são aditivas e compatíveis com as linhas da E4.
"""

import sqlalchemy as sa
from alembic import op

revision = "0004_video_generation_jobs"
down_revision = "0003_credits_engine"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("generations", sa.Column("request_payload", sa.JSON(), nullable=True))
    op.add_column(
        "generations", sa.Column("provider_request_id", sa.String(length=160), nullable=True)
    )
    op.add_column(
        "generations", sa.Column("provider_status_url", sa.String(length=512), nullable=True)
    )
    op.add_column(
        "generations", sa.Column("provider_response_url", sa.String(length=512), nullable=True)
    )
    op.add_column(
        "generations",
        sa.Column(
            "progress",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("0"),
        ),
    )
    op.create_index(
        "ix_generations_provider_request_id",
        "generations",
        ["provider_request_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_generations_provider_request_id", table_name="generations")
    op.drop_column("generations", "progress")
    op.drop_column("generations", "provider_response_url")
    op.drop_column("generations", "provider_status_url")
    op.drop_column("generations", "provider_request_id")
    op.drop_column("generations", "request_payload")
