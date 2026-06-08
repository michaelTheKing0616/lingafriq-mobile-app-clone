# DigitalOcean backend — what you have vs what to add

Plain-language ops guide for `LingAfriq-Backend-v2`. Run commands **on the server** over SSH (Cursor cannot log in for you).

## What your `pm2` list already covers

| Process | Likely role | Matches `.env` |
|--------|-------------|----------------|
| `lingafriq-backend` | Node API (port 4000) | `PORT=4000` |
| `lingafriq-workers` | Background jobs (Redis queues) | `REDIS_HOST` |
| `voice-service` | Pronunciation / wav2vec on **5051** | `VOICE_SERVICE_URL`, `WAV2VEC2_SERVICE_URL` |
| `mfa-service` | Montreal Forced Aligner **5052** | `MFA_SERVICE_URL` |
| `tone-service` | Tone analysis **5053** | `TONE_ANALYSIS_URL` |

You already point African TTS at **MMS on port 8001** (`TTS_SERVICE_URL=http://127.0.0.1:8001`). If that process is healthy, you do **not** need a second MMS on 8080.

## What is probably still missing

1. **Whisper ASR sidecar (port 8090)** — used for pronunciation scoring in games (`/api/v2/asr/*`). Not in your `pm2 list`.
2. **Disk space** — root is **99.6% full**. Fix this before any `docker pull` or model download.
3. **Optional: Ollama** — `.env` has `AI_CHAT_SERVICE_URL=http://localhost:11434/api/generate`. Only needed if Polie should use local LLM; Groq/Gemini keys are also set.

## Can Cursor access my DO server?

**No.** This assistant only has your local project folder and shell on your PC. To “give access” you can:

- Paste command output here after you SSH in, or
- Use **Cursor SSH Remote** (connect the IDE to the droplet yourself), or
- Open a **GitHub Action** that deploys from your repo.

## Step 1 — Free disk (do this first)

```bash
df -h /
sudo du -xh / --max-depth=1 2>/dev/null | sort -hr | head -20
sudo du -xh /var --max-depth=1 2>/dev/null | sort -hr | head -15
sudo du -xh /root --max-depth=1 2>/dev/null | sort -hr | head -15
```

Common safe cleanups:

```bash
# APT cache
sudo apt-get clean
sudo apt-get autoremove -y

# Old journal logs (keeps last 3 days)
sudo journalctl --vacuum-time=3d

# PM2 logs
pm2 flush

# Your TTS cache (only if you can regenerate)
sudo du -sh /var/lib/lingafriq/tts-cache
# sudo rm -rf /var/lib/lingafriq/tts-cache/*   # only if desperate

# Docker (if installed)
docker system df
# docker system prune -af   # removes unused images — confirm first
```

Aim for **at least 5 GB free** before adding Whisper or large models.

## Step 2 — Verify what is listening

```bash
ss -tlnp | grep -E '4000|5051|5052|5053|8001|8090|6379|27017'
curl -sS http://127.0.0.1:8001/health || curl -sS http://127.0.0.1:8001/
curl -sS http://127.0.0.1:5051/health || true
curl -sS http://127.0.0.1:4000/health || curl -sS http://127.0.0.1:4000/api/health || true
```

## Step 3 — Deploy Whisper ASR (if repo has `whisper-asr-service/`)

On the server (after disk cleanup), from your backend checkout:

```bash
cd ~/node-backend   # or wherever whisper-asr-service lives
python3 -m venv venv-asr
source venv-asr/bin/activate
pip install -r whisper-asr-service/requirements.txt

export ASR_INTERNAL_TOKEN="$(openssl rand -hex 32)"
# Add to Node .env:
# WHISPER_ASR_URL=http://127.0.0.1:8090
# ASR_INTERNAL_TOKEN=<same value>

pm2 start whisper-asr-service/app.py --name whisper-asr --interpreter python3
pm2 save
pm2 restart lingafriq-backend
```

Smoke test (replace token):

```bash
curl -sS http://127.0.0.1:8090/health
```

## Step 4 — Node `.env` additions

Add if missing (generate tokens with `openssl rand -hex 32`):

```env
WHISPER_ASR_URL=http://127.0.0.1:8090
ASR_INTERNAL_TOKEN=<secret>
# Optional if MMS requires auth:
# TTS_INTERNAL_TOKEN=<secret>
```

Then: `pm2 restart lingafriq-backend lingafriq-workers`

## Step 5 — Security note

API keys and passwords appeared in chat logs. **Rotate** MongoDB password, JWT secrets, Groq/OpenAI/Gemini/HF keys, LiveKit, and SMTP app password when you can.

## Regenerating mobile content (local machine)

From `mobile-app-safe-push-michael/tools`:

```bash
python generate_lingafriq_content.py
```

Ship a new app build so users get `game_content.json` v4 and `lingafriq_authentic_curriculum_a1_c2.json` (C2 + expanded lessons).

## Content numbers (after `generate_lingafriq_content.py`)

| Asset | Approximate scale |
|-------|-------------------|
| `game_content.json` | ~1,400 words across 14 languages (85–120 per language) |
| `lingafriq_authentic_curriculum_a1_c2.json` | A1–C2, ~1,680 lessons target (20 per level × 6 levels × 14 langs) |
| `audio_manifest.json` | Regenerated from words + curriculum phrases |

The app loads `a1_c2.json` first when present (`curriculum_service.dart`).
