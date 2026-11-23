"""Cena 3D estilo Pixar: dois irmaos jogando pebolim de caixa de papelao.

Gratuito e compativel com AMD (renderizador Eevee, sem CUDA).

Uso:
    blender -b -t 4 --python tools/blender/pebolim_pixar.py
    blender -b -t 4 --python tools/blender/pebolim_pixar.py -- --preset closeup
    blender -b -t 4 --python tools/blender/pebolim_pixar.py -- --preset celebration --duration 12
    blender -b -t 4 --python tools/blender/pebolim_pixar.py -- --no-render

Opcoes (depois de ``--``):
    --preset pixar|closeup|celebration   direcao visual (padrao: pixar)
    --duration SEGUNDOS                  duracao da animacao
    --width PX / --height PX             resolucao
    --no-render                          salva apenas o .blend

Saidas (pasta output/ ao lado deste arquivo):
    pebolim_<preset>.blend   cena editavel
    pebolim_<preset>.mp4     animacao H.264

Requer Blender 4.2+ (Eevee Next). No Blender 4.0/4.1 usa Eevee classico
automaticamente.
"""

from __future__ import annotations

import math
import os
import sys

import bpy
from mathutils import Vector


# ---------------------------------------------------------------------------
# Configuracao
# ---------------------------------------------------------------------------

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

ARGS = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []


def _arg(nome: str, padrao):
    if nome in ARGS:
        indice = ARGS.index(nome)
        if indice + 1 < len(ARGS):
            return ARGS[indice + 1]
    return padrao


PRESETS = {
    "pixar": {
        "camera": (4.4, -5.4, 3.1),
        "alvo": (0, 0, 1.25),
        "lente": 42,
        "duracao": 8,
        "resolucao": (1920, 1080),
        "luzes": (
            ((2.5, -2.5, 5.0), 900, 5.0, (1.0, 0.94, 0.86)),
            ((-3.5, -1.5, 3.5), 450, 4.0, (0.86, 0.92, 1.0)),
            ((0.5, 3.5, 4.0), 700, 3.0, (1.0, 0.88, 0.72)),
        ),
        "mundo": (0.35, 0.30, 0.28),
        "mundo_intensidade": 0.7,
        "amplitude": 1.0,
        "velocidade": 1.0,
    },
    "closeup": {
        "camera": (2.1, -3.3, 2.35),
        "alvo": (0.0, -0.4, 1.38),
        "lente": 55,
        "duracao": 6,
        "resolucao": (1280, 720),
        "luzes": (
            ((1.5, -2.2, 4.0), 1100, 3.5, (1.0, 0.85, 0.70)),
            ((-2.5, -1.0, 3.0), 500, 3.0, (0.88, 0.90, 1.0)),
            ((0.5, 3.0, 3.5), 650, 2.5, (1.0, 0.80, 0.60)),
        ),
        "mundo": (0.42, 0.30, 0.22),
        "mundo_intensidade": 0.85,
        "amplitude": 0.7,
        "velocidade": 0.85,
    },
    "celebration": {
        "camera": (5.0, -6.4, 3.8),
        "alvo": (0, 0, 1.30),
        "lente": 38,
        "duracao": 10,
        "resolucao": (1920, 1080),
        "luzes": (
            ((2.5, -2.5, 5.0), 1200, 5.0, (1.0, 0.90, 0.75)),
            ((-3.5, -1.5, 3.5), 600, 4.0, (0.75, 0.85, 1.0)),
            ((0.5, 3.5, 4.0), 900, 3.0, (1.0, 0.70, 0.45)),
        ),
        "mundo": (0.30, 0.25, 0.35),
        "mundo_intensidade": 0.9,
        "amplitude": 1.4,
        "velocidade": 1.5,
    },
}

PRESET = str(_arg("--preset", "pixar")).strip().lower()
if PRESET not in PRESETS:
    print(f"Preset desconhecido '{PRESET}'. Usando 'pixar'.")
    PRESET = "pixar"
CFG = PRESETS[PRESET]

FPS = 24
DURATION_SECONDS = float(_arg("--duration", CFG["duracao"]))
FRAME_END = max(FPS, int(FPS * DURATION_SECONDS))
LARGURA = int(_arg("--width", CFG["resolucao"][0]))
ALTURA = int(_arg("--height", CFG["resolucao"][1]))
RESOLUTION = (LARGURA, ALTURA)
RENDER = "--no-render" not in ARGS
NOME = f"pebolim_{PRESET}"


def quadro(t: float) -> int:
    """Converte uma fracao [0..1] em numero de frame valido."""
    return max(1, min(FRAME_END, round(1 + t * (FRAME_END - 1))))


# ---------------------------------------------------------------------------
# Utilitarios
# ---------------------------------------------------------------------------


def limpar_cena() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for colecao in (bpy.data.meshes, bpy.data.materials, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
        for bloco in list(colecao):
            if bloco.users == 0:
                colecao.remove(bloco)


def material(nome: str, cor: tuple[float, float, float], roughness: float = 0.6, subsurface: float = 0.0):
    mat = bpy.data.materials.new(nome)
    mat.diffuse_color = (*cor, 1.0)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*cor, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    for chave in ("Subsurface Weight", "Subsurface"):
        if chave in bsdf.inputs:
            bsdf.inputs[chave].default_value = subsurface
            break
    return mat


def cubo(nome, localizacao, escala, mat, rotacao=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(location=localizacao, rotation=rotacao)
    obj = bpy.context.object
    obj.name = nome
    obj.scale = escala
    obj.data.materials.append(mat)
    return obj


def esfera(nome, localizacao, raio, mat, escala=None, segmentos=32):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segmentos, ring_count=16, radius=raio, location=localizacao
    )
    obj = bpy.context.object
    obj.name = nome
    if escala:
        obj.scale = escala
    obj.data.materials.append(mat)
    return obj


def cilindro(nome, localizacao, raio, profundidade, mat, rotacao=(0, 0, 0), vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices,
        radius=raio,
        depth=profundidade,
        location=localizacao,
        rotation=rotacao,
    )
    obj = bpy.context.object
    obj.name = nome
    obj.data.materials.append(mat)
    return obj


def curva_sorriso(nome, centro, frente, mat):
    """Arco de sorriso na frente do rosto, no plano X-Z."""
    dados = bpy.data.curves.new(nome, type="CURVE")
    dados.dimensions = "3D"
    dados.bevel_depth = 0.012
    dados.bevel_resolution = 3
    spline = dados.splines.new("BEZIER")
    spline.bezier_points.add(2)
    x, y, z = centro
    pontos = [
        (x - 0.11, y + frente * 0.30, z - 0.04),
        (x, y + frente * 0.325, z - 0.005),
        (x + 0.11, y + frente * 0.30, z - 0.04),
    ]
    for ponto, co in zip(spline.bezier_points, pontos):
        ponto.co = co
        ponto.handle_left_type = "AUTO"
        ponto.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(nome, dados)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def vazio(nome, localizacao):
    obj = bpy.data.objects.new(nome, None)
    bpy.context.collection.objects.link(obj)
    obj.location = localizacao
    obj.empty_display_size = 0.15
    return obj


# ---------------------------------------------------------------------------
# Materiais
# ---------------------------------------------------------------------------

limpar_cena()

M_PAREDE = material("Parede creme", (0.96, 0.90, 0.80))
M_PISO = material("Piso madeira", (0.72, 0.48, 0.30))
M_PAPELAO = material("Papelao", (0.72, 0.52, 0.30), roughness=0.9)
M_PAPELAO_CLARO = material("Papelao claro", (0.85, 0.66, 0.40), roughness=0.9)
M_MADEIRA = material("Palito de madeira", (0.80, 0.60, 0.36))
M_PRETO = material("Preto", (0.06, 0.05, 0.08), roughness=0.35)
M_BRANCO = material("Branco", (0.99, 0.98, 0.96))

CORES_TAMPINHA = [
    (0.98, 0.36, 0.30),  # coral
    (1.00, 0.75, 0.20),  # amarelo
    (0.30, 0.70, 0.90),  # ciano
    (0.42, 0.80, 0.48),  # verde
    (0.70, 0.45, 0.92),  # lilas
]
M_TAMPINHAS = [material(f"Tampinha {i+1}", c, roughness=0.35) for i, c in enumerate(CORES_TAMPINHA)]

CORES_PELE = [(0.96, 0.76, 0.60), (0.82, 0.58, 0.42)]
CORES_CAMISA = [(0.98, 0.45, 0.28), (0.30, 0.62, 0.88)]
CORES_CABELO = [(0.20, 0.12, 0.10), (0.42, 0.22, 0.10)]


# ---------------------------------------------------------------------------
# Cozinha
# ---------------------------------------------------------------------------

cubo("Piso", (0, 0, -0.05), (8, 8, 0.10), M_PISO)
cubo("Parede fundo", (0, 3.2, 2.0), (8, 0.10, 4.0), M_PAREDE)
cubo("Parede esquerda", (-4.0, 0, 2.0), (0.10, 8, 4.0), M_PAREDE)

# Mesa de apoio
cubo("Mesa", (0, 0, 0.62), (2.0, 1.15, 0.09), M_MADEIRA)
for px in (-1.75, 1.75):
    for py in (-0.95, 0.95):
        cubo(f"Perna mesa {px} {py}", (px, py, 0.36), (0.08, 0.08, 0.36), M_MADEIRA)


# ---------------------------------------------------------------------------
# Pebolim de caixa de papelao
# ---------------------------------------------------------------------------

MESA_Z = 1.15
# Caixa de papelao que sustenta o campo sobre a mesa.
cubo("Base papelao", (0, 0, 0.93), (1.70, 0.95, 0.22), M_PAPELAO)
cubo("Campo papelao", (0, 0, MESA_Z), (1.65, 0.92, 0.05), M_PAPELAO_CLARO)
cubo("Borda esquerda", (-1.65, 0, MESA_Z + 0.14), (0.07, 0.95, 0.20), M_PAPELAO)
cubo("Borda direita", (1.65, 0, MESA_Z + 0.14), (0.07, 0.95, 0.20), M_PAPELAO)
cubo("Borda frente", (0, -0.92, MESA_Z + 0.14), (1.70, 0.07, 0.20), M_PAPELAO)
cubo("Borda tras", (0, 0.92, MESA_Z + 0.14), (1.70, 0.07, 0.20), M_PAPELAO)

# Linha central desenhada com uma faixa fina
cubo("Linha central", (0, 0, MESA_Z + 0.055), (0.02, 0.90, 0.005), M_BRANCO)

PIVOS = []
POSICOES_HASTE = (-1.05, -0.55, 0.55, 1.05)
for indice, x in enumerate(POSICOES_HASTE):
    piv = vazio(f"Haste {indice+1} — pivo", (x, 0, MESA_Z + 0.22))
    PIVOS.append((piv, x))

    corpo = cilindro(
        f"Haste {indice+1} — palito",
        (0, 0, 0),
        0.018,
        1.95,
        M_MADEIRA,
        rotacao=(math.pi / 2, 0, 0),
    )
    corpo.parent = piv

    # Tampinhas: duas por haste, uma de cada lado
    for lado, y in ((-1, -0.55), (1, 0.55)):
        mat = M_TAMPINHAS[(indice + (0 if lado < 0 else 2)) % len(M_TAMPINHAS)]
        tampinha = cilindro(
            f"Tampinha {indice+1}{'A' if lado < 0 else 'B'}",
            (0, y, 0),
            0.095,
            0.035,
            mat,
            rotacao=(0, math.pi / 2, 0),
        )
        tampinha.parent = piv

        # "Bracinhos" da tampinha
        for sinal in (-1, 1):
            braco = cilindro(
                f"Braco tampinha {indice+1}{lado}{sinal}",
                (0, y + sinal * 0.06, 0.08),
                0.012,
                0.16,
                mat,
                rotacao=(0, math.pi / 2, 0),
            )
            braco.parent = piv


# ---------------------------------------------------------------------------
# Irmaos
# ---------------------------------------------------------------------------


def criar_irmao(indice: int, x: float, y: float, frente: int = -1):
    # ``frente`` e a direcao para onde o rosto olha (-1 = para a camera).
    pele = material(f"Pele irmao {indice+1}", CORES_PELE[indice], subsurface=0.12)
    camisa = material(f"Camisa irmao {indice+1}", CORES_CAMISA[indice])
    cabelo = material(f"Cabelo irmao {indice+1}", CORES_CABELO[indice])
    boca = material(f"Boca irmao {indice+1}", (0.55, 0.18, 0.20))

    base = vazio(f"Irmao {indice+1} — raiz", (x, y, 0))

    tronco = esfera(
        f"Irmao {indice+1} — tronco", (0, 0, 0.85), 1, camisa, escala=(0.34, 0.25, 0.46)
    )
    tronco.parent = base

    cabeca = vazio(f"Irmao {indice+1} — cabeca pivô", (0, 0, 1.52))
    cabeca.parent = base

    rosto = esfera(f"Irmao {indice+1} — rosto", (0, 0, 0), 0.30, pele)
    rosto.parent = cabeca

    cabelo_obj = esfera(
        f"Irmao {indice+1} — cabelo", (0, -frente * 0.02, 0.17), 0.29, cabelo, escala=(1.0, 1.0, 0.62)
    )
    cabelo_obj.parent = cabeca

    oculos_palpebras = []
    for olho_i, ox in enumerate((-0.115, 0.115)):
        olho = esfera(
            f"Irmao {indice+1} — olho {olho_i+1}",
            (ox, frente * 0.255, 0.045),
            0.072,
            M_BRANCO,
        )
        olho.parent = cabeca
        pupil = esfera(
            f"Irmao {indice+1} — pupila {olho_i+1}",
            (ox, frente * 0.318, 0.045),
            0.034,
            M_PRETO,
        )
        pupil.parent = cabeca

        palpebra = esfera(
            f"Irmao {indice+1} — palpebra {olho_i+1}",
            (ox, frente * 0.30, 0.045),
            0.078,
            pele,
            escala=(1.0, 0.35, 0.02),
        )
        palpebra.parent = cabeca
        oculos_palpebras.append(palpebra)

    sorriso = curva_sorriso(f"Irmao {indice+1} — sorriso", (0, 0, 0.01), frente, boca)
    sorriso.parent = cabeca

    # Bracos e maos apontando para a mesa
    maos = []
    for braco_i, (bx, alvo_x) in enumerate(((-0.30, -0.55), (0.30, 0.55))):
        braco = cilindro(
            f"Irmao {indice+1} — braco {braco_i+1}",
            (bx, frente * 0.22, 1.10),
            0.075,
            0.55,
            camisa,
            rotacao=(math.pi / 2.6, 0, 0),
        )
        braco.parent = base
        mao = esfera(
            f"Irmao {indice+1} — mao {braco_i+1}",
            (alvo_x, frente * 0.92, MESA_Z + 0.22),
            0.09,
            pele,
        )
        mao.parent = base
        maos.append((mao, alvo_x))

    # Perninhas
    for px in (-0.16, 0.16):
        cubo(f"Irmao {indice+1} — perna {px}", (px, 0, 0.28), (0.10, 0.11, 0.30), camisa).parent = base

    return {"cabeca": cabeca, "palpebras": oculos_palpebras, "maos": maos, "frente": frente}


irmao1 = criar_irmao(0, -0.85, -2.05, frente=-1)
irmao2 = criar_irmao(1, 0.85, -2.05, frente=-1)


# ---------------------------------------------------------------------------
# Animacao (tempos proporcionais a duracao, independentes do preset)
# ---------------------------------------------------------------------------

AMP = CFG["amplitude"]
VEL = CFG["velocidade"]

for piv, x_base in PIVOS:
    for t, angulo, deslocamento in (
        (0.00, 0.0, 0.0),
        (0.25 * VEL, 0.95 * AMP, 0.11 * AMP),
        (0.50 * VEL, -0.85 * AMP, -0.11 * AMP),
        (0.75 * VEL, 0.55 * AMP, 0.07 * AMP),
        (1.00, 0.0, 0.0),
    ):
        piv.rotation_euler[1] = angulo
        piv.location.x = x_base + deslocamento
        piv.keyframe_insert(data_path="rotation_euler", frame=quadro(t))
        piv.keyframe_insert(data_path="location", frame=quadro(t))

for irmao in (irmao1, irmao2):
    cabeca = irmao["cabeca"]
    for t, rz, rx in (
        (0.00, 0.0, 0.0),
        (0.25 * VEL, 0.14 * AMP, 0.05 * AMP),
        (0.50 * VEL, -0.12 * AMP, -0.04 * AMP),
        (0.75 * VEL, 0.10 * AMP, 0.03 * AMP),
        (1.00, 0.0, 0.0),
    ):
        cabeca.rotation_euler[2] = rz
        cabeca.rotation_euler[0] = rx
        cabeca.keyframe_insert(data_path="rotation_euler", frame=quadro(t))

    for palpebra in irmao["palpebras"]:
        for t, altura in (
            (0.00, 0.02),
            (0.30, 0.02),
            (0.32, 1.0),
            (0.34, 0.02),
            (0.66, 0.02),
            (0.68, 1.0),
            (0.70, 0.02),
            (1.00, 0.02),
        ):
            palpebra.scale[2] = altura
            palpebra.keyframe_insert(data_path="scale", frame=quadro(t))

    for mao, x_base in irmao["maos"]:
        for t, deslocamento in (
            (0.00, 0.0),
            (0.25 * VEL, 0.08 * AMP),
            (0.50 * VEL, -0.09 * AMP),
            (0.75 * VEL, 0.05 * AMP),
            (1.00, 0.0),
        ):
            mao.location.x = x_base + deslocamento
            mao.keyframe_insert(data_path="location", frame=quadro(t))


# Interpolacao suave (Bezier) em todos os keyframes
for acao in bpy.data.actions:
    for curva in getattr(acao, "fcurves", []):
        for ponto in curva.keyframe_points:
            ponto.interpolation = "BEZIER"
            ponto.handle_left_type = "AUTO_CLAMPED"
            ponto.handle_right_type = "AUTO_CLAMPED"


# ---------------------------------------------------------------------------
# Iluminacao suave
# ---------------------------------------------------------------------------


def area_light(nome, localizacao, alvo, energia, tamanho, cor=(1, 1, 1)):
    dados = bpy.data.lights.new(nome, type="AREA")
    dados.energy = energia
    dados.shape = "DISK"
    dados.size = tamanho
    dados.color = cor
    obj = bpy.data.objects.new(nome, dados)
    bpy.context.collection.objects.link(obj)
    obj.location = localizacao
    direcao = Vector(alvo) - obj.location
    obj.rotation_euler = direcao.to_track_quat("-Z", "Y").to_euler()
    return obj


for indice, (posicao, energia, tamanho, cor) in enumerate(CFG["luzes"]):
    area_light(f"Luz {indice+1}", posicao, (0, 0, 1.2), energia, tamanho, cor)

mundo = bpy.data.worlds.new("Ambiente")
bpy.context.scene.world = mundo
mundo.use_nodes = True
fundo = mundo.node_tree.nodes.get("Background")
fundo.inputs["Color"].default_value = (*CFG["mundo"], 1.0)
fundo.inputs["Strength"].default_value = CFG["mundo_intensidade"]


# ---------------------------------------------------------------------------
# Camera e render
# ---------------------------------------------------------------------------

dados_camera = bpy.data.cameras.new("Camera principal")
camera = bpy.data.objects.new("Camera principal", dados_camera)
bpy.context.collection.objects.link(camera)
camera.location = CFG["camera"]
direcao = Vector(CFG["alvo"]) - camera.location
camera.rotation_euler = direcao.to_track_quat("-Z", "Y").to_euler()
dados_camera.lens = CFG["lente"]

cena = bpy.context.scene
cena.camera = camera

for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    try:
        cena.render.engine = engine
        break
    except TypeError:
        continue

cena.render.resolution_x, cena.render.resolution_y = RESOLUTION
cena.render.resolution_percentage = 100
cena.render.fps = FPS
cena.frame_start = 1
cena.frame_end = FRAME_END
cena.render.film_transparent = False
try:
    cena.view_settings.view_transform = "AgX"
except TypeError:
    pass

cena.render.image_settings.file_format = "FFMPEG"
cena.render.image_settings.color_mode = "RGB"
cena.render.ffmpeg.format = "MPEG4"
cena.render.ffmpeg.codec = "H264"
cena.render.ffmpeg.constant_rate_factor = "MEDIUM"
cena.render.ffmpeg.ffmpeg_preset = "GOOD"
cena.render.filepath = os.path.join(OUTPUT_DIR, f"{NOME}.mp4")

blend_path = os.path.join(OUTPUT_DIR, f"{NOME}.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(f"Cena salva: {blend_path} ({PRESET}, {DURATION_SECONDS:g}s, {LARGURA}x{ALTURA})")

if RENDER:
    print("Renderizando animacao...")
    bpy.ops.render.render(animation=True)
    print(f"Video pronto: {cena.render.filepath}")
else:
    print("Render pulado (--no-render).")
