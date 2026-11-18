"""Provedor local de desenvolvimento — PNG sintético, sem rede e sem chave.

É o padrão quando ``OPENAI_API_KEY`` está vazio. Não é um gerador de imagens
real: serve para validar o fluxo ponta a ponta (débito, storage, galeria).
"""

from __future__ import annotations

import hashlib
import struct
import zlib

from app.generation.providers.base import GeneratedImage, ImageProvider


def _chunk(kind: bytes, data: bytes) -> bytes:
    checksum = zlib.crc32(kind + data) & 0xFFFFFFFF
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", checksum)


def _solid_png(rgb: tuple[int, int, int], width: int = 64, height: int = 64) -> bytes:
    """PNG RGBA-independente (RGB de 8 bits) gerado sem dependências externas."""
    scanline = b"\x00" + bytes(rgb) * width
    raw = scanline * height
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    return (
        b"\x89PNG\r\n\x1a\n"
        + _chunk(b"IHDR", header)
        + _chunk(b"IDAT", zlib.compress(raw, level=9))
        + _chunk(b"IEND", b"")
    )


class MockImageProvider(ImageProvider):
    name = "mock"

    def generate(self, *, prompt: str, style: str | None, size: str) -> GeneratedImage:
        del size  # o mock devolve sempre um quadrado pequeno
        seed = (prompt + (style or "")).encode("utf-8")
        digest = hashlib.sha256(seed).digest()
        # Cor estável por prompt, com um piso para não gerar imagem escura demais.
        rgb = tuple(96 + (byte % 128) for byte in digest[:3])
        return GeneratedImage(
            content=_solid_png(rgb),  # type: ignore[arg-type]
            media_type="image/png",
            provider=self.name,
            extension="png",
        )
