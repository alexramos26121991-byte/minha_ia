"""Autenticação — placeholder substituído na E2 por verificação Firebase.

O contrato já expõe o esquema Bearer (JWT do Firebase). Nesta etapa apenas
validamos a presença do token para manter as rotas protegidas documentadas;
a E2 troca o corpo pela validação real com firebase-admin.
"""

from uuid import NAMESPACE_URL, uuid5

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

bearer_scheme = HTTPBearer(
    scheme_name="FirebaseBearer",
    description="ID token do Firebase no cabeçalho Authorization: Bearer <token>.",
    auto_error=True,
)


async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
) -> str:
    """Retorna um identificador estável do portador do token.

    TODO(E2): verificar `credentials.credentials` com firebase-admin e
    retornar o `firebase_uid` real, criando o usuário na primeira chamada.
    """
    token = credentials.credentials
    if not token or len(token) < 10:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token de autenticação inválido.",
        )
    return str(uuid5(NAMESPACE_URL, token))
