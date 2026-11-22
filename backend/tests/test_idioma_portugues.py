"""Testes da frente de idioma português do Brasil (pt-BR)."""

from __future__ import annotations

from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient
from pydantic import BaseModel, Field

from app.core.errors import instalar_handlers
from app.core.security import VerifiedIdentity, get_current_identity, get_verifier
from app.generation.providers.language import (
    INSTRUCAO_PT_BR,
    compor_prompt_imagem,
    compor_prompt_video,
)
from app.main import app as app_principal


class _Entrada(BaseModel):
    fcm_token: str = Field(max_length=512)


def _app_minimal() -> FastAPI:
    aplicacao = FastAPI()
    instalar_handlers(aplicacao)

    @aplicacao.post("/teste")
    def rota(payload: _Entrada) -> dict:
        return {"ok": True}

    return aplicacao


def test_prompt_de_imagem_tem_idioma_explicito() -> None:
    prompt = compor_prompt_imagem("um gato", "cyberpunk")

    assert prompt.startswith("um gato. Estilo: cyberpunk.")
    assert INSTRUCAO_PT_BR in prompt


def test_prompt_de_video_tem_idioma_explicito() -> None:
    prompt = compor_prompt_video("uma cidade", "zoom lento")

    assert prompt.startswith("uma cidade. Movimento: zoom lento.")
    assert INSTRUCAO_PT_BR in prompt


def test_prompt_de_video_sem_texto_continua_vazio() -> None:
    assert compor_prompt_video(None, None) == ""


def test_erro_de_validacao_usa_mensagem_em_portugues() -> None:
    client = TestClient(_app_minimal())

    resposta = client.post("/teste", json={"fcm_token": "a" * 513})

    assert resposta.status_code == 422
    erro = resposta.json()["detail"][0]
    assert erro["type"] == "string_too_long"
    assert erro["msg"] == "Deve ter no máximo 512 caracteres."
    assert erro["loc"] == ["body", "fcm_token"]


def test_erro_de_validacao_para_campo_obrigatorio() -> None:
    client = TestClient(_app_minimal())

    resposta = client.post("/teste", json={})

    assert resposta.status_code == 422
    assert resposta.json()["detail"][0]["msg"] == "Campo obrigatório."


def test_erro_404_esta_em_portugues() -> None:
    client = TestClient(_app_minimal())

    resposta = client.get("/rota-inexistente")

    assert resposta.status_code == 404
    assert resposta.json() == {"detail": "Recurso não encontrado."}


def test_bearer_ausente_retorna_401_em_portugues() -> None:
    aplicacao = FastAPI()

    class VerificadorFixo:
        def verify(self, token: str) -> VerifiedIdentity:
            return VerifiedIdentity(uid="teste", email="teste@minhaia.local")

    aplicacao.dependency_overrides[get_verifier] = lambda: VerificadorFixo()

    @aplicacao.get("/protegido")
    def rota(identidade: VerifiedIdentity = Depends(get_current_identity)) -> dict:
        return {"uid": identidade.uid}

    resposta = TestClient(aplicacao).get("/protegido")

    assert resposta.status_code == 401
    assert resposta.json()["detail"].startswith("Credencial de autenticação ausente.")
    assert resposta.headers["www-authenticate"] == "Bearer"


def test_descricoes_do_openapi_estao_em_portugues() -> None:
    schema = app_principal.openapi()
    descricoes = {
        resposta.get("description")
        for metodo in schema["paths"].values()
        for operacao in metodo.values()
        if isinstance(operacao, dict)
        for resposta in operacao.get("responses", {}).values()
    }

    assert "Validation Error" not in descricoes
    assert "Successful Response" not in descricoes
    assert "Requisição inválida (validação falhou)." in descricoes
