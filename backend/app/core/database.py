"""Engine SQLAlchemy e sessão de banco (sync, psycopg 3)."""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.core.config import settings

engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,
    pool_size=5,
    max_overflow=10,
)

SessionLocal = sessionmaker(
    bind=engine,
    autoflush=False,
    expire_on_commit=False,
    class_=Session,
)


class Base(DeclarativeBase):
    """Metadata compartilhada por todos os modelos e pelo Alembic."""


def get_db() -> Generator[Session, None, None]:
    """Dependency FastAPI: abre e fecha a sessão por requisição."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
