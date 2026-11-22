"""Handlers de erro com mensagens em português do Brasil.

A estrutura das respostas permanece a do contrato (``detail`` como lista de
``ValidationError``), apenas os textos gerados automaticamente pelo FastAPI,
Pydantic e Starlette são traduzidos.
"""

from __future__ import annotations

from fastapi import FastAPI, HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

# Mensagens padrão que o Starlette produz em inglês. Qualquer `detail` customizado
# (já escrito em pt-BR nas rotas) passa sem alteração.
_DETALHES_PADRAO = {
    "Bad Request": "Requisição inválida.",
    "Unauthorized": "Não autenticado.",
    "Forbidden": "Acesso negado.",
    "Not Found": "Recurso não encontrado.",
    "Method Not Allowed": "Método não permitido.",
    "Internal Server Error": "Erro interno do servidor.",
}

# Mensagens do Pydantic v2 indexadas pelo código de erro. Os valores com
# placeholder usam o `ctx` original do erro, sem expor detalhes de implementação.
_MENSAGENS_VALIDACAO = {
    "missing": "Campo obrigatório.",
    "string_type": "Deve ser um texto.",
    "string_too_short": "Deve ter pelo menos {min_length} caracteres.",
    "string_too_long": "Deve ter no máximo {max_length} caracteres.",
    "string_pattern_mismatch": "Formato inválido.",
    "int_type": "Deve ser um número inteiro.",
    "int_parsing": "Deve ser um número inteiro.",
    "float_type": "Deve ser um número.",
    "float_parsing": "Deve ser um número.",
    "bool_type": "Deve ser verdadeiro ou falso.",
    "bool_parsing": "Deve ser verdadeiro ou falso.",
    "list_type": "Deve ser uma lista.",
    "dict_type": "Deve ser um objeto.",
    "none_required": "Não é permitido valor vazio.",
    "extra_forbidden": "Campo não permitido.",
    "enum": "Valor não permitido.",
    "json_invalid": "JSON inválido.",
    "json_type": "JSON inválido.",
    "greater_than_equal": "Deve ser maior ou igual a {ge}.",
    "greater_than": "Deve ser maior que {gt}.",
    "less_than_equal": "Deve ser menor ou igual a {le}.",
    "less_than": "Deve ser menor que {lt}.",
    "too_short": "Deve ter pelo menos {min_length} itens.",
    "too_long": "Deve ter no máximo {max_length} itens.",
    "value_error": "Valor inválido.",
    "assertion_error": "Valor inválido.",
}

_MARCADORES_PT = (
    "ão", "ã", "ç", "é", "ê", "í", "ó", "ô", "ú", "á", "à",
    "não", "deve", "inválid", "obrigat", "permitid", "máxim", "mínim",
)


def not_implemented(stage: str) -> HTTPException:
    """Marca endpoints cuja implementação pertence a uma etapa posterior.

    As assinaturas e os schemas já fazem parte do contrato E1c; apenas a
    lógica de negócio fica para a etapa indicada.
    """
    return HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail=f"Endpoint contratado na E1c; implementação prevista na {stage}.",
    )


def _traduzir_mensagem(erro: dict) -> str:
    """Traduz um erro do Pydantic preservando o código e o contexto originais."""
    codigo = str(erro.get("type", ""))
    modelo = _MENSAGENS_VALIDACAO.get(codigo)
    if modelo is not None:
        ctx = erro.get("ctx") or {}
        if isinstance(ctx, dict):
            try:
                return modelo.format(**ctx)
            except (KeyError, IndexError, ValueError):
                return modelo
        return modelo

    mensagem = str(erro.get("msg", ""))
    # Validadores de domínio já escrevem em pt-BR: não sobrescreva essa mensagem.
    if any(marcador in mensagem.lower() for marcador in _MARCADORES_PT):
        return mensagem
    return "Valor inválido para este campo."


async def tratar_validacao(request: Request, exc: RequestValidationError) -> JSONResponse:
    """Converte a lista de erros do Pydantic para mensagens em pt-BR."""
    detalhes = []
    for erro in exc.errors():
        item = dict(erro)
        item["msg"] = _traduzir_mensagem(erro)
        detalhes.append(item)
    return JSONResponse(status_code=422, content={"detail": detalhes})


async def tratar_http(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    """Traduz apenas os detalhes genéricos emitidos pelo Starlette."""
    detail = _DETALHES_PADRAO.get(str(exc.detail), exc.detail)
    headers = dict(exc.headers or {})
    if exc.status_code == 401:
        headers.setdefault("WWW-Authenticate", "Bearer")
    return JSONResponse(status_code=exc.status_code, content={"detail": detail}, headers=headers)


def instalar_handlers(app: FastAPI) -> None:
    """Registra os handlers no ponto de entrada da aplicação."""
    app.add_exception_handler(RequestValidationError, tratar_validacao)
    app.add_exception_handler(StarletteHTTPException, tratar_http)
