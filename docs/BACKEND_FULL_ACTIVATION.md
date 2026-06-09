# LingAfriq backend — full activation guide (v4 elevation)

Plain-language, copy-paste steps for **LingAfriq-Backend-v2** (`104.248.26.163`).
Use this after pulling the latest `node-backend` and (optionally) refreshing content packs from the mobile repo.

---

## Important clarifications (read first)

### 1. `python` vs `python3` on your server

Your droplet uses **pyenv**. `python` is not on PATH until you set a global version.

```bash
pyenv versions
pyenv global 3.11.9
hash -r
python3 --version    # should print Python 3.11.9
```

Always use **`python3`** (or `pyenv exec python`) in commands below.

### 2. Content scripts do **not** live in `~/node-backend`

| Script | Location | Run on |
|--------|----------|--------|
| `generate_lingafriq_content.py` | **mobile app repo** `tools/` | Your **PC** or a build machine (not required for API runtime) |
| `export_backend_content_packs.py` | **mobile app repo** `tools/` | Your **PC**, then deploy JSON to server |

Running `python tools/generate_lingafriq_content.py` inside `~/node-backend` will fail — that folder is the Node API only.

### 3. Docker is **optional**

Your server has **no Docker**. That is fine. All new sidecars can run with **Python venv + pm2** (same pattern as `voice-service`, `mfa-service`, `tone-service`).

### 4. MMS TTS port: **8001**, not 8080

Your `.env` already has:

```env
TTS_SERVICE_URL=http://127.0.0.1:8001
```

The repo’s Docker compose defaults to **8080**; **your production MMS is on 8001** (`tts-mms-service/main.py`). Health check:

```bash
curl -sS http://127.0.0.1:8001/health
```

### 5. Never `export` tokens with special characters unquoted

This **breaks bash** (your `%UBq&<3-VW}4{hlm` example):

```bash
# WRONG — shell interprets &, <, {, }
export TTS_INTERNAL_TOKEN=%UBq&<3-VW}4{hlm
```

Generate and store safely:

```bash
TOKEN=$(openssl rand -base64 32)
echo "TTS_INTERNAL_TOKEN=$TOKEN" >> ~/node-backend/.env
# Or append manually in nano — no spaces around =
```

---

## Phase 0 — Free disk (mandatory: you were at 99.6%)

```bash
df -h /
sudo du -xh / --max-depth=1 2>/dev/null | sort -hr | head -15
sudo du -sh /var/lib/lingafriq/tts-cache ~/.pm2/logs /var/log /root 2>/dev/null
```

Safe cleanup:

```bash
sudo apt-get clean
sudo apt-get autoremove -y
sudo journalctl --vacuum-time=3d
pm2 flush
```

Aim for **≥ 5 GB free** before installing Whisper models (~500 MB–2 GB).

---

## Phase 1 — What you already have (pm2)

Expected processes:

| pm2 name | Port | Purpose |
|----------|------|---------|
| `lingafriq-backend` | **4000** | Node API |
| `lingafriq-workers` | — | Redis job workers |
| `voice-service` | **5051** | Pronunciation / wav2vec |
| `mfa-service` | **5052** | Montreal Forced Aligner |
| `tone-service` | **5053** | Tone analysis |

Verify listeners:

```bash
ss -tlnp | grep -E '4000|5051|5052|5053|8001|8090|6379|27017'
pm2 list
pm2 logs voice-service --lines 30    # high restart count — check errors
```

---

## Phase 2 — Update Node backend (Polie SSE + ASR proxy + TTS routing)

On the server:

```bash
cd ~/node-backend
git fetch origin
git pull origin main
npm ci
npm run build
```

Add to `~/node-backend/.env` if missing:

```env
# Whisper ASR sidecar (NEW — v4 games pronunciation scoring)
WHISPER_ASR_URL=http://127.0.0.1:8090
ASR_INTERNAL_TOKEN=PASTE_GENERATED_TOKEN_HERE
ASR_TIMEOUT_MS=45000
ASR_MODEL_SIZE=small

# MMS TTS (you likely already have these)
TTS_SERVICE_URL=http://127.0.0.1:8001
TTS_PROXY_TIMEOUT_MS=20000
TTS_CACHE_DIR=/var/lib/lingafriq/tts-cache
# Optional shared secret between Node and MMS:
# TTS_INTERNAL_TOKEN=PASTE_GENERATED_TOKEN_HERE
```

Generate tokens (run once each):

```bash
openssl rand -base64 32   # copy output → ASR_INTERNAL_TOKEN
openssl rand -base64 32   # copy output → TTS_INTERNAL_TOKEN (if MMS enforces auth)
```

Restart API:

```bash
pm2 restart lingafriq-backend lingafriq-workers
pm2 save
```

Smoke test Node:

```bash
curl -sS http://127.0.0.1:4000/health || curl -sS http://127.0.0.1:4000/api/health
```

---

## Phase 3 — MMS African TTS (port 8001)

If `curl http://127.0.0.1:8001/health` already returns `{"status":"ok"}`, **skip install** — only verify.

If not running, clone/copy `tts-mms-service/` to the server (from your LingAfriqMobile repo):

```bash
sudo mkdir -p /opt/lingafriq
sudo chown "$USER":"$USER" /opt/lingafriq
# From your PC (example):
# scp -r tts-mms-service root@104.248.26.163:/opt/lingafriq/

cd /opt/lingafriq/tts-mms-service
pyenv global 3.11.9
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

Run with pm2 (binds 127.0.0.1:8001 per `main.py`):

```bash
cd /opt/lingafriq/tts-mms-service
source venv/bin/activate
pm2 start "venv/bin/uvicorn main:app --host 127.0.0.1 --port 8001" --name mms-tts --interpreter bash
pm2 save
```

Test:

```bash
curl -sS http://127.0.0.1:8001/health
curl -sS "http://127.0.0.1:8001/tts?lang=yor&text=Bawo%20ni" -o /tmp/test.wav
file /tmp/test.wav
```

Ensure cache dir exists:

```bash
sudo mkdir -p /var/lib/lingafriq/tts-cache
sudo chown "$USER":"$USER" /var/lib/lingafriq/tts-cache
```

---

## Phase 4 — Whisper ASR sidecar (port 8090) — NEW

Copy `whisper-asr-service/` from repo to server:

```bash
# scp -r whisper-asr-service root@104.248.26.163:/opt/lingafriq/

cd /opt/lingafriq/whisper-asr-service
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

Create env file (use the **same** `ASR_INTERNAL_TOKEN` as Node `.env`):

```bash
cat > /opt/lingafriq/whisper-asr-service/.env <<'EOF'
ASR_INTERNAL_TOKEN=PASTE_SAME_VALUE_AS_NODE_ENV
ASR_MODEL_SIZE=small
ASR_DEVICE=cpu
ASR_COMPUTE_TYPE=int8
LOG_LEVEL=INFO
EOF
```

Start with pm2:

```bash
cd /opt/lingafriq/whisper-asr-service
source venv/bin/activate
pm2 start "venv/bin/uvicorn app:app --host 127.0.0.1 --port 8090" --name whisper-asr --interpreter bash
pm2 save
```

Test:

```bash
curl -sS http://127.0.0.1:8090/health
# Score endpoint needs Authorization header matching ASR_INTERNAL_TOKEN
```

After Node restart, mobile app hits: `POST https://admin.lingafriq.com/api/v2/asr/score` → Node proxies to `:8090`.

---

## Phase 5 — Existing Python services (verify, don’t duplicate)

These should already be managed by pm2. Only restart if you updated code:

```bash
pm2 restart voice-service mfa-service tone-service
```

Your `.env` mappings:

```env
VOICE_SERVICE_URL=http://localhost:5051
WAV2VEC2_SERVICE_URL=http://localhost:5051
PRONUNCIATION_API_URL=http://localhost:5051
MFA_SERVICE_URL=http://localhost:5052
TONE_ANALYSIS_URL=http://localhost:5053
```

---

## Phase 6 — Content packs for CMS API (optional, from your PC)

On your **Windows/Mac dev machine** (mobile app repo):

```bash
cd mobile-app-safe-push-michael/tools
python3 generate_lingafriq_content.py
python3 export_backend_content_packs.py
```

This writes to `node-backend-safe-push/data/content-packs/*.json`.

Deploy to server:

```bash
scp -r node-backend-safe-push/data/content-packs/* root@104.248.26.163:~/node-backend/data/content-packs/
```

Then on server:

```bash
pm2 restart lingafriq-backend
```

---

## Phase 7 — CDN Gold audio (optional, large disk)

Batch TTS upload for `audio_manifest.json` Gold tier:

- Run `tools/generate_native_audio.py` on a machine with MMS access + CDN credentials
- Requires significant disk and network; **not** required for Silver (live MMS) tier

---

## Phase 8 — Full smoke-test checklist

Run on server:

```bash
# Core
curl -sS http://127.0.0.1:4000/health

# TTS
curl -sS http://127.0.0.1:8001/health

# Voice / MFA / Tone
curl -sS http://127.0.0.1:5051/health || true
curl -sS http://127.0.0.1:5052/health || true
curl -sS http://127.0.0.1:5053/health || true

# Whisper ASR
curl -sS http://127.0.0.1:8090/health

# Redis + Mongo (should listen locally)
ss -tlnp | grep -E '6379|27017'

pm2 list
df -h /
```

From outside (replace with a real user JWT):

```bash
curl -sS "https://admin.lingafriq.com/api/tts?language=yoruba&text=Bawo%20ni" \
  -H "Authorization: Bearer YOUR_USER_JWT" -o /tmp/tts.wav
```

---

## Phase 9 — Security rotation (recommended)

You pasted live secrets in chat. Rotate when possible:

- MongoDB password (`lingafriqadmin2`)
- `JWT_SECRET`, `JWT_REFRESH_SECRET`, `EVENT_SECRET`
- `GEMINI_API_KEY`, `OPENAI_API_KEY`, `GROQ_API_KEY`, `HUGGINGFACE_TOKEN`
- `LIVEKIT_API_SECRET`, SMTP app password
- `ASR_INTERNAL_TOKEN`, `TTS_INTERNAL_TOKEN` (after generating new ones, update both Node `.env` and sidecar `.env`, then `pm2 restart all`)

---

## Quick reference — new v4 backend routes

| Feature | Mobile calls | Node route | Sidecar |
|---------|--------------|------------|---------|
| Polie streaming chat | SSE | `/api/v2/polie/conversation/stream` | Groq/Gemini (env keys) |
| African TTS | GET | `/api/tts` | MMS `:8001` |
| Pronunciation score | POST multipart | `/api/v2/asr/score` | Whisper `:8090` |
| Voice analysis | POST | `/api/voice/*` | `voice-service :5051` |

---

## Troubleshooting your exact errors

| Error | Cause | Fix |
|-------|-------|-----|
| `pyenv: python: command not found` | No global Python | `pyenv global 3.11.9` or use `python3` |
| `tools/generate_lingafriq_content.py` in node-backend | Wrong repo | Run from **mobile-app** `tools/` on your PC |
| `/opt/lingafriq/tts-mms-service: No such file` | Not deployed yet | `mkdir -p /opt/lingafriq` and copy folder, or use existing MMS on 8001 |
| `export TTS_INTERNAL_TOKEN=%UBq&...` bash errors | Unquoted special chars | Generate with `openssl rand -base64 32`; edit `.env` in nano |
| `docker: command not found` | Docker not installed | Use **venv + pm2** path above |
| `curl :8080/healthz` empty | Wrong port | Use **`curl http://127.0.0.1:8001/health`** |
