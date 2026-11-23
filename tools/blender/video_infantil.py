"""Cria um video de animacao infantil a partir de uma foto, local e sem custo.

A foto e o elemento principal: aparece com moldura colorida, baloes subindo,
nuvens passando, estrelas piscando e confete caindo. Tudo renderizado no
Blender (Eevee), compativel com GPU AMD, sem CUDA e sem API paga.

Uso:
    blender -b -t 4 --python tools/blender/video_infantil.py -- \
        --image "C:/caminho/foto.jpg" --titulo "Papai & eu"

Opcoes (depois de ``--``):
    --image CAMINHO        foto de origem (obrigatoria)
    --titulo TEXTO         texto exibido no topo (padrao: "Papai & eu")
    --duration SEGUNDOS    duracao (padrao: 10)
    --width PX             largura (padrao: 1080)
    --height PX            altura (padrao: 1920)
    --output CAMINHO       arquivo de saida .mp4 (padrao: output/infantil_<nome>.mp4)
    --no-render            salva apenas o .blend

Saida: arquivo .mp4 (H.264) na pasta output/ ao lado deste script.
"""

from __future__ import annotations

import math
import os
import random
import sys

import bpy


# ---------------------------------------------------------------------------
# Argumentos
# ---------------------------------------------------------------------------

ARGS = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []


def arg(nome: str, padrao):
    if nome in ARGS:
        i = ARGS.index(nome)
        if i + 1 < len(ARGS):
            return ARGS[i + 1]
    return padrao


OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
os.makedirs(OUTPUT_DIR, exist_ok=True)

IMAGE_PATH = str(arg("--image", "")).strip()
if IMAGE_PATH:
    IMAGE_PATH = os.path.abspath(os.path.expanduser(IMAGE_PATH))
if not IMAGE_PATH or not os.path.isfile(IMAGE_PATH):
    raise SystemExit("ERRO: informe --image com o caminho de uma imagem valida.")

TITULO = str(arg("--titulo", "Papai & eu"))
DURACAO = float(arg("--duration", 10))
LARGURA = int(arg("--width", 1080))
ALTURA = int(arg("--height", 1920))
RENDER = "--no-render" not in ARGS
FPS = 24
FRAMES = max(FPS, int(FPS * DURACAO))
random.seed(42)

NOME_BASE = "infantil_" + os.path.splitext(os.path.basename(IMAGE_PATH))[0]
NOME_BASE = "".join(c if c.isalnum() or c in "-_" else "_" for c in NOME_BASE)
CAMINHO_SAIDA = str(arg("--output", os.path.join(OUTPUT_DIR, NOME_BASE + ".mp4")))

ORTO_ALTURA = 6.0
ORTO_LARGURA = ORTO_ALTURA * (LARGURA / ALTURA)


# ---------------------------------------------------------------------------
# Cena e render
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
cena.render.film_transparent = False
try:
    cena.view_settings.view_transform = "Standard"
except TypeError:
    pass

cena.render.image_settings.file_format = "FFMPEG"
cena.render.image_settings.color_mode = "RGB"
cena.render.ffmpeg.format = "MPEG4"
cena.render.ffmpeg.codec = "H264"
cena.render.ffmpeg.constant_rate_factor = "MEDIUM"
cena.render.ffmpeg.ffmpeg_preset = "GOOD"
cena.render.filepath = CAMINHO_SAIDA


# ---------------------------------------------------------------------------
# Utilitarios
# ---------------------------------------------------------------------------


def material(nome: str, cor, emissivo: bool = False):
    mat = bpy.data.materials.new(nome)
    mat.diffuse_color = (*cor, 1.0)
    mat.use_nodes = True
    nos = mat.node_tree.nodes
    nos.clear()
    if emissivo:
        emissao = nos.new("ShaderNodeEmission")
        emissao.inputs["Color"].default_value = (*cor, 1.0)
        emissao.inputs["Strength"].default_value = 1.0
        saida = nos.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(emissao.outputs["Emission"], saida.inputs["Surface"])
    else:
        bsdf = nos.new("ShaderNodeBsdfPrincipled")
        bsdf.inputs["Base Color"].default_value = (*cor, 1.0)
        bsdf.inputs["Roughness"].default_value = 0.5
        saida = nos.new("ShaderNodeOutputMaterial")
        mat.node_tree.links.new(bsdf.outputs["BSDF"], saida.inputs["Surface"])
    return mat


def quadro(t: float) -> int:
    return max(1, min(FRAMES, round(1 + t * (FRAMES - 1))))


def suavizar(obj, caminho: str = "location"):
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


def cubo(nome, localizacao, escala, mat):
    bpy.ops.mesh.primitive_cube_add(location=localizacao)
    obj = bpy.context.object
    obj.name = nome
    obj.scale = escala
    obj.data.materials.append(mat)
    return obj


def esfera(nome, localizacao, raio, mat, escala=None, segmentos=16):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segmentos, ring_count=8, radius=raio, location=localizacao
    )
    obj = bpy.context.object
    obj.name = nome
    if escala:
        obj.scale = escala
    obj.data.materials.append(mat)
    return obj


# ---------------------------------------------------------------------------
# Cores infantis
# ---------------------------------------------------------------------------

AZUL = (0.36, 0.76, 0.96)
AMARELO = (1.0, 0.84, 0.24)
ROSA = (1.0, 0.45, 0.60)
VERDE = (0.35, 0.85, 0.50)
LARANJA = (1.0, 0.58, 0.24)
ROXO = (0.72, 0.46, 0.95)
BRANCO = (1.0, 1.0, 1.0)

M_FUNDO = material("Ceu azul", AZUL, emissivo=True)
M_BRANCO = material("Branco nuvem", BRANCO, emissivo=True)
M_ESTRELA = material("Estrela", AMARELO, emissivo=True)
M_MOLDURA = material("Moldura", AMARELO, emissivo=True)
M_CORDA = material("Corda balao", (0.9, 0.9, 0.9), emissivo=True)
CORES_BALAO = [ROSA, VERDE, LARANJA, ROXO, AMARELO]
CORES_CONFETE = [ROSA, VERDE, LARANJA, ROXO, AMARELO, AZUL]
M_BALOES = [material(f"Balao {i}", c) for i, c in enumerate(CORES_BALAO)]
M_CONFETE = [material(f"Confete {i}", c, emissivo=True) for i, c in enumerate(CORES_CONFETE)]


# ---------------------------------------------------------------------------
# Fundo cenario
# ---------------------------------------------------------------------------

cubo("Ceu", (0, 1.2, 0), (ORTO_LARGURA, 0.05, ORTO_ALTURA), M_FUNDO)

# Nuvens fofas (3 esferas por nuvem), atravessando a tela lateralmente.
for nuvem_i in range(4):
    x0 = -ORTO_LARGURA - 1.2 + nuvem_i * (ORTO_LARGURA * 0.7)
    z0 = 2.2 + (nuvem_i % 2) * 0.45
    nuvem = bpy.data.objects.new(f"Nuvem {nuvem_i+1}", None)
    bpy.context.collection.objects.link(nuvem)
    nuvem.location = (x0, 0.5, z0)
    for parte, (dx, dz, s) in enumerate(((-0.32, 0.0, 0.34), (0.0, 0.12, 0.44), (0.34, 0.0, 0.30))):
        pedaco = esfera(
            f"Nuvem {nuvem_i+1} parte {parte+1}",
            (dx, 0, dz),
            s,
            M_BRANCO,
            escala=(1.0, 0.5, 0.75),
        )
        pedaco.parent = nuvem
    nuvem.location.x = x0
    nuvem.keyframe_insert(data_path="location", frame=1)
    nuvem.location.x = ORTO_LARGURA + 1.2
    nuvem.keyframe_insert(data_path="location", frame=FRAMES)
    suavizar(nuvem)


# ---------------------------------------------------------------------------
# Foto protagonista com moldura
# ---------------------------------------------------------------------------

imagem = bpy.data.images.load(IMAGE_PATH, check_existing=True)
try:
    imagem.pack()
except Exception:
    pass

prop_foto = imagem.size[0] / max(1, imagem.size[1])
altura_foto = ORTO_ALTURA * 0.56
largura_foto = altura_foto * prop_foto
largura_max = ORTO_LARGURA * 0.86
if largura_foto > largura_max:
    largura_foto = largura_max
    altura_foto = largura_foto / prop_foto

moldura = cubo(
    "Moldura colorida",
    (0, 0.10, -0.15),
    (largura_foto / 2 + 0.10, 0.03, altura_foto / 2 + 0.10),
    M_MOLDURA,
)

mat_foto = bpy.data.materials.new("Foto")
mat_foto.use_nodes = True
nos = mat_foto.node_tree.nodes
nos.clear()
tex = nos.new("ShaderNodeTexImage")
tex.image = imagem
tex.extension = "EXTEND"
emissao_foto = nos.new("ShaderNodeEmission")
emissao_foto.inputs["Strength"].default_value = 1.0
saida_foto = nos.new("ShaderNodeOutputMaterial")
mat_foto.node_tree.links.new(tex.outputs["Color"], emissao_foto.inputs["Color"])
mat_foto.node_tree.links.new(emissao_foto.outputs["Emission"], saida_foto.inputs["Surface"])

bpy.ops.mesh.primitive_plane_add(size=2, location=(0, 0.0, -0.15))
foto = bpy.context.object
foto.name = "Foto protagonista"
foto.rotation_euler = (math.pi / 2, 0, 0)
foto.scale = (largura_foto / 2, altura_foto / 2, 1.0)
foto.data.materials.append(mat_foto)

# Entrada animada: a foto "salta" e cresce suavemente.
conjunto = bpy.data.objects.new("Conjunto foto", None)
bpy.context.collection.objects.link(conjunto)
conjunto.location = (0, 0, 0)
foto.parent = conjunto
moldura.parent = conjunto
for t, escala, rz in ((0.00, 0.55, -0.10), (0.12, 1.06, 0.03), (0.20, 1.0, 0.0), (1.00, 1.0, 0.0)):
    conjunto.scale = (escala, escala, escala)
    conjunto.rotation_euler[2] = rz
    conjunto.keyframe_insert(data_path="scale", frame=quadro(t))
    conjunto.keyframe_insert(data_path="rotation_euler", frame=quadro(t))
suavizar(conjunto, "scale")
suavizar(conjunto, "rotation_euler")


# ---------------------------------------------------------------------------
# Titulo em pt-BR
# ---------------------------------------------------------------------------

dados_texto = bpy.data.curves.new("Titulo", type="FONT")
dados_texto.body = TITULO
dados_texto.align_x = "CENTER"
dados_texto.align_y = "CENTER"
dados_texto.size = 0.52
dados_texto.extrude = 0.02
titulo = bpy.data.objects.new("Titulo", dados_texto)
bpy.context.collection.objects.link(titulo)
titulo.location = (0, -0.35, ORTO_ALTURA / 2 - 0.55)
titulo.rotation_euler = (math.pi / 2, 0, 0)
titulo.data.materials.append(material("Titulo amarelo", AMARELO, emissivo=True))
for t, escala in ((0.0, 0.4), (0.18, 1.12), (0.26, 1.0), (1.0, 1.0)):
    titulo.scale = (escala, escala, escala)
    titulo.keyframe_insert(data_path="scale", frame=quadro(t))
suavizar(titulo, "scale")


# ---------------------------------------------------------------------------
# Baloes subindo
# ---------------------------------------------------------------------------

for i in range(7):
    cor = CORES_BALAO[i % len(CORES_BALAO)]
    mat = M_BALOES[i % len(M_BALOES)]
    x = -ORTO_LARGURA / 2 + 0.25 + i * (ORTO_LARGURA - 0.5) / 6
    x += random.uniform(-0.12, 0.12)
    y = -0.8 - (i % 3) * 0.15
    balao = bpy.data.objects.new(f"Balao {i+1}", None)
    bpy.context.collection.objects.link(balao)
    balao.location = (x, y, -ORTO_ALTURA / 2 - 0.8)

    globo = esfera(f"Balao {i+1} globo", (0, 0, 0), 0.20, mat, escala=(1.0, 0.85, 1.15))
    globo.parent = balao
    corda = cubo(f"Balao {i+1} corda", (0, 0, -0.36), (0.006, 0.006, 0.20), M_CORDA)
    corda.parent = balao

    balao.location.z = -ORTO_ALTURA / 2 - 0.8
    balao.keyframe_insert(data_path="location", frame=1)
    balao.location.z = ORTO_ALTURA / 2 + 0.9
    balao.keyframe_insert(data_path="location", frame=FRAMES)
    suavizar(balao)


# ---------------------------------------------------------------------------
# Estrelas piscando
# ---------------------------------------------------------------------------

for i in range(12):
    x = random.uniform(-ORTO_LARGURA / 2 + 0.1, ORTO_LARGURA / 2 - 0.1)
    z = random.uniform(-ORTO_ALTURA / 2 + 0.2, ORTO_ALTURA / 2 - 0.2)
    estrela = esfera(f"Estrela {i+1}", (x, 0.35, z), 0.055, M_ESTRELA, segmentos=8)
    for t in (0.0, 0.25, 0.5, 0.75, 1.0):
        s = 1.0 if random.random() > 0.4 else 0.35
        estrela.scale = (s, s, s)
        estrela.keyframe_insert(data_path="scale", frame=quadro(t))
    suavizar(estrela, "scale")


# ---------------------------------------------------------------------------
# Confete caindo
# ---------------------------------------------------------------------------

for i in range(26):
    mat = M_CONFETE[i % len(M_CONFETE)]
    x = random.uniform(-ORTO_LARGURA / 2, ORTO_LARGURA / 2)
    z0 = random.uniform(ORTO_ALTURA / 2, ORTO_ALTURA / 2 + 1.5)
    peca = cubo(
        f"Confete {i+1}",
        (x, -0.6 - (i % 4) * 0.05, z0),
        (0.035, 0.006, 0.075),
        mat,
    )
    peca.location.z = z0
    peca.rotation_euler[2] = random.uniform(0, math.pi)
    peca.keyframe_insert(data_path="location", frame=1)
    peca.keyframe_insert(data_path="rotation_euler", frame=1)
    peca.location.z = -ORTO_ALTURA / 2 - 1.0
    peca.rotation_euler[2] += random.uniform(2, 6)
    peca.keyframe_insert(data_path="location", frame=FRAMES)
    peca.keyframe_insert(data_path="rotation_euler", frame=FRAMES)
    suavizar(peca, "location")
    suavizar(peca, "rotation_euler")


# ---------------------------------------------------------------------------
# Camera (ortografica, enquadramento vertical)
# ---------------------------------------------------------------------------

dados_camera = bpy.data.cameras.new("Camera infantil")
dados_camera.type = "ORTHO"
dados_camera.ortho_scale = ORTO_ALTURA
camera = bpy.data.objects.new("Camera infantil", dados_camera)
bpy.context.collection.objects.link(camera)
camera.location = (0, -8, 0)
camera.rotation_euler = (math.pi / 2, 0, 0)
cena.camera = camera

# Leve balanco da camera para dar vida ao video.
for t, x, z in ((0.0, 0.0, 0.0), (0.25, 0.06, 0.03), (0.5, 0.0, -0.02), (0.75, -0.06, 0.03), (1.0, 0.0, 0.0)):
    camera.location.x = x
    camera.location.z = z
    camera.keyframe_insert(data_path="location", frame=quadro(t))
suavizar(camera)


# ---------------------------------------------------------------------------
# Salvar e renderizar
# ---------------------------------------------------------------------------

blend_path = os.path.join(OUTPUT_DIR, NOME_BASE + ".blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(f"Cena salva: {blend_path}")
print(f"Foto: {IMAGE_PATH} ({imagem.size[0]}x{imagem.size[1]})")
print(f"Video: {CAMINHO_SAIDA} ({DURACAO:g}s, {LARGURA}x{ALTURA}, {FPS} fps)")

if RENDER:
    print("Renderizando animacao infantil...")
    bpy.ops.render.render(animation=True)
    print(f"Video pronto: {cena.render.filepath}")
else:
    print("Render pulado (--no-render).")
