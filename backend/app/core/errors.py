"""Erros HTTP compartilhados."""

from fastapi import HTTPException, status


def not_implemented(stage: str) -> HTTPException:
    """Marca endpoints cuja implementação pertence a uma etapa posterior.

    As assinaturas e os schemas já fazem parte do contrato E1c; apenas a
    lógica de negócio fica para a etapa indicada.
    """
    return HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail=f"Endpoint contratado na E1c; implementação prevista na {stage}.",
    )
