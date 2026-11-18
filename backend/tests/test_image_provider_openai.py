"""Testes do provedor oficial de imagem (D1 — OpenAI GPT Image).

Nenhuma chamada de rede real: o cliente httpx recebe um ``MockTransport``.
"""

from __future__ import annotations

import base64
import json

import httpx
import pytest
from fastapi import HTTPException

from app.core.config import settings
from app.generation.deps import get_image_provider
from app.generation.providers.base import ImageProviderTimeout, ImageProviderUnavailable
from app.generation.providers.mock import MockImageProvider
from app.generation.providers.openai import OpenAIImageProvider

_SLEEP_PATH = "app.generation.providers.openai.time.sleep"


def _png_b64() -> str:
    image = MockImageProvider().generate(prompt="x", style=None, size="1024x1024")
    return base64.b64encode(image.content).decode("ascii")


def _provider(handler, **kwargs) -> OpenAIImageProvider:
    """Cria o provedor com transporte mockado e sem retries por padrão."""
    options = {"retries": 0}
    options.update(kwargs)
    return OpenAIImageProvider(
        "sk-teste",
        transport=httpx.MockTransport(handler),
        **options,
    )


def _generate(provider: OpenAIImageProvider):
    return provider.generate(prompt="um gato", style="cyberpunk", size="1024x1024")


def test_openai_mounta_request_e_devolve_png() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["method"] = request.method
        seen["url"] = str(request.url)
        seen["authorization"] = request.headers.get("Authorization")
        seen["content_type"] = request.headers.get("Content-Type")
        seen["body"] = json.loads(request.content)
        return httpx.Response(200, json={"data": [{"b64_json": _png_b64()}]})

    image = _generate(_provider(handler))

    assert image.content.startswith(b"\x89PNG")
    assert image.media_type == "image/png"
    assert image.extension == "png"
    assert image.provider == "openai"
    assert seen == {
        "method": "POST",
        "url": "https://api.openai.com/v1/images/generations",
        "authorization": "Bearer sk-teste",
        "content_type": "application/json",
        "body": {
            "model": "gpt-image-1",
            "prompt": "um gato. Estilo: cyberpunk",
            "n": 1,
            "size": "1024x1024",
        },
    }


def test_openai_rejeita_tamanho_fora_do_contrato() -> None:
    provider = _provider(lambda _: pytest.fail("não deveria chamar a rede"))

    with pytest.raises(ImageProviderUnavailable, match="Tamanho não suportado"):
        provider.generate(prompt="x", style=None, size="512x512")


def test_openai_exige_chave_na_construcao() -> None:
    with pytest.raises(ImageProviderUnavailable, match="OPENAI_API_KEY"):
        OpenAIImageProvider("")


def test_openai_400_e_erro_do_usuario_sem_retry() -> None:
    calls: list[int] = []

    def handler(_: httpx.Request) -> httpx.Response:
        calls.append(1)
        return httpx.Response(400, json={"error": {"message": "prompt inválido"}})

    provider = _provider(handler, retries=2)

    with pytest.raises(ImageProviderUnavailable, match="Revise o prompt"):
        _generate(provider)
    assert len(calls) == 1


def test_openai_retrya_429_e_sucesso(monkeypatch: pytest.MonkeyPatch) -> None:
    sleeps: list[float] = []
    monkeypatch.setattr(_SLEEP_PATH, sleeps.append)
    calls: list[int] = []

    def handler(_: httpx.Request) -> httpx.Response:
        calls.append(1)
        if len(calls) == 1:
            return httpx.Response(429, json={"error": {"message": "rate limit"}})
        return httpx.Response(200, json={"data": [{"b64_json": _png_b64()}]})

    image = _generate(_provider(handler, retries=1))

    assert image.content.startswith(b"\x89PNG")
    assert len(calls) == 2
    assert sleeps == [0.5]


def test_openai_esgota_retries_em_erro_do_servidor(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(_SLEEP_PATH, lambda _: None)
    calls: list[int] = []

    def handler(_: httpx.Request) -> httpx.Response:
        calls.append(1)
        return httpx.Response(503, json={"error": {"message": "down"}})

    provider = _provider(handler, retries=2)

    with pytest.raises(ImageProviderUnavailable, match="indisponível"):
        _generate(provider)
    assert len(calls) == 3


def test_openai_timeout_vira_erro_especifico(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(_SLEEP_PATH, lambda _: None)

    def handler(_: httpx.Request) -> httpx.Response:
        raise httpx.TimeoutException("timeout")

    with pytest.raises(ImageProviderTimeout, match="demorou"):
        _generate(_provider(handler, retries=1))


def test_openai_falha_de_rede_e_mensagem_segura() -> None:
    def handler(_: httpx.Request) -> httpx.Response:
        raise httpx.ConnectError("offline")

    with pytest.raises(ImageProviderUnavailable, match="conectar ao provedor"):
        _generate(_provider(handler))


@pytest.mark.parametrize(
    "payload",
    [
        {},
        {"data": []},
        {"data": [{}]},
        {"data": [{"b64_json": "!!!base64-invalido!!!"}]},
    ],
)
def test_openai_resposta_inesperada_nao_vaza_detalhes(payload: dict) -> None:
    provider = _provider(lambda _: httpx.Response(200, json=payload))

    with pytest.raises(ImageProviderUnavailable, match="resposta inesperada"):
        _generate(provider)


def test_selecao_auto_usa_openai_quando_ha_chave(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "image_provider", "auto")
    monkeypatch.setattr(settings, "openai_api_key", "sk-teste")
    monkeypatch.setattr(settings, "app_env", "development")

    assert isinstance(get_image_provider(), OpenAIImageProvider)


def test_selecao_auto_usa_mock_sem_chave_em_desenvolvimento(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(settings, "image_provider", "auto")
    monkeypatch.setattr(settings, "openai_api_key", "")
    monkeypatch.setattr(settings, "app_env", "development")

    assert isinstance(get_image_provider(), MockImageProvider)


@pytest.mark.parametrize("mode", ["auto", "mock"])
def test_selecao_mock_e_bloqueada_em_producao(
    monkeypatch: pytest.MonkeyPatch, mode: str
) -> None:
    monkeypatch.setattr(settings, "image_provider", mode)
    monkeypatch.setattr(settings, "openai_api_key", "")
    monkeypatch.setattr(settings, "app_env", "production")

    with pytest.raises(HTTPException) as excinfo:
        get_image_provider()
    assert excinfo.value.status_code == 503


def test_selecao_openai_exige_chave(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "image_provider", "openai")
    monkeypatch.setattr(settings, "openai_api_key", "")
    monkeypatch.setattr(settings, "app_env", "development")

    with pytest.raises(HTTPException) as excinfo:
        get_image_provider()
    assert excinfo.value.status_code == 503


def test_selecao_rejeita_modo_desconhecido(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "image_provider", "outro")

    with pytest.raises(HTTPException) as excinfo:
        get_image_provider()
    assert excinfo.value.status_code == 503
