"""Verificação da assinatura de webhooks do fal.ai (D2).

O fal assina cada entrega com ED25519 e publica as chaves em um JWKS. Validamos
os quatro headers obrigatórios, a janela de tempo (±5 min por padrão) e o hash
do corpo cru — antes de qualquer registro em ``webhook_events``.

Referência: https://fal.ai/docs/documentation/model-apis/inference/webhooks
"""

from __future__ import annotations

import base64
import hashlib
import logging
import time
from collections.abc import Mapping

import httpx
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PublicKey

logger = logging.getLogger(__name__)

HEADER_REQUEST_ID = "x-fal-webhook-request-id"
HEADER_USER_ID = "x-fal-webhook-user-id"
HEADER_TIMESTAMP = "x-fal-webhook-timestamp"
HEADER_SIGNATURE = "x-fal-webhook-signature"
_REQUIRED = (HEADER_REQUEST_ID, HEADER_USER_ID, HEADER_TIMESTAMP, HEADER_SIGNATURE)

# Cache compartilhado por instância: o FastAPI cria um verificador por request,
# e sem isso cada webhook baixaria o JWKS novamente. Chaves antigas continuam
# válidas por um curto período se o provedor estiver temporariamente fora.
_JWKS_CACHE: dict[str, tuple[float, list[bytes]]] = {}


class FalWebhookVerifier:
    """Valida assinatura ED25519 de webhooks do fal.ai."""

    def __init__(
        self,
        *,
        jwks_url: str = "https://rest.fal.ai/.well-known/jwks.json",
        leeway_seconds: int = 300,
        cache_ttl_seconds: int = 3600,
        expected_user_id: str = "",
        transport: httpx.BaseTransport | None = None,
        pinned_keys: list[bytes] | None = None,
    ) -> None:
        self.jwks_url = jwks_url
        self.leeway_seconds = leeway_seconds
        # O fal recomenda no máximo 24h de cache; limitamos a 24h.
        self.cache_ttl_seconds = min(max(1, cache_ttl_seconds), 24 * 3600)
        self.expected_user_id = expected_user_id
        self._transport = transport
        self._pinned_keys = pinned_keys

    def _fetch_keys(self) -> list[bytes]:
        with httpx.Client(timeout=10.0, transport=self._transport) as client:
            response = client.get(self.jwks_url)
            response.raise_for_status()
            payload = response.json()
        keys: list[bytes] = []
        for item in payload.get("keys", []):
            encoded = item.get("x")
            if not isinstance(encoded, str):
                continue
            try:
                padded = encoded + "=" * (-len(encoded) % 4)
                keys.append(base64.urlsafe_b64decode(padded))
            except (ValueError, TypeError):
                continue
        return keys

    def _keys(self) -> list[bytes]:
        if self._pinned_keys is not None:
            return self._pinned_keys
        now = time.monotonic()
        cached = _JWKS_CACHE.get(self.jwks_url)
        if cached is not None and now - cached[0] < self.cache_ttl_seconds:
            return cached[1]
        try:
            keys = self._fetch_keys()
        except (httpx.HTTPError, ValueError) as exc:
            logger.warning("Falha ao buscar JWKS do fal: %s", type(exc).__name__)
            # Serve o último conjunto conhecido em vez de rejeitar entregas
            # legítimas durante uma indisponibilidade do endpoint de chaves.
            return cached[1] if cached is not None else []
        _JWKS_CACHE[self.jwks_url] = (now, keys)
        return keys

    def verify(self, headers: Mapping[str, str], body: bytes) -> bool:
        """Devolve ``True`` somente para uma entrega autêntica e recente."""
        normalized = {str(key).lower(): str(value) for key, value in headers.items()}
        if any(name not in normalized for name in _REQUIRED):
            return False

        request_id = normalized[HEADER_REQUEST_ID]
        user_id = normalized[HEADER_USER_ID]
        timestamp = normalized[HEADER_TIMESTAMP]
        signature_hex = normalized[HEADER_SIGNATURE]
        if not all([request_id, user_id, timestamp, signature_hex]):
            return False
        if self.expected_user_id and user_id != self.expected_user_id:
            return False

        try:
            sent_at = int(timestamp)
            signature = bytes.fromhex(signature_hex)
        except ValueError:
            return False
        if abs(time.time() - sent_at) > self.leeway_seconds:
            return False

        message = "\n".join(
            [request_id, user_id, timestamp, hashlib.sha256(body).hexdigest()]
        ).encode("utf-8")

        for key in self._keys():
            try:
                Ed25519PublicKey.from_public_bytes(key).verify(signature, message)
                return True
            except (InvalidSignature, ValueError):
                continue
        return False
