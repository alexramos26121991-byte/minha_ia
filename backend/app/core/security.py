"""Autenticação da API — verificação de ID token do Firebase (E2).

Em produção o token do cabeçalho Bearer é um ID token do Firebase validado
com ``firebase-admin``. Para desenvolvimento local sem credenciais, o modo
``auth_provider=dev`` aceita um token ``dev:<email>:<nonce>`` e deriva um UID
estável; esse modo é recusado quando ``app_env=production``.

Os testes substituem o verificador com ``set_verifier`` (ou via
``app.dependency_overrides[get_verifier]``), sem depender de Firebase.
"""

from __future__ import annotations

import json
import logging
from dataclasses import dataclass
from typing import Protocol
from uuid import NAMESPACE_URL, uuid5

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import settings

logger = logging.getLogger(__name__)

bearer_scheme = HTTPBearer(
    scheme_name="FirebaseBearer",
    description="ID token do Firebase no cabeçalho Authorization: Bearer <token>.",
    # O missing-credential é tratado em get_current_identity para responder 401
    # com mensagem em pt-BR, em vez do 403 padrão em inglês do HTTPBearer.
    auto_error=False,
)


@dataclass(frozen=True)
class VerifiedIdentity:
    """Identidade já validada pelo provedor de autenticação."""

    uid: str
    email: str | None = None
    display_name: str | None = None
    email_verified: bool = False


class AuthError(Exception):
    """Credencial inválida, expirada ou não verificável."""


class TokenVerifier(Protocol):
    """Contrato do verificador — facilita injetar um fake nos testes."""

    def verify(self, token: str) -> VerifiedIdentity: ...


class DevTokenVerifier:
    """Verificador somente para desenvolvimento (sem credenciais Firebase).

    Formato aceito: ``dev:<email>:<nonce>``. Qualquer outro token com ao menos
    10 caracteres gera uma identidade de desenvolvimento estável.
    """

    def verify(self, token: str) -> VerifiedIdentity:
        if not token or len(token) < 10:
            raise AuthError("Token de autenticação inválido.")

        email = "dev@minhaia.local"
        if token.startswith("dev:"):
            parts = token.split(":", 2)
            if len(parts) >= 2 and "@" in parts[1]:
                email = parts[1]

        uid = str(uuid5(NAMESPACE_URL, "minha-ia:dev:" + email))
        return VerifiedIdentity(
            uid=uid,
            email=email,
            display_name=email.split("@")[0],
            email_verified=True,
        )


class FirebaseTokenVerifier:
    """Valida ID tokens do Firebase com ``firebase-admin`` (import lazy)."""

    def __init__(self, project_id: str, service_account_json: str) -> None:
        if not service_account_json:
            raise RuntimeError(
                "auth_provider=firebase exige FIREBASE_SERVICE_ACCOUNT_JSON."
            )
        self._project_id = project_id
        self._service_account_json = service_account_json
        self._app = None
        self._ready = False

    def _ensure_app(self) -> None:
        if self._ready:
            return
        import firebase_admin
        from firebase_admin import credentials

        info = json.loads(self._service_account_json)
        cred = credentials.Certificate(info)
        if firebase_admin.get_apps():
            self._app = firebase_admin.get_app()
        else:
            options = {"projectId": self._project_id} if self._project_id else None
            self._app = firebase_admin.initialize_app(cred, options)
        self._ready = True

    def verify(self, token: str) -> VerifiedIdentity:
        from firebase_admin import auth as fb_auth

        self._ensure_app()
        try:
            decoded = fb_auth.verify_id_token(
                token, app=self._app, check_revoked=False
            )
        except Exception as exc:  # firebase lança diversos tipos de exceção
            raise AuthError("ID token do Firebase inválido ou expirado.") from exc

        return VerifiedIdentity(
            uid=str(decoded["uid"]),
            email=decoded.get("email"),
            display_name=decoded.get("name"),
            email_verified=bool(decoded.get("email_verified", False)),
        )


_verifier: TokenVerifier | None = None


def get_verifier() -> TokenVerifier:
    """Dependency FastAPI — constrói o verificador uma vez por processo."""
    global _verifier
    if _verifier is not None:
        return _verifier

    provider = settings.auth_provider.lower()
    if provider == "firebase":
        _verifier = FirebaseTokenVerifier(
            settings.firebase_project_id,
            settings.firebase_service_account_json,
        )
    elif provider == "dev":
        if settings.app_env.lower() == "production":
            raise RuntimeError("auth_provider=dev é proibido em production.")
        _verifier = DevTokenVerifier()
    else:
        raise RuntimeError(f"auth_provider desconhecido: {provider!r}")
    return _verifier


def set_verifier(verifier: TokenVerifier | None) -> None:
    """Injeta um verificador (testes). ``None`` restaura o padrão."""
    global _verifier
    _verifier = verifier


def get_current_identity(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    verifier: TokenVerifier = Depends(get_verifier),
) -> VerifiedIdentity:
    """Converte o Bearer em identidade validada ou responde 401."""
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credencial de autenticação ausente. Envie Authorization: Bearer <token>.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    try:
        return verifier.verify(credentials.credentials)
    except AuthError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except Exception as exc:  # configuração/provedor indisponível
        logger.exception("Falha inesperada ao verificar token")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Não foi possível validar a credencial.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


async def get_current_user_id(
    identity: VerifiedIdentity = Depends(get_current_identity),
) -> str:
    """UID estável do portador (usado pelas rotas protegidas já contratadas)."""
    return identity.uid
