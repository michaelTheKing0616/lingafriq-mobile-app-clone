Polie Chat Full Bundle
======================

This bundle contains a starter implementation for the Polie messaging suite:
- frontend/: React + TypeScript + Material 3 tokens + Tailwind utility
- backend/: FastAPI ASGI app with Pydantic models and routes for chats, world wall, connect
- src/enforce_diacritics.py (integration stub)
- tests/: pytest backend tests and a sample jest test stub
- infra/: Dockerfile and GitHub Actions CI

How to run (local dev):
1) Backend:
   - python -m venv .venv
   - source .venv/bin/activate
   - pip install -r infra/requirements.txt
   - uvicorn backend.main:app --reload --port 8000
2) Frontend:
   - cd frontend
   - npm install
   - npm run dev

Notes:
- This is a starter bundle and contains placeholders for heavy systems (E2EE, ASR, model endpoints).
- enforce_diacritics module is included as a simple version; you can replace with your enhanced module.
