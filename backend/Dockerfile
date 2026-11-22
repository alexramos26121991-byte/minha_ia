FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# F0: a API, o worker e o beat rodam como usuário sem privilégio de root.
RUN groupadd --gid 10001 app \
    && useradd --uid 10001 --gid app --create-home --shell /usr/sbin/nologin app

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
# /app/media: upload de midia; /app/beat: estado persistente do agendador Celery.
# Ambos precisam ser gravaveis pelo usuario sem privilegio (uid 10001).
RUN mkdir -p /app/media /app/beat && chown -R app:app /app/media /app/beat

USER app

EXPOSE 8000

# Health real: exige status "ok" (DB + Redis), não apenas HTTP 200.
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import json,sys,urllib.request; d=json.load(urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=5)); sys.exit(0 if d.get('status') == 'ok' else 1)" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--proxy-headers"]
