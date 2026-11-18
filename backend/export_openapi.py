"""Exporta o OpenAPI da aplicação para `backend/openapi.yaml`.

Uso:
    cd backend
    python export_openapi.py

Regra de ouro: toda alteração de endpoint deve atualizar o YAML e regerar o
cliente Dart no mesmo commit (ver plano de execução, seção 4).
"""

from pathlib import Path

import yaml

from app.main import app

OUTPUT = Path(__file__).resolve().parent / "openapi.yaml"


def main() -> None:
    schema = app.openapi()
    payload = yaml.safe_dump(schema, sort_keys=False, allow_unicode=True, width=120)
    OUTPUT.write_text(payload, encoding="utf-8")
    paths = len(schema.get("paths", {}))
    print(f"OpenAPI exportado: {OUTPUT} ({paths} paths)")


if __name__ == "__main__":
    main()
