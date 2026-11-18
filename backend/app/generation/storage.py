"""Armazenamento de mídia gerada.

A implementação padrão é local (``backend/media``, servido em ``/media``) para
que o fluxo funcione sem provisionamento do GCS. A troca para Cloud Storage
será feita apenas na dependency, sem alterar rotas ou serviço.
"""

from __future__ import annotations

import uuid
from abc import ABC, abstractmethod
from pathlib import Path, PurePosixPath

_ALLOWED_EXTENSIONS = frozenset({"png", "jpg", "jpeg", "webp"})


class MediaStorage(ABC):
    @abstractmethod
    def save(
        self,
        *,
        user_id: uuid.UUID,
        generation_id: uuid.UUID,
        content: bytes,
        extension: str,
    ) -> str:
        """Persiste o arquivo e devolve o caminho relativo guardado no banco."""

    @abstractmethod
    def url_for(self, storage_path: str) -> str:
        """Converte o caminho interno em URL pública para o cliente."""

    @abstractmethod
    def delete(self, storage_path: str) -> None:
        """Remove o arquivo; ausência não é erro."""


def _safe_relative(storage_path: str) -> Path:
    """Impede path traversal antes de qualquer operação de arquivo."""
    candidate = PurePosixPath(storage_path.replace("\\", "/").lstrip("/"))
    if candidate.is_absolute() or ".." in candidate.parts or not candidate.parts:
        raise ValueError("Caminho de mídia inválido.")
    return Path(*candidate.parts)


class LocalMediaStorage(MediaStorage):
    """Storage local para desenvolvimento e testes."""

    def __init__(self, root: str | Path, url_prefix: str = "/media") -> None:
        self.root = Path(root).resolve()
        self.root.mkdir(parents=True, exist_ok=True)
        self.url_prefix = "/" + url_prefix.strip("/")

    def save(
        self,
        *,
        user_id: uuid.UUID,
        generation_id: uuid.UUID,
        content: bytes,
        extension: str,
    ) -> str:
        ext = extension.lower().lstrip(".")
        if ext not in _ALLOWED_EXTENSIONS:
            raise ValueError(f"Extensão de imagem não suportada: {extension!r}")
        relative = Path(str(user_id)) / f"{generation_id}.{ext}"
        destination = self.root / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(content)
        return relative.as_posix()

    def url_for(self, storage_path: str) -> str:
        return f"{self.url_prefix}/{_safe_relative(storage_path).as_posix()}"

    def delete(self, storage_path: str) -> None:
        destination = (self.root / _safe_relative(storage_path)).resolve()
        if not destination.is_relative_to(self.root):
            raise ValueError("Caminho de mídia inválido.")
        destination.unlink(missing_ok=True)
        parent = destination.parent
        if parent != self.root and parent.is_dir() and not any(parent.iterdir()):
            parent.rmdir()
