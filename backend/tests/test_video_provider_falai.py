"""Testes do provedor oficial de vídeo (D2 — fal.ai + Kling).

Todas as chamadas usam ``httpx.MockTransport``: nenhuma chave real e nenhuma
rede são necessárias.
"""

from __future__ import annotations

import json

import httpx
import pytest

from app.generation.providers.falai import FalVideoProvider
from app.generation.providers.language import INSTRUCAO_PT_BR
from app.generation.providers.video_base import (
    VideoJobFailed,
    VideoOperation,
    VideoProviderUnavailable,
)

_SLEEP_PATH = "app.generation.providers.falai.time.sleep"
_REQUEST_ID = "019a1b2c-3d4e-7f80-9a1b-2c3d4e5f6a7b"
_STATUS_URL = "https://queue.fal.run/fal-ai/kling-video/requests/" + _REQUEST_ID + "/status"
_RESULT_URL = "https://queue.fal.run/fal-ai/kling-video/requests/" + _REQUEST_ID
_MEDIA_URL = "https://v3.fal.media/files/abc/render.mp4"
_MP4 = b"\x00\x00\x00\x18ftypmp42video-bytes"


def _submit_payload() -> dict:
    return {
        "request_id": _REQUEST_ID,
        "status_url": _STATUS_URL,
        "response_url": _RESULT_URL,
    }


def _provider(handler, **kwargs) -> FalVideoProvider:
    options = {"retries": 0}
    options.update(kwargs)
    return FalVideoProvider("key-teste", transport=httpx.MockTransport(handler), **options)


def _submit(provider: FalVideoProvider, **overrides):
    args = {
        "operation": VideoOperation.TEXT_TO_VIDEO,
        "prompt": "um dragão sobre a cidade",
        "image_url": None,
        "motion": None,
        "duration_seconds": 5,
        "resolution": "720p",
    }
    args.update(overrides)
    return provider.submit(**args)


def test_exige_chave_na_construcao() -> None:
    with pytest.raises(VideoProviderUnavailable, match="FAL_API_KEY"):
        FalVideoProvider("")


def test_submit_texto_monta_request_e_devolve_job() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        seen["auth"] = request.headers.get("Authorization")
        seen["body"] = json.loads(request.content)
        return httpx.Response(200, json=_submit_payload())

    job = _submit(_provider(handler))

    assert job.provider_request_id == _REQUEST_ID
    assert job.status_url == _STATUS_URL
    assert job.response_url == _RESULT_URL
    assert job.provider == "falai"
    assert seen["url"] == "https://queue.fal.run/fal-ai/kling-video/v3/pro/text-to-video"
    assert seen["auth"] == "Key key-teste"
    assert seen["body"] == {
        "prompt": f"um dragão sobre a cidade. {INSTRUCAO_PT_BR}",
        "duration": 5,
        "resolution": "720p",
    }


def test_submit_imagem_usa_modelo_de_imagem_e_movimento() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        seen["body"] = json.loads(request.content)
        return httpx.Response(200, json=_submit_payload())

    _submit(
        _provider(handler),
        operation=VideoOperation.IMAGE_TO_VIDEO,
        prompt=None,
        image_url="https://exemplo.test/foto.png",
        motion="zoom lento",
    )

    assert seen["url"] == "https://queue.fal.run/fal-ai/kling-video/v3/pro/image-to-video"
    assert seen["body"]["image_url"] == "https://exemplo.test/foto.png"
    assert seen["body"]["prompt"] == f"Movimento: zoom lento. {INSTRUCAO_PT_BR}"


def test_animar_foto_usa_o_mesmo_modelo_de_imagem() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["url"] = str(request.url)
        return httpx.Response(200, json=_submit_payload())

    _submit(
        _provider(handler),
        operation=VideoOperation.ANIMATE_PHOTO,
        image_url="https://exemplo.test/foto.png",
    )

    assert "image-to-video" in str(seen["url"])


def test_submit_inclui_webhook_quando_configurado() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen["webhook"] = request.url.params.get("fal_webhook")
        return httpx.Response(200, json=_submit_payload())

    provider = _provider(handler, webhook_url="https://api.test/webhooks/fal")
    _submit(provider)

    assert seen["webhook"] == "https://api.test/webhooks/fal"


def test_submit_rejeita_operacao_desconhecida() -> None:
    provider = _provider(lambda _: pytest.fail("não deveria chamar a rede"))

    with pytest.raises(VideoProviderUnavailable, match="não suportada"):
        _submit(provider, operation="outro")  # type: ignore[arg-type]


def test_submit_exige_imagem_nas_operacoes_de_imagem() -> None:
    provider = _provider(lambda _: pytest.fail("não deveria chamar a rede"))

    with pytest.raises(VideoProviderUnavailable, match="É necessária uma imagem"):
        _submit(provider, operation=VideoOperation.ANIMATE_PHOTO)


def test_submit_retrya_429_e_sucesso(monkeypatch: pytest.MonkeyPatch) -> None:
    sleeps: list[float] = []
    monkeypatch.setattr(_SLEEP_PATH, sleeps.append)
    calls: list[int] = []

    def handler(_: httpx.Request) -> httpx.Response:
        calls.append(1)
        if len(calls) == 1:
            return httpx.Response(429, json={"error": "rate limit"})
        return httpx.Response(200, json=_submit_payload())

    job = _submit(_provider(handler, retries=1))

    assert job.provider_request_id == _REQUEST_ID
    assert len(calls) == 2
    assert sleeps == [0.5]


def test_submit_400_para_imediatamente(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(_SLEEP_PATH, lambda _: pytest.fail("não deveria dormir"))
    calls: list[int] = []

    def handler(_: httpx.Request) -> httpx.Response:
        calls.append(1)
        return httpx.Response(400, json={"error": "bad request"})

    with pytest.raises(VideoProviderUnavailable, match="não aceitou"):
        _submit(_provider(handler, retries=2))
    assert len(calls) == 1


def test_submit_resposta_sem_request_id() -> None:
    provider = _provider(lambda _: httpx.Response(200, json={"status": "IN_QUEUE"}))

    with pytest.raises(VideoProviderUnavailable, match="id de job"):
        _submit(provider)


@pytest.mark.parametrize(
    ("status_code", "status"),
    [(200, "IN_QUEUE"), (202, "IN_PROGRESS"), (200, "COMPLETED")],
)
def test_status_mapeia_estados(status_code: int, status: str) -> None:
    provider = _provider(lambda _: httpx.Response(status_code, json={"status": status}))
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    assert provider.status(job) == status


def test_status_404_vira_erro_seguro() -> None:
    provider = _provider(lambda _: httpx.Response(404, json={}))
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    with pytest.raises(VideoProviderUnavailable, match="não foi encontrado"):
        provider.status(job)


def test_status_inesperado_e_recusado() -> None:
    provider = _provider(lambda _: httpx.Response(200, json={"status": "EXPLODED"}))
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    with pytest.raises(VideoProviderUnavailable, match="inesperado"):
        provider.status(job)


def test_result_baixa_video_e_valida_tipo() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "v3.fal.media":
            assert request.headers.get("Authorization") == "Key key-teste"
            return httpx.Response(
                200, content=_MP4, headers={"content-type": "video/mp4; charset=utf-8"}
            )
        return httpx.Response(200, json={"video": {"url": _MEDIA_URL}})

    provider = _provider(handler)
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    video = provider.result(job)

    assert video.content == _MP4
    assert video.media_type == "video/mp4"
    assert video.extension == "mp4"
    assert video.provider == "falai"


def test_result_aceita_videos_lista_e_url_string() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "v3.fal.media":
            return httpx.Response(200, content=_MP4, headers={"content-type": "video/mp4"})
        return httpx.Response(200, json={"videos": [_MEDIA_URL]})

    video = _provider(handler).result(
        _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))
    )
    assert video.content == _MP4


def test_result_rejeita_host_fora_do_fal_media() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "evil.example":
            return httpx.Response(200, content=_MP4)
        return httpx.Response(200, json={"video": "https://evil.example/video.mp4"})

    provider = _provider(handler)
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    with pytest.raises(VideoProviderUnavailable, match="mídia inválida"):
        provider.result(job)


def test_result_recusa_job_com_erro() -> None:
    provider = _provider(lambda _: httpx.Response(200, json={"error": "moderation"}))
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    with pytest.raises(VideoJobFailed, match="não conseguiu gerar"):
        provider.result(job)


def test_result_recusa_conteudo_que_nao_e_mp4() -> None:
    """Um HTML de erro com content-type video/mp4 não pode virar mídia final."""

    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "v3.fal.media":
            return httpx.Response(
                200,
                content=b"<html>erro temporario</html>",
                headers={"content-type": "video/mp4"},
            )
        return httpx.Response(200, json={"video": _MEDIA_URL})

    provider = _provider(handler)
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    with pytest.raises(VideoProviderUnavailable, match="MP4 válido"):
        provider.result(job)


def test_result_recusa_video_vazio() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "v3.fal.media":
            return httpx.Response(200, content=b"")
        return httpx.Response(200, json={"video": _MEDIA_URL})

    provider = _provider(handler)
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    with pytest.raises(VideoProviderUnavailable, match="vazio"):
        provider.result(job)


def test_result_limita_tamanho_do_download() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.host == "v3.fal.media":
            return httpx.Response(200, content=b"12345678")
        return httpx.Response(200, json={"video": _MEDIA_URL})

    provider = _provider(handler, max_video_bytes=4)
    job = _submit(_provider(lambda _: httpx.Response(200, json=_submit_payload())))

    with pytest.raises(VideoProviderUnavailable, match="tamanho permitido"):
        provider.result(job)
