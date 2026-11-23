"""Animacao infantil 3D estilo Pixar: "A historia da estrela".

Quatro cenas, 20 segundos, vertical 9:16, renderizada localmente no Blender
(Eevee, compativel com GPU AMD, sem CUDA e sem nenhuma API paga).

Cena 1 (0-5s)   : o menino encontra uma estrela cadente no jardim e se surpreende.
Cena 2 (5-10s)  : a menina chega e pergunta "Será que ela está perdida?".
Cena 3 (10-15s) : os dois juntam as maos e fazem um pedido; a estrela brilha.
Cena 4 (15-20s) : a estrela sobe, cria um arco-iris e os dois sorriem.

Uso:
    blender -b -t 4 --python tools/blender/historia_da_estrela.py
    blender -b -t 4 --python tools/blender/historia_da_estrela.py -- --no-render
"""

from __future__ import annotations

import math
import os
import random
import sys

import bpy
from mathutils import Vector


# ---------------------------------------------------------------------------
# Argumentos e configuracao
# ---------------------------------------------------------------------------

ARGS = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

FPS = 24
DURACAO = 20.0
FRAMES = int(FPS * DURACAO)
LARGURA = 1080
ALTURA = 1920
RENDER = "--no-render" not in ARGS
CAMINHO_SAIDA = os.path.join(OUTPUT_DIR, "historia_da_estrela_video.mp4")

random.seed(7)


def q(t: float) -> int:
    """Converte tempo em segundos para numero de frame."""
    return max(1, min(FRAMES, round(1 + t * (FRAMES - 1))))


# ---------------------------------------------------------------------------
# Cena limpa e render
# ---------------------------------------------------------------------------

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for colecao in (bpy.data.meshes, bpy.data.materials, bpy.data.curves, bpy.data.cameras, bpy.data.lights):
    for bloco in list(colecao):
        if bloco.users == 0:
            colecao.remove(bloco)

cena = bpy.context.scene
for engine in ("BLENDER_EEVEE_NEXT", "BLENDER_EEVEE"):
    try:
        cena.render.engine = engine
        break
    except TypeError:
        continue

cena.render.resolution_x = LARGURA
cena.render.resolution_y = ALTURA
cena.render.resolution_percentage = 100
cena.render.fps = FPS
cena.frame_start = 1
cena.frame_end = FRAMES
try:
    cena.eevee.taa_render_samples = 32
except Exception:
    pass
try:
    cena.render.image_settings.file_format = "FFMPEG"
    cena.render.image_settings.color_mode = "RGB"
    cena.render.ffmpeg.format = "MPEG4"
    cena.render.ffmpeg.codec = "H264"
    cena.render.ffmpeg.constant_rate_factor = "MEDIUM"
    cena.render.ffmpeg.ffmpeg_preset = "GOOD"
except Exception as exc:
    print("Aviso FFMPEG:", exc)
cena.render.filepath = CAMINHO_SAIDA
try:
    cena.view_settings.view_transform = "Standard"
    cena.view_settings.look = "Medium High Contrast"
except Exception:
    pass

# Brilho suave dos elementos magicos (se disponivel nesta versao do Blender).
try:
    cena.use_nodes = True
    nos_comp = cena.node_tree.nodes
    rl = nos_comp.get("Render Layers")
    comp = nos_comp.get("Composite")
    glare = nos_comp.new("CompositorNodeGlare")
    try:
        glare.glare_type = "FOG_GLOW"
    except Exception:
        pass
    for prop, valor in (("quality", "MEDIUM"), ("threshold", 0.65), ("size", 7)):
        try:
            setattr(glare, prop, valor)
        except Exception:
            pass
    cena.node_tree.links.new(rl.outputs["Image"], glare.inputs["Image"])
    cena.node_tree.links.new(glare.outputs["Image"], comp.inputs["Image"])
    print("Glare de composicao ativado.")
except Exception as exc:
    print("Glare indisponivel (segue sem ele):", exc)


# ---------------------------------------------------------------------------
# Utilitarios
# ---------------------------------------------------------------------------


def material(nome: str, cor, brilho: float = 0.0, emissivo: bool = False):
    mat = bpy.data.materials.new(nome)
    mat.diffuse_color = (*cor, 1.0)
    mat.use_nodes = True
    nos = mat.node_tree.nodes
    nos.clear()
    if emissivo:
        no = nos.new("ShaderNodeEmission")
        no.inputs["Color"].default_value = (*cor, 1.0)
        no.inputs["Strength"].default_value = brilho or 1.0
    else:
        no = nos.new("ShaderNodeBsdfPrincipled")
        no.inputs["Base Color"].default_value = (*cor, 1.0)
        no.inputs["Roughness"].default_value = 0.62
        no.inputs["Metallic"].default_value = 0.0
    saida = nos.new("ShaderNodeOutputMaterial")
    mat.node_tree.links.new(no.outputs[0], saida.inputs["Surface"])
    return mat


def suavizar(obj, caminho: str = "location") -> None:
    acao = obj.animation_data.action if obj.animation_data else None
    if not acao:
        return
    for curva in getattr(acao, "fcurves", []):
        if curva.data_path != caminho:
            continue
        for ponto in curva.keyframe_points:
            ponto.interpolation = "BEZIER"
            ponto.handle_left_type = "AUTO_CLAMPED"
            ponto.handle_right_type = "AUTO_CLAMPED"


def cubo(nome, local, escala, mat, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=local)
    obj = bpy.context.object
    obj.name = nome
    obj.scale = escala
    obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
    return obj


def esfera(nome, local, raio, mat, escala=None, segmentos=20, parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segmentos, ring_count=12, radius=raio, location=local
    )
    obj = bpy.context.object
    obj.name = nome
    if escala:
        obj.scale = escala
    obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
    return obj


def cilindro(nome, local, raio, altura, mat, vertices=12, parent=None):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=vertices, radius=raio, depth=altura, location=local
    )
    obj = bpy.context.object
    obj.name = nome
    obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
    return obj


def cone(nome, local, raio_topo, raio_base, altura, mat, vertices=20, parent=None):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=raio_base,
        radius2=raio_topo,
        depth=altura,
        location=local,
    )
    obj = bpy.context.object
    obj.name = nome
    obj.data.materials.append(mat)
    if parent:
        obj.parent = parent
    return obj


def vazio(nome, local=(0, 0, 0), parent=None):
    obj = bpy.data.objects.new(nome, None)
    bpy.context.collection.objects.link(obj)
    obj.location = local
    if parent:
        obj.parent = parent
    return obj


def ligar(obj, ponto_a, ponto_b, frame=None):
    """Posiciona um cilindro (altura 1) entre dois pontos."""
    a, b = Vector(ponto_a), Vector(ponto_b)
    d = b - a
    obj.location = (a + b) / 2
    obj.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    obj.scale = (1, 1, max(0.001, d.length))
    if frame is not None:
        obj.keyframe_insert("location", frame=frame)
        obj.keyframe_insert("rotation_euler", frame=frame)
        obj.keyframe_insert("scale", frame=frame)


def olhar(obj, alvo, frame) -> None:
    obj.rotation_euler = (Vector(alvo) - obj.location).to_track_quat("-Z", "Y").to_euler()
    obj.keyframe_insert("rotation_euler", frame=frame)


def escala_em(obj, valores, frames):
    for valor, frame in zip(valores, frames):
        obj.scale = valor if isinstance(valor, (tuple, list)) else (valor, valor, valor)
        obj.keyframe_insert("scale", frame=frame)
    suavizar(obj, "scale")


# ---------------------------------------------------------------------------
# Paleta
# ---------------------------------------------------------------------------

PELE = (1.0, 0.80, 0.64)
PELE2 = (0.96, 0.74, 0.57)
CAFE = (0.34, 0.18, 0.11)
CAFE_CLARO = (0.46, 0.26, 0.15)
AZUL = (0.16, 0.52, 0.95)
AZUL_ESCURO = (0.10, 0.30, 0.60)
ROSA = (1.0, 0.42, 0.66)
ROSA_CLARO = (1.0, 0.70, 0.82)
AMARELO = (1.0, 0.86, 0.25)
BRANCO = (1.0, 1.0, 1.0)
PRETO = (0.10, 0.09, 0.12)
VERDE = (0.30, 0.76, 0.34)
VERDE_ESCURO = (0.18, 0.58, 0.26)
TERRA = (0.55, 0.36, 0.20)

M_PELE = material("Pele", PELE)
M_PELE2 = material("Pele menina", PELE2)
M_CAFE = material("Cabelo castanho", CAFE)
M_CAFE_CLARO = material("Cabelo cacheado", CAFE_CLARO)
M_AZUL = material("Camiseta azul", AZUL)
M_AZUL_ESCURO = material("Calcao azul", AZUL_ESCURO)
M_ROSA = material("Vestido rosa", ROSA)
M_ROSA_CLARO = material("Sapatinho rosa", ROSA_CLARO)
M_AMARELO = material("Amarelo", AMARELO, 1.6, True)
M_BRANCO = material("Branco olho", BRANCO)
M_PRETO = material("Preto olho", PRETO)
M_VERDE = material("Grama", VERDE)
M_VERDE_ESCURO = material("Folhagem", VERDE_ESCURO)
M_TERRA = material("Terra", TERRA)
M_BOCINHA = material("Boca", (0.48, 0.14, 0.18))
M_BOCHECHA = material("Bochecha", (1.0, 0.52, 0.55))
M_NUVEM = material("Nuvem", (1.0, 0.99, 0.96), 0.55, True)


# ---------------------------------------------------------------------------
# Ceu, jardim e luzes
# ---------------------------------------------------------------------------

# Gradiente do ceu em coordenadas de mundo.
ceu_mat = bpy.data.materials.new("Ceu gradiente")
ceu_mat.use_nodes = True
nos = ceu_mat.node_tree.nodes
nos.clear()
geo = nos.new("ShaderNodeNewGeometry")
sep = nos.new("ShaderNodeSeparateXYZ")
mapa = nos.new("ShaderNodeMapRange")
mapa.inputs["From Min"].default_value = 0.0
mapa.inputs["From Max"].default_value = 11.0
rampa = nos.new("ShaderNodeValToRGB")
rampa.color_ramp.elements[0].position = 0.0
rampa.color_ramp.elements[0].color = (0.68, 0.91, 1.0, 1.0)
rampa.color_ramp.elements[1].position = 1.0
rampa.color_ramp.elements[1].color = (0.16, 0.48, 0.96, 1.0)
emis = nos.new("ShaderNodeEmission")
emis.inputs["Strength"].default_value = 1.0
saida = nos.new("ShaderNodeOutputMaterial")
lt = ceu_mat.node_tree.links
lt.new(geo.outputs["Position"], sep.inputs[0])
lt.new(sep.outputs["Z"], mapa.inputs["Value"])
lt.new(mapa.outputs["Result"], rampa.inputs["Fac"])
lt.new(rampa.outputs["Color"], emis.inputs["Color"])
lt.new(emis.outputs[0], saida.inputs["Surface"])

fundo = cubo("Ceu", (0, 6.0, 5.2), (34, 0.1, 15), ceu_mat)  # type: ignore[arg-type]
grama = cubo("Jardim", (0, 0, -0.08), (34, 22, 0.16), M_VERDE)

for i in range(30):
    x, y = random.uniform(-7, 7), random.uniform(-2.5, 4)
    mancha = esfera(
        f"Mancha grama {i+1}",
        (x, y, 0.005),
        random.uniform(0.18, 0.5),
        M_VERDE_ESCURO if i % 2 else material(f"Grama clara {i}", (0.42, 0.86, 0.42)),
        escala=(1, 0.8, 0.06),
        segmentos=12,
    )

CORES_FLOR = [
    (1.0, 0.40, 0.55),
    (1.0, 0.78, 0.20),
    (0.85, 0.45, 1.0),
    (1.0, 1.0, 1.0),
    (0.35, 0.75, 1.0),
]
for i in range(34):
    x, y = random.uniform(-6.5, 6.5), random.uniform(-1.8, 4.2)
    if abs(x) < 1.7 and y < 1.2:
        continue
    cor = CORES_FLOR[i % len(CORES_FLOR)]
    mat_petala = material(f"Petala {i}", cor)
    h = random.uniform(0.18, 0.32)
    cilindro(f"Caule {i+1}", (x, y, h / 2), 0.012, h, M_VERDE_ESCURO, 8)
    for p in range(5):
        a = 2 * math.pi * p / 5
        esfera(
            f"Petala {i+1}.{p+1}",
            (x + 0.055 * math.cos(a), y + 0.055 * math.sin(a), h),
            0.05,
            mat_petala,
            escala=(1, 1, 0.45),
            segmentos=10,
        )
    esfera(f"Miolo {i+1}", (x, y, h + 0.02), 0.042, M_AMARELO, segmentos=10)

# Arbustos e arvores nas bordas.
for i, x in enumerate((-4.6, -3.7, 3.8, 4.8, -5.8, 5.9)):
    y = random.uniform(0.6, 3.2)
    for j in range(4):
        esfera(
            f"Arbusto {i+1}.{j+1}",
            (x + random.uniform(-0.3, 0.3), y, 0.22 + j * 0.06),
            random.uniform(0.28, 0.46),
            M_VERDE if j % 2 else M_VERDE_ESCURO,
            escala=(1, 0.9, 0.8),
            segmentos=12,
        )

for i, x in enumerate((-3.4, 3.5)):
    y = 2.6
    cilindro(f"Tronco {i+1}", (x, y, 0.7), 0.13, 1.4, M_TERRA, 12)
    for j, (dx, dy, dz, r) in enumerate(((0, 0, 1.6, 0.62), (-0.4, 0, 1.35, 0.45), (0.4, 0, 1.4, 0.48))):
        esfera(f"Copa {i+1}.{j+1}", (x + dx, y + dy, dz), r, M_VERDE_ESCURO, segmentos=16)

# Nuvens fofas passando devagar.
for i in range(6):
    nuvem = vazio(f"Nuvem {i+1}", (-5 + i * 2.2, 4.6, 4.3 + (i % 2) * 0.7))
    for j, (dx, s) in enumerate(((-0.45, 0.36), (0, 0.5), (0.45, 0.34))):
        esfera(
            f"Nuvem {i+1}.{j+1}",
            (dx, 0, 0),
            s,
            M_NUVEM,
            escala=(1, 0.55, 0.75),
            segmentos=14,
            parent=nuvem,
        )
    nuvem.location.x = -5 + i * 2.2
    nuvem.keyframe_insert("location", frame=1)
    nuvem.location.x = -3 + i * 2.2
    nuvem.keyframe_insert("location", frame=FRAMES)
    suavizar(nuvem)

# Luzes: sol quente, preenchimento frio e contorno.
def area(nome, local, cor, energia, tamanho, alvo=(0, 0, 1)):
    dados = bpy.data.lights.new(nome, type="AREA")
    dados.color = cor
    dados.energy = energia
    dados.shape = "DISK"
    dados.size = tamanho
    obj = bpy.data.objects.new(nome, dados)
    bpy.context.collection.objects.link(obj)
    obj.location = local
    olhar(obj, alvo, 1)
    obj.animation_data_clear()
    return obj


area("Sol quente", (-4, -4, 7), (1.0, 0.90, 0.75), 315, 6)
area("Preenchimento", (5, -3, 4), (0.65, 0.80, 1.0), 158, 5)
area("Contorno", (0, 4, 5), (1.0, 0.85, 0.60), 228, 4)

mundo = bpy.data.worlds.new("Mundo")
mundo.use_nodes = True
mundo.node_tree.nodes["Background"].inputs["Color"].default_value = (0.55, 0.75, 1.0, 1)
mundo.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.25
cena.world = mundo


# ---------------------------------------------------------------------------
# Personagens
# ---------------------------------------------------------------------------


def criar_crianca(tipo: str, x: float):
    """Cria menino (camiseta azul) ou menina (vestido rosa, cabelo cacheado)."""
    menino = tipo == "menino"
    pele = M_PELE if menino else M_PELE2
    cabelo = M_CAFE if menino else M_CAFE_CLARO
    root = vazio(f"Root {tipo}", (x, 0, 0))

    # Corpo.
    if menino:
        cubo(f"Camiseta {tipo}", (0, 0, 1.00), (0.66, 0.44, 0.72), M_AZUL, root)
        esfera(f"Bolinha camiseta {tipo}", (0, 0, 1.32), 0.30, M_AZUL, escala=(1, 0.8, 0.55), parent=root)
        for s in (-1, 1):
            esfera(f"Short {tipo} {s}", (s * 0.17, 0, 0.60), 0.20, M_AZUL_ESCURO, escala=(1, 1, 0.8), parent=root)
    else:
        cone(f"Vestido {tipo}", (0, 0, 0.88), 0.19, 0.46, 0.70, M_ROSA, 24, root)
        esfera(f"Bolinha vestido {tipo}", (0, 0, 1.28), 0.28, M_ROSA, escala=(1, 0.8, 0.55), parent=root)
        cilindro(f"Gola {tipo}", (0, 0, 1.25), 0.20, 0.07, M_ROSA_CLARO, 20, root)

    # Pernas e sapatos.
    for s in (-1, 1):
        px = s * (0.17 if menino else 0.14)
        cilindro(f"Perna {tipo} {s}", (px, 0, 0.35), 0.072, 0.48, pele, 12, root)
        esfera(
            f"Sapato {tipo} {s}",
            (px, -0.07, 0.09),
            0.12,
            M_AZUL_ESCURO if menino else M_ROSA_CLARO,
            escala=(1, 1.5, 0.55),
            segmentos=14,
            parent=root,
        )

    # Bracos (cilindros animados) e maos.
    bracos, maos = {}, {}
    for s, nome in ((-1, "esq"), (1, "dir")):
        braco = cilindro(f"Braco {tipo} {nome}", (s * 0.36, 0, 1.0), 0.072, 1, pele, 12, root)
        mao = esfera(f"Mao {tipo} {nome}", (s * 0.44, -0.12, 0.82), 0.095, pele, segmentos=14, parent=root)
        bracos[nome], maos[nome] = braco, mao
        ligar(braco, (s * 0.30, 0, 1.17), (s * 0.44, -0.12, 0.82), 1)

    # Cabeca e rosto.
    cabeca = esfera(f"Cabeca {tipo}", (0, 0, 1.62), 0.42, pele, escala=(1, 0.92, 1.03), segmentos=28, parent=root)
    olhos, pupilas, sobrancelhas = [], [], []
    for s in (-1, 1):
        olho = esfera(f"Olho {tipo} {s}", (s * 0.17, -0.355, 1.66), 0.115, M_BRANCO, escala=(1, 0.62, 1.15), segmentos=18, parent=root)
        pupila = esfera(f"Pupila {tipo} {s}", (s * 0.17, -0.425, 1.66), 0.058, M_PRETO, escala=(1, 0.7, 1), segmentos=16, parent=root)
        esfera(f"Brilho olho {tipo} {s}", (s * 0.17 - 0.02, -0.47, 1.69), 0.020, M_BRANCO, segmentos=10, parent=root)
        sobrancelha = cubo(f"Sobrancelha {tipo} {s}", (s * 0.17, -0.39, 1.83), (0.15, 0.025, 0.030), cabelo, root)
        esfera(f"Bochecha {tipo} {s}", (s * 0.30, -0.335, 1.51), 0.075, M_BOCHECHA, escala=(1, 0.35, 0.7), segmentos=12, parent=root)
        olhos.append(olho)
        pupilas.append(pupila)
        sobrancelhas.append(sobrancelha)
    esfera(f"Nariz {tipo}", (0, -0.42, 1.55), 0.045, pele, segmentos=12, parent=root)
    boca = esfera(f"Boca {tipo}", (0, -0.395, 1.40), 0.055, M_BOCINHA, escala=(1.4, 0.35, 0.55), segmentos=14, parent=root)

    # Cabelo.
    esfera(f"Cabelo topo {tipo}", (0, 0.02, 1.94), 0.43, cabelo, escala=(1.02, 0.96, 0.48), segmentos=24, parent=root)
    if menino:
        for i, (dx, rz) in enumerate(((-0.18, 0.5), (0.02, 0.1), (0.20, -0.5))):
            tufo = cone(f"Tufo {tipo} {i+1}", (dx, -0.18, 2.10), 0.0, 0.11, 0.24, cabelo, 10, root)
            tufo.rotation_euler[1] = rz * 0.4
        esfera(f"Franja {tipo}", (0, -0.32, 1.96), 0.17, cabelo, escala=(1.4, 0.7, 0.5), segmentos=14, parent=root)
    else:
        for i in range(14):
            a = 2 * math.pi * i / 14
            r = 0.40 if i % 2 == 0 else 0.44
            esfera(
                f"Cacho {tipo} {i+1}",
                (r * math.cos(a), r * math.sin(a) * 0.92, 1.86 + 0.10 * math.sin(3 * a)),
                random.uniform(0.13, 0.17),
                cabelo,
                segmentos=12,
                parent=root,
            )
        for i in range(5):
            esfera(
                f"Franja cacheada {tipo} {i+1}",
                (-0.32 + i * 0.16, -0.33, 1.92 + 0.04 * (i % 2)),
                0.12,
                cabelo,
                segmentos=12,
                parent=root,
            )

    return {
        "root": root,
        "cabeca": cabeca,
        "olhos": olhos,
        "pupilas": pupilas,
        "sobrancelhas": sobrancelhas,
        "boca": boca,
        "bracos": bracos,
        "maos": maos,
        "tipo": tipo,
    }


menino = criar_crianca("menino", -0.78)
menina = criar_crianca("menina", 2.6)
menina["root"].location.y = -0.10


def expressao(personagem, frame, olho=1.0, boca=(1.4, 0.35, 0.55), sobrancelha=0.0):
    for olho_obj, pupila in zip(personagem["olhos"], personagem["pupilas"]):
        olho_obj.scale = (1.0 * olho, 0.62 * olho, 1.15 * olho)
        olho_obj.keyframe_insert("scale", frame=frame)
        pupila.scale = (1.0 * olho, 0.7 * olho, 1.0 * olho)
        pupila.keyframe_insert("scale", frame=frame)
    personagem["boca"].scale = boca
    personagem["boca"].keyframe_insert("scale", frame=frame)
    for sobra in personagem["sobrancelhas"]:
        sobra.location.z = 1.83 + sobrancelha
        sobra.keyframe_insert("location", frame=frame)


def piscar(personagem, frame):
    for olho_obj, pupila in zip(personagem["olhos"], personagem["pupilas"]):
        olho_obj.scale = (1, 0.06, 1.15)
        olho_obj.keyframe_insert("scale", frame=frame)
        pupila.scale = (1, 0.06, 1)
        pupila.keyframe_insert("scale", frame=frame)
        olho_obj.scale = (1, 0.62, 1.15)
        olho_obj.keyframe_insert("scale", frame=frame + 3)
        pupila.scale = (1, 0.7, 1)
        pupila.keyframe_insert("scale", frame=frame + 3)


# ---------------------------------------------------------------------------
# Estrela cadente
# ---------------------------------------------------------------------------


def criar_estrela(nome, raio=0.19, espessura=0.055):
    pontos = []
    for i in range(10):
        a = math.pi / 2 + i * math.pi / 5
        r = raio if i % 2 == 0 else raio * 0.44
        pontos.append((r * math.cos(a), r * math.sin(a)))
    verts = [(x, y, espessura) for x, y in pontos] + [(x, y, -espessura) for x, y in pontos]
    faces = [tuple(range(10)), tuple(range(19, 9, -1))]
    for i in range(10):
        j = (i + 1) % 10
        faces.append((i, j, j + 10, i + 10))
    malha = bpy.data.meshes.new(nome)
    malha.from_pydata(verts, [], faces)
    malha.update()
    obj = bpy.data.objects.new(nome, malha)
    bpy.context.collection.objects.link(obj)
    obj.rotation_euler[0] = math.pi / 2
    return obj


estrela = criar_estrela("Estrela magica")
estrela.location = (0, -0.15, 0.34)
estrela.data.materials.append(M_AMARELO)

# Halo da estrela: esferas brilhantes que crescem com a magia.
halos = []
for i, (mat, r) in enumerate(
    [
        (material(f"Halo {i}", c, 2.2, True), s)
        for i, (c, s) in enumerate(
            [((1.0, 0.92, 0.45), 0.26), ((1.0, 0.75, 0.30), 0.42), ((1.0, 0.95, 0.75), 0.60)]
        )
    ]
):
    halo = esfera(f"Halo estrela {i+1}", (0, -0.12, 0.34), r, mat, escala=(1, 0.4, 1), segmentos=16)
    halos.append(halo)

# Particulas magicas que so surgem no pedido (10-15s).
particulas = []
CORES_MAGIA = [(1.0, 0.92, 0.40), (1.0, 0.55, 0.80), (0.55, 0.90, 1.0), (0.85, 0.65, 1.0)]
for i in range(56):
    mat = material(f"Particula {i}", CORES_MAGIA[i % len(CORES_MAGIA)], 2.4, True)
    obj = esfera(f"Particula {i+1}", (0, 0, -5), random.uniform(0.018, 0.042), mat, segmentos=8)
    a0 = random.uniform(0, 2 * math.pi)
    r0 = random.uniform(0.20, 0.85)
    z0 = random.uniform(0.35, 1.25)
    for frame, esp, sobe in ((1, 0.2, 0), (239, 0.2, 0), (q(10), 0.7, 0.0), (q(12.5), 1.35, 0.7), (q(15), 1.8, 1.3), (FRAMES, 2.4, 3.2)):
        a = a0 + frame / FRAMES * 7.0
        obj.location = (r0 * esp * math.cos(a), -0.15 + r0 * esp * math.sin(a) * 0.45, z0 + sobe)
        obj.keyframe_insert("location", frame=frame)
    escala_em(obj, [0.001, 0.001, 1.0, 1.3, 1.0, 0.55], [1, 239, q(10), q(12.5), q(15), FRAMES])
    particulas.append(obj)


# ---------------------------------------------------------------------------
# Arco-iris (surge aos 15s)
# ---------------------------------------------------------------------------

grupo_arco = vazio("Grupo arco-iris", (0, 1.6, 0.8))
CORES_ARCO = [
    (1.0, 0.25, 0.28),
    (1.0, 0.55, 0.18),
    (1.0, 0.90, 0.22),
    (0.35, 0.88, 0.42),
    (0.22, 0.62, 1.0),
    (0.35, 0.32, 0.90),
    (0.78, 0.36, 0.92),
]
arcos = []
for i, cor in enumerate(CORES_ARCO):
    raio = 1.85 + i * 0.22
    curva = bpy.data.curves.new(f"Curva arco {i+1}", "CURVE")
    curva.dimensions = "3D"
    curva.resolution_u = 2
    curva.bevel_depth = 0.055
    curva.bevel_resolution = 4
    spline = curva.splines.new("POLY")
    n = 48
    spline.points.add(n - 1)
    for j, ponto in enumerate(spline.points):
        t = math.pi * j / (n - 1)
        ponto.co = (raio * math.cos(t), 0, raio * math.sin(t), 1)
    obj = bpy.data.objects.new(f"Arco {i+1}", curva)
    bpy.context.collection.objects.link(obj)
    obj.parent = grupo_arco
    obj.data.materials.append(material(f"Cor arco {i+1}", cor, 1.5, True))
    arcos.append(obj)

escala_em(grupo_arco, [0.001, 0.001, 1.06, 1.0], [1, q(14.8), q(16.6), FRAMES])

# Coracoes subindo no final: simbolo de compartilhar amor.
for i in range(9):
    coracao = vazio(f"Coracao {i+1}", (random.uniform(-1.4, 1.4), -0.4, 0.9))
    mat = material(f"Cor {i+1}", (1.0, 0.35 + 0.05 * (i % 3), 0.62), 1.8, True)
    esfera(f"Coracao {i+1} A", (-0.075, 0, 0.07), 0.085, mat, segmentos=12, parent=coracao)
    esfera(f"Coracao {i+1} B", (0.075, 0, 0.07), 0.085, mat, segmentos=12, parent=coracao)
    cone(f"Coracao {i+1} C", (0, 0, -0.04), 0.0, 0.115, 0.17, mat, 12, coracao)
    coracao.rotation_euler[2] = math.pi
    x0, z0 = coracao.location.x, coracao.location.z
    for frame, s, z in ((1, 0.001, z0), (q(15), 0.001, z0), (q(17), 1.0, z0 + 0.5), (FRAMES, 0.6, z0 + 2.4)):
        coracao.scale = (s, s, s)
        coracao.location = (x0 + 0.12 * math.sin(frame / 20 + i), -0.4, z)
        coracao.keyframe_insert("scale", frame=frame)
        coracao.keyframe_insert("location", frame=frame)


# ---------------------------------------------------------------------------
# Animacao dos personagens
# ---------------------------------------------------------------------------

# Menino: curvado procurando -> surpresa -> interesse -> pedido -> sorriso.
menino["root"].location = (-0.78, -0.10, -0.18)
menino["root"].keyframe_insert("location", frame=1)
menino["root"].location = (-0.78, -0.10, -0.18)
menino["root"].keyframe_insert("location", frame=q(1.5))
menino["root"].location = (-0.72, -0.10, 0.0)
menino["root"].keyframe_insert("location", frame=q(4.5))
menino["root"].location = (-0.66, -0.10, 0.0)
menino["root"].keyframe_insert("location", frame=q(10))
menino["root"].location = (-0.52, -0.10, 0.0)
menino["root"].keyframe_insert("location", frame=q(15))
suavizar(menino["root"])

for t, rx in ((0, 0.28), (1.8, 0.28), (3.2, -0.04), (4.6, 0.0), (10, 0.0), (12.5, -0.10), (15, -0.16), (20, -0.12)):
    menino["cabeca"].rotation_euler[0] = rx
    menino["cabeca"].keyframe_insert("rotation_euler", frame=q(t))
suavizar(menino["cabeca"], "rotation_euler")

expressao(menino, 1, 0.85, (1.4, 0.35, 0.55))
expressao(menino, q(2.4), 0.85, (1.4, 0.35, 0.55))
expressao(menino, q(3.3), 1.45, (0.72, 0.72, 0.72), 0.07)
expressao(menino, q(5.0), 1.30, (0.85, 0.60, 0.65), 0.05)
expressao(menino, q(9.5), 1.05, (1.30, 0.34, 0.55))
expressao(menino, q(12.5), 1.20, (0.80, 0.70, 0.70), 0.06)
expressao(menino, q(15.5), 1.10, (1.55, 0.30, 0.50))
expressao(menino, FRAMES, 1.05, (1.55, 0.30, 0.50), -0.02)
piscar(menino, q(7.2))
piscar(menino, q(18.0))

# Bracos do menino: apontando para a estrela -> maos juntas -> celebracao.
estados_menino = {
    "esq": [
        (q(0), (-0.30, 0, 1.17), (-0.52, -0.32, 0.62)),
        (q(3.3), (-0.30, 0, 1.17), (-0.55, -0.38, 1.38)),
        (q(9.5), (-0.30, 0, 1.17), (-0.50, -0.14, 0.86)),
        (q(12.5), (-0.30, 0, 1.17), (-0.04, -0.30, 1.02)),
        (q(15.2), (-0.30, 0, 1.17), (-0.20, -0.35, 1.30)),
        (FRAMES, (-0.30, 0, 1.17), (-0.48, -0.32, 1.72)),
    ],
    "dir": [
        (q(0), (0.30, 0, 1.17), (0.48, -0.25, 0.72)),
        (q(3.3), (0.30, 0, 1.17), (0.38, -0.45, 1.12)),
        (q(9.5), (0.30, 0, 1.17), (0.30, -0.20, 0.90)),
        (q(12.5), (0.30, 0, 1.17), (0.02, -0.30, 1.02)),
        (q(15.2), (0.30, 0, 1.17), (0.20, -0.35, 1.30)),
        (FRAMES, (0.30, 0, 1.17), (0.48, -0.32, 1.72)),
    ],
}
for nome, quadros in estados_menino.items():
    braco, mao = menino["bracos"][nome], menino["maos"][nome]
    for frame, ombro, mao_pos in quadros:
        ligar(braco, ombro, mao_pos, frame)
        mao.location = mao_pos
        mao.keyframe_insert("location", frame=frame)
    suavizar(braco, "location")
    suavizar(mao)

# Menina: entra pela direita, pergunta, junta a mao, sorri.
for frame, x in ((1, 2.6), (q(4.6), 2.6), (q(7.0), 0.82), (q(10), 0.72), (q(12.5), 0.50), (q(15), 0.46), (FRAMES, 0.46)):
    menina["root"].location = (x, -0.10, 0.0)
    menina["root"].keyframe_insert("location", frame=frame)
suavizar(menina["root"])

for t, rx in ((0, 0), (5.2, 0), (7.5, -0.06), (10, 0.02), (12.5, -0.12), (15, -0.18), (20, -0.14)):
    menina["cabeca"].rotation_euler[0] = rx
    menina["cabeca"].keyframe_insert("rotation_euler", frame=q(t))
suavizar(menina["cabeca"], "rotation_euler")

expressao(menina, 1, 1.0)
expressao(menina, q(5.2), 1.0)
expressao(menina, q(7.2), 1.15, (0.85, 0.55, 0.65), 0.04)
expressao(menina, q(9.8), 1.05, (1.35, 0.32, 0.55))
expressao(menina, q(12.5), 1.20, (0.80, 0.70, 0.70), 0.06)
expressao(menina, q(15.5), 1.12, (1.55, 0.30, 0.50))
expressao(menina, FRAMES, 1.05, (1.60, 0.30, 0.50), -0.02)
piscar(menina, q(8.8))
piscar(menina, q(18.6))

estados_menina = {
    "esq": [
        (q(0), (-0.30, 0, 1.17), (-0.44, -0.12, 0.82)),
        (q(7.2), (-0.30, 0, 1.17), (-0.48, -0.34, 1.12)),
        (q(10), (-0.30, 0, 1.17), (-0.36, -0.20, 0.88)),
        (q(12.5), (-0.30, 0, 1.17), (-0.02, -0.30, 1.02)),
        (q(15.2), (-0.30, 0, 1.17), (0.20, -0.35, 1.30)),
        (FRAMES, (-0.30, 0, 1.17), (0.48, -0.32, 1.72)),
    ],
    "dir": [
        (q(0), (0.30, 0, 1.17), (0.44, -0.12, 0.82)),
        (q(7.2), (0.30, 0, 1.17), (0.40, -0.14, 0.90)),
        (q(12.5), (0.30, 0, 1.17), (0.34, -0.18, 0.92)),
        (q(15.2), (0.30, 0, 1.17), (0.20, -0.35, 1.42)),
        (FRAMES, (0.30, 0, 1.17), (0.48, -0.32, 1.72)),
    ],
}
for nome, quadros in estados_menina.items():
    braco, mao = menina["bracos"][nome], menina["maos"][nome]
    for frame, ombro, mao_pos in quadros:
        ligar(braco, ombro, mao_pos, frame)
        mao.location = mao_pos
        mao.keyframe_insert("location", frame=frame)
    suavizar(braco, "location")
    suavizar(mao)


# ---------------------------------------------------------------------------
# Estrela: pulso, pedido e subida ao ceu
# ---------------------------------------------------------------------------

for t, r, z, rz in (
    (0, 0.30, 0.55, 0.0),
    (2.4, 0.40, 0.60, 0.20),
    (9.8, 0.42, 0.62, 0.5),
    (11.0, 0.72, 0.66, 1.8),
    (13.0, 1.05, 0.74, 3.6),
    (15.0, 1.30, 0.92, 5.0),
    (16.5, 1.15, 1.70, 5.6),
    (18.5, 1.00, 2.70, 6.2),
    (20.0, 0.90, 3.45, 6.8),
):
    estrela.scale = (r, r, r)
    estrela.location = (0.05 * math.sin(z), -0.15, z)
    estrela.rotation_euler[2] = rz
    estrela.keyframe_insert("scale", frame=q(t))
    estrela.keyframe_insert("location", frame=q(t))
    estrela.keyframe_insert("rotation_euler", frame=q(t))
suavizar(estrela, "scale")
suavizar(estrela, "location")

for i, halo in enumerate(halos):
    for t, fator in ((0, 0.3), (9.8, 0.4), (11.5, 1.0), (13.5, 1.9), (15, 2.3), (17, 1.8), (20, 1.4)):
        f = fator * (1 - i * 0.18)
        halo.scale = (f, 0.4 * f, f)
        halo.keyframe_insert("scale", frame=q(t))
    halo.location.z = 0.34
    halo.keyframe_insert("location", frame=1)
    halo.location.z = 3.45
    halo.keyframe_insert("location", frame=FRAMES)
    suavizar(halo, "scale")
    suavizar(halo, "location")


# ---------------------------------------------------------------------------
# Camera com cortes suaves entre as cenas
# ---------------------------------------------------------------------------

dados_camera = bpy.data.cameras.new("Camera historia")
dados_camera.lens = 48
camera = bpy.data.objects.new("Camera historia", dados_camera)
bpy.context.collection.objects.link(camera)
cena.camera = camera

planos_camera = [
    (1, (0.15, -3.15, 1.30), (-0.65, 0, 1.05), 52),   # cena 1: menino e estrela
    (q(4.8), (-0.05, -3.60, 1.45), (-0.55, 0, 1.20), 48),
    (q(7.2), (0.05, -4.45, 1.55), (0.05, 0, 1.20), 44),  # cena 2: os dois
    (q(10.0), (0.0, -3.05, 1.30), (0.0, 0, 1.05), 50),   # cena 3: maos juntas
    (q(14.8), (0.0, -3.40, 1.45), (0.0, 0, 1.20), 46),
    (q(16.2), (0.0, -6.40, 2.20), (0.0, 0.4, 2.00), 34),  # cena 4: arco-iris
    (FRAMES, (0.0, -6.80, 2.35), (0.0, 0.6, 2.20), 33),
]
for frame, pos, alvo, lente in planos_camera:
    camera.location = pos
    camera.keyframe_insert("location", frame=frame)
    olhar(camera, alvo, frame)
    dados_camera.lens = lente
    dados_camera.keyframe_insert("lens", frame=frame)
suavizar(camera, "location")
suavizar(camera, "rotation_euler")


# ---------------------------------------------------------------------------
# Salvar e renderizar
# ---------------------------------------------------------------------------

blend_path = os.path.join(OUTPUT_DIR, "historia_da_estrela.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(f"Cena salva: {blend_path}")
print(f"Video: {CAMINHO_SAIDA} ({DURACAO:g}s, {LARGURA}x{ALTURA}, {FPS} fps)")

if RENDER:
    print("Renderizando historia da estrela...")
    bpy.ops.render.render(animation=True)
    print(f"Video pronto: {cena.render.filepath}")
else:
    print("Render pulado (--no-render).")
