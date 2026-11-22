"""Instrução de idioma compartilhada pelos provedores de geração (pt-BR).

Os modelos recebem prompts escritos pelo usuário em português, mas isso não
garante que legendas, letreiros ou qualquer texto gerado dentro da mídia também
venham em português do Brasil. Esta camada acrescenta a instrução explicitamente
a todo prompt enviado à OpenAI e à fal.ai.
"""

from __future__ import annotations

INSTRUCAO_PT_BR = (
    "Idioma: português do Brasil (pt-BR). "
    "Use português do Brasil em todo texto visível, incluindo legendas e letreiros."
)


def _juntar(*partes: str | None) -> str:
    """Junta partes não vazias com ponto, sem produzir pontuação duplicada."""
    limpas = [parte.strip().rstrip(".") for parte in partes if parte and parte.strip()]
    return ". ".join(limpas)


def compor_prompt_imagem(prompt: str, style: str | None = None) -> str:
    """Prompt de imagem com estilo opcional e instrução explícita de pt-BR."""
    base = _juntar(prompt, f"Estilo: {style}" if style else "")
    return f"{base}. {INSTRUCAO_PT_BR}" if base else INSTRUCAO_PT_BR


def compor_prompt_video(prompt: str | None, motion: str | None = None) -> str:
    """Prompt de vídeo com movimento opcional e instrução explícita de pt-BR.

    Sem prompt e sem movimento, devolve string vazia para preservar o
    comportamento anterior dos modelos que recebem apenas a imagem de origem.
    """
    movimento = f"Movimento: {motion.strip()}" if motion and motion.strip() else ""
    base = _juntar(prompt or "", movimento)
    return f"{base}. {INSTRUCAO_PT_BR}" if base else ""
