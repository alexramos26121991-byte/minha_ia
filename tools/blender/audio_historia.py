"""Audio completo de "A historia da estrela": narração, trilha, efeitos e legendas.

Tudo é produzido localmente e sem custo:
- narração/falas: edge-tts com vozes pt-BR (serviço gratuito do Microsoft Edge);
- trilha e efeitos: sintetizados com numpy + ondas PCM;
- legendas: ASS com a fonte Arial do Windows;
- mixagem e muxação: ffmpeg.

Uso:
    python tools/blender/audio_historia.py
"""

from __future__ import annotations

import asyncio
import math
import os
import subprocess
import wave

import edge_tts
import numpy as np

BASE = os.path.dirname(os.path.abspath(__file__))
OUTPUT = os.path.join(BASE, "output")
os.makedirs(OUTPUT, exist_ok=True)

VIDEO = os.path.join(OUTPUT, "historia_da_estrela_video.mp4")
FINAL = os.path.join(OUTPUT, "historia_da_estrela_final.mp4")
TEMP = os.path.join(OUTPUT, "audio_temp")
os.makedirs(TEMP, exist_ok=True)

FPS = 48000
DURACAO = 20.0

NARRADOR = "pt-BR-AntonioNeural"
MENINA = "pt-BR-FranciscaNeural"
VOZ_FINAL = "pt-BR-ThalitaMultilingualNeural"

# (id, voz, texto, inicio, fim, taxa edge-tts)
TRECHOS = [
    ("n1", NARRADOR, "Um menino encontrou uma estrela caída do céu.", 0.40, 3.10, "+5%"),
    ("n2", NARRADOR, "Ele se surpreendeu!", 3.20, 5.00, "+0%"),
    ("n3", NARRADOR, "Então chegou uma menina.", 5.10, 7.10, "+0%"),
    ("f1", MENINA, "Será que ela está perdida?", 7.20, 9.40, "+0%"),
    ("n5", NARRADOR, "Juntaram as mãos e pediram um desejo mágico.", 10.20, 13.00, "+5%"),
    ("n6", NARRADOR, "A estrela brilhou!", 13.10, 14.90, "+0%"),
    ("n7", NARRADOR, "E subiu ao céu com um arco-íris.", 15.10, 17.10, "+5%"),
    ("f2", VOZ_FINAL, "A verdadeira magia acontece quando compartilhamos amor!", 17.25, 19.98, "+12%"),
]


def duracao_ffprobe(caminho: str) -> float:
    resultado = subprocess.run(
        [
            "ffprobe", "-v", "error", "-show_entries", "format=duration",
            "-of", "default=nw=1:nk=1", caminho,
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return float(resultado.stdout.strip())


async def gerar_falas() -> list[dict]:
    """Gera um MP3 por fala e o comprime, se necessário, para caber no tempo."""
    gerados = []
    for id_, voz, texto, inicio, fim, taxa in TRECHOS:
        bruto = os.path.join(TEMP, f"{id_}_bruto.mp3")
        pronto = os.path.join(TEMP, f"{id_}.wav")
        await edge_tts.Communicate(texto, voz, rate=taxa).save(bruto)
        dur = duracao_ffprobe(bruto)
        slot = fim - inicio
        filtro = "aresample=48000"
        if dur > slot - 0.05:
            fator = min(1.95, max(0.55, dur / (slot - 0.05)))
            filtro += f",atempo={fator:.4f}"
            print(f"  {id_}: {dur:.2f}s -> {slot - 0.05:.2f}s (atempo {fator:.2f})")
        else:
            print(f"  {id_}: {dur:.2f}s (slot {slot:.2f}s)")
        subprocess.run(
            [
                "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
                "-i", bruto, "-af", filtro + ",apad=pad_dur=0.2",
                "-ac", "2", "-ar", str(FPS), "-c:a", "pcm_s16le", pronto,
            ],
            check=True,
        )
        gerados.append({"id": id_, "inicio": inicio, "caminho": pronto, "texto": texto})
    return gerados


def escrever_wav(caminho: str, sinal: np.ndarray) -> None:
    sinal = np.clip(sinal, -1.0, 1.0)
    pcm = (sinal * 32767).astype("<i2")
    with wave.open(caminho, "wb") as arquivo:
        arquivo.setnchannels(2)
        arquivo.setsampwidth(2)
        arquivo.setframerate(FPS)
        arquivo.writeframes(pcm.tobytes())


def nota(freq: float, inicio: float, dur: float, amp: float, tipo: str = "piano") -> np.ndarray:
    """Adiciona uma nota com envelope suave ao buffer da trilha."""
    n = int(dur * FPS)
    t = np.arange(n) / FPS
    if tipo == "piano":
        onda = (
            np.sin(2 * np.pi * freq * t)
            + 0.42 * np.sin(2 * np.pi * freq * 2 * t)
            + 0.18 * np.sin(2 * np.pi * freq * 3 * t)
        )
        env = np.minimum(1.0, t / 0.012) * np.exp(-2.2 * t / max(dur, 0.01))
    elif tipo == "flauta":
        vibrato = 1 + 0.004 * np.sin(2 * np.pi * 5.5 * t)
        onda = np.sin(2 * np.pi * freq * vibrato * t) + 0.12 * np.sin(4 * np.pi * freq * t)
        env = np.minimum(1.0, t / 0.06) * np.minimum(1.0, (dur - t) / 0.09)
    else:  # sino
        onda = (
            np.sin(2 * np.pi * freq * t)
            + 0.5 * np.sin(2 * np.pi * freq * 2.01 * t)
            + 0.25 * np.sin(2 * np.pi * freq * 3.98 * t)
        )
        env = np.minimum(1.0, t / 0.004) * np.exp(-1.5 * t / max(dur, 0.01))
    bloco = np.zeros((n, 2), dtype=np.float32)
    bloco[:, 0] = onda * env * amp * 0.94
    bloco[:, 1] = onda * env * amp
    return bloco


def colar(destino: np.ndarray, bloco: np.ndarray, inicio: float) -> None:
    i = int(inicio * FPS)
    if i >= len(destino):
        return
    fim = min(len(destino), i + len(bloco))
    destino[i:fim] += bloco[: fim - i]


def midi(m: int) -> float:
    return 440.0 * 2 ** ((m - 69) / 12)


def gerar_trilha() -> None:
    """Melodia infantil em Dó maior, 10 compassos de 2 segundos."""
    trilha = np.zeros((int(DURACAO * FPS), 2), dtype=np.float32)
    melodia = [
        [72, 76, 79, 76], [72, 76, 79, 84],
        [69, 72, 76, 72], [69, 72, 76, 79],
        [65, 69, 72, 69], [67, 71, 74, 71],
        [72, 76, 79, 84], [76, 79, 84, 88],
        [79, 76, 72, 76], [72, 79, 84, 88],
    ]
    acordes = [
        [48, 55, 60], [48, 55, 64], [45, 52, 57], [45, 52, 60],
        [41, 48, 53], [43, 50, 55], [48, 55, 60], [48, 55, 64],
        [45, 52, 57], [48, 55, 60],
    ]
    for compasso in range(10):
        t0 = compasso * 2.0
        for b, nota_midi in enumerate(melodia[compasso]):
            inicio = t0 + b * 0.5
            tipo = "flauta" if compasso in (2, 3, 8) else "piano"
            colar(trilha, nota(midi(nota_midi), 0, 0.58, 0.105, tipo), inicio)
        for b in range(4):
            inicio = t0 + b * 0.5
            for m in acordes[compasso]:
                colar(trilha, nota(midi(m), 0, 0.9, 0.022, "flauta"), inicio)
        colar(trilha, nota(midi(acordes[compasso][0] - 12), 0, 1.3, 0.075, "piano"), t0)
    # Brilho extra na parte mágica e no final.
    for t0, f in ((10.4, 1046), (11.4, 1318), (12.4, 1568), (17.4, 1046), (18.2, 1568)):
        colar(trilha, nota(f, 0, 1.6, 0.045, "sino"), t0)
    escrever_wav(os.path.join(TEMP, "trilha.wav"), trilha)


def gerar_efeitos() -> None:
    rng = np.random.default_rng(7)
    sfx = np.zeros((int(DURACAO * FPS), 2), dtype=np.float32)

    def colar_ruido(inicio: float, dur: float, amp: float, corte: float, decrescente: bool) -> None:
        n = int(dur * FPS)
        t = np.arange(n) / FPS
        ruido = rng.standard_normal(n)
        janela = np.minimum(1.0, t / 0.05) * np.minimum(1.0, (dur - t) / 0.12)
        frequencia = np.linspace(9000, corte, n) if decrescente else np.linspace(corte, 9000, n)
        fase = 2 * np.pi * np.cumsum(frequencia) / FPS
        suave = np.convolve(ruido, np.ones(8) / 8, mode="same")
        onda = suave * (0.6 + 0.4 * np.sin(fase)) * janela * amp
        bloco = np.zeros((n, 2), dtype=np.float32)
        bloco[:, 0], bloco[:, 1] = onda, onda * 0.9
        colar(sfx, bloco, inicio)

    # 0.2-1.2s: estrela cadente.
    colar_ruido(0.20, 1.00, 0.12, 400, True)
    for i, f in enumerate((1760, 1320, 880)):
        colar(sfx, nota(f, 0, 0.8, 0.06 - i * 0.012, "sino"), 0.25 + i * 0.12)

    # 3.1s: espanto do menino.
    colar(sfx, nota(523, 0, 0.35, 0.10, "sino"), 3.10)
    colar(sfx, nota(784, 0, 0.30, 0.07, "sino"), 3.16)

    # 5.2s: chegada da menina.
    colar_ruido(5.15, 0.45, 0.055, 1200, False)
    colar(sfx, nota(659, 0, 0.4, 0.05, "flauta"), 5.25)

    # 10-15s: cintilância do pedido mágico.
    for i in range(18):
        t0 = 10.2 + i * 0.26
        f = float(rng.choice([784, 988, 1175, 1318, 1568, 1976]))
        colar(sfx, nota(f, 0, 0.75 + (i % 3) * 0.2, 0.055, "sino"), t0)
    colar_ruido(12.9, 0.8, 0.09, 600, False)

    # 15-17s: a estrela sobe ao céu.
    colar_ruido(15.0, 1.9, 0.08, 1600, False)
    for i, f in enumerate((523, 659, 784, 1046, 1318)):
        colar(sfx, nota(f, 0, 1.1, 0.055, "sino"), 15.1 + i * 0.28)

    # 17s em diante: arco-íris e corações.
    for i, f in enumerate((523, 659, 784, 1046)):
        colar(sfx, nota(f, 0, 2.4, 0.05, "sino"), 17.3 + i * 0.10)

    escrever_wav(os.path.join(TEMP, "efeitos.wav"), sfx)


def quebrar(texto: str, limite: int = 34) -> str:
    palavras = texto.split()
    linhas, atual = [], ""
    for palavra in palavras:
        candidata = f"{atual} {palavra}".strip()
        if len(candidata) > limite and atual:
            linhas.append(atual)
            atual = palavra
        else:
            atual = candidata
    if atual:
        linhas.append(atual)
    return "\\N".join(linhas)


def tempo_ass(segundos: float) -> str:
    centesimos = int(round(segundos * 100))
    h, centesimos = divmod(centesimos, 360000)
    m, centesimos = divmod(centesimos, 6000)
    s, c = divmod(centesimos, 100)
    return f"{h}:{m:02d}:{s:02d}.{c:02d}"


def gerar_legendas() -> None:
    cabecalho = """[Script Info]
Title: A historia da estrela - legendas em portugues
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Padrao,Arial,62,&H00FFFFFF,&H00FFFFFF,&H002A1B3C,&H90000000,-1,0,0,0,100,100,0,0,1,5,2,2,70,70,210,1
Style: Fala,Arial,66,&H00FFF3A8,&H00FFFFFF,&H002A1B3C,&H90000000,-1,0,0,0,100,100,0,0,1,5,2,2,70,70,210,1
Style: Final,Arial,68,&H00FFFFFF,&H00FFFFFF,&H002A1B3C,&H90000000,-1,0,0,0,100,100,0,0,1,6,3,2,60,60,230,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""
    eventos = []
    for id_, _, texto, inicio, fim, _ in TRECHOS:
        estilo = "Fala" if id_ == "f1" else "Final" if id_ == "f2" else "Padrao"
        eventos.append(
            f"Dialogue: 0,{tempo_ass(inicio)},{tempo_ass(min(fim, 19.96))},{estilo},,0,0,0,,{quebrar(texto)}"
        )
    with open(os.path.join(OUTPUT, "historia_legendas.ass"), "w", encoding="utf-8") as arquivo:
        arquivo.write(cabecalho + "\n".join(eventos) + "\n")


def mixar(falas: list[dict]) -> None:
    entradas: list[str] = []
    filtros: list[str] = []
    for i, fala in enumerate(falas):
        entradas += ["-i", fala["caminho"]]
        atraso = int(round(fala["inicio"] * 1000))
        indice = i + 1  # o input 0 é o vídeo
        filtros.append(f"[{indice}:a]adelay={atraso}|{atraso},volume=1.15[f{i}]")

    n_falas = len(falas)
    entradas += ["-i", os.path.join(TEMP, "trilha.wav")]
    entradas += ["-i", os.path.join(TEMP, "efeitos.wav")]
    indice_trilha, indice_sfx = n_falas + 1, n_falas + 2
    filtros += [
        f"[{indice_trilha}:a]volume=0.30[mus]",
        f"[{indice_sfx}:a]volume=0.42[sfx]",
        "[" + "][".join(f"f{i}" for i in range(n_falas)) + f"][mus][sfx]"
        f"amix=inputs={n_falas + 2}:duration=longest:dropout_transition=0,"
        "atrim=duration=20,loudnorm=I=-16:TP=-1.5:LRA=11[a]",
    ]
    filtro_video = "ass=filename=historia_legendas.ass"
    comando = [
        "ffmpeg", "-y", "-hide_banner", "-loglevel", "error",
        "-i", VIDEO,
        *entradas,
        "-filter_complex", ";".join(filtros) + f";[0:v]{filtro_video}[v]",
        "-map", "[v]", "-map", "[a]",
        "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
        "-shortest", FINAL,
    ]
    subprocess.run(comando, check=True, cwd=OUTPUT)


def main() -> None:
    print("Gerando falas em portugues brasileiro...")
    falas = asyncio.run(gerar_falas())
    print("Sintetizando trilha infantil...")
    gerar_trilha()
    print("Sintetizando efeitos magicos...")
    gerar_efeitos()
    print("Criando legendas ASS...")
    gerar_legendas()
    print("Mixando e muxando...")
    mixar(falas)
    print(f"Pronto: {FINAL} ({duracao_ffprobe(FINAL):.2f}s)")


if __name__ == "__main__":
    main()
