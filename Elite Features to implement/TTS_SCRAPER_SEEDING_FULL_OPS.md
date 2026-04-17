# TTS, scraper, and seeding — full operations guide

This document lists **every variable and secret** you need, with **example values** (replace placeholders with your own). It complements the backend repo files `BACKEND_SERVICES_SETUP.md` and `SCRAPER_API_SETUP.md` in `node-backend-safe-push`.

---

## 0. Mental model

| Concern | Where it runs | Who needs secrets |
|--------|----------------|-------------------|
| **MMS-TTS** | Same machine as Node (recommended), `127.0.0.1:8001` | Server `.env` only (`TTS_SERVICE_URL` on Node) |
| **Node API** | VPS / cloud | Server `.env` (`MONGODB_URI`, `JWT_SECRET`, …) |
| **Scraper (CI)** | GitHub Actions | **GitHub repository secrets** on the **backend** repo |
| **Seeding** | Your shell on server or laptop with DB access | `MONGODB_URI` in `.env` |

The **mobile app** never talks to the Python TTS port. It calls **`GET /api/tts`** on your Node API (authenticated).

---

## 1. Node.js backend — `.env` (production example)

Create or edit `.env` in the backend project root (e.g. `/opt/lingafriq/node-backend/.env`).

### 1.1 Required (minimal)

| Variable | Example value | Notes |
|----------|----------------|-------|
| `MONGODB_URI` | `mongodb+srv://appuser:STRONG_PASSWORD@cluster0.xxxxx.mongodb.net/lingafriq?retryWrites=true&w=majority` | Use your Atlas user + DB name. Never commit. |
| `JWT_SECRET` | `openssl rand -hex 32` → paste 64-char hex | Signs user sessions; keep stable in prod. |

### 1.2 TTS proxy (MMS sidecar)

| Variable | Example value | Notes |
|----------|----------------|-------|
| `TTS_SERVICE_URL` | `http://127.0.0.1:8001` | Must match MMS-TTS bind host/port. No trailing slash. |
| `TTS_CACHE_DIR` | `/var/lib/lingafriq/tts-cache` (Linux) or `C:\lingafriq\tts-cache` (Windows) | Optional; defaults to `<backend>/.cache/tts`. Ensure the Node process can write here. |
| `TTS_PROXY_TIMEOUT_MS` | `20000` | Optional; default `20000`. Increase (e.g. `120000`) if first model load causes timeouts. |

### 1.3 Scraper signing (token generation)

| Variable | Example value | Notes |
|----------|----------------|-------|
| `SCRAPER_SECRET` | Another `openssl rand -hex 32` | **Optional.** If unset, `scripts/generateScraperToken.js` uses `JWT_SECRET`. Using a **separate** `SCRAPER_SECRET` lets you rotate scraper tokens without rotating all user JWTs. |

### 1.4 Culture scraper behaviour (server)

Exact names depend on your deployed code; common patterns:

| Variable | Example value | Notes |
|----------|----------------|-------|
| `CULTURE_SCRAPER_AUTO_PUBLISH` | `true` or `false` | Whether scraped articles are published immediately. |
| `CULTURE_SCRAPER_FEATURE_RATE` | `0.15` | Fraction 0–1 of articles marked featured (if implemented). |
| `SCRAPER_BATCH_SIZE` | `20` | Topics per run (if implemented). |

### 1.5 Optional: Hybrid Polie voice (Docker Coqui path)

| Variable | Example value | Notes |
|----------|----------------|-------|
| `VOICE_SERVICE_URL` | `http://127.0.0.1:5051` | Only if you run `voice-service/` separately from MMS-TTS. |

### 1.6 GitHub Actions workflow (not in server `.env`)

These are **GitHub Actions secrets** on the backend repository (see section 3).

---

## 2. MMS-TTS sidecar — environment and commands

Path in repo: `mms-tts-service/`.

### 2.1 Python-side variables

| Variable | Example | Notes |
|----------|---------|-------|
| `MMS_TTS_HOST` | `127.0.0.1` | Bind address; **do not** expose `0.0.0.0` to the public internet without auth in front. |
| `MMS_TTS_PORT` | `8001` | Must match `TTS_SERVICE_URL` on Node. |
| `MMS_TTS_DEVICE` | `cpu` or `cuda` | GPU only if PyTorch + CUDA installed. |
| `MMS_TTS_MAX_TEXT_LEN` | `500` | Optional; aligns with Node’s max text length. |

### 2.2 Install (Linux example)

```bash
cd /path/to/node-backend/mms-tts-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Windows (PowerShell):

```powershell
cd C:\path\to\node-backend\mms-tts-service
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2.3 Run (development)

```bash
export MMS_TTS_HOST=127.0.0.1
export MMS_TTS_PORT=8001
# export MMS_TTS_DEVICE=cuda   # if GPU
python main.py
```

Or:

```bash
uvicorn main:app --host 127.0.0.1 --port 8001
```

### 2.4 Verify

```bash
curl -s "http://127.0.0.1:8001/health"
curl -s -o /tmp/test.wav "http://127.0.0.1:8001/tts?lang=eng&text=Hello"
```

### 2.5 Node verify (after user login in app, or with a valid API session)

The mobile client hits **`GET https://YOUR_API/api/tts?language=...&text=...`** (exact query names as in your app). Ensure `TTS_SERVICE_URL` is set and MMS-TTS is running before testing.

---

## 3. Scraper — GitHub Secrets and token generation

Workflow file: `.github/workflows/scraper-cron.yml` (runs daily + `workflow_dispatch`).

### 3.1 Repository secrets (backend repo)

| Secret name | Example value | Required |
|-------------|---------------|----------|
| `BACKEND_URL` | `https://api.yourdomain.com` | **Yes** — public HTTPS base **without** trailing slash; must reach your live API. |
| `SCRAPER_TOKEN` | *(JWT string from step 3.2)* | **Yes** |
| `NEWS_API_KEY` | *(provider key)* | Only if your scraper code still calls News APIs (optional per your build). |

### 3.2 Generate `SCRAPER_TOKEN` (on a machine that has backend `.env`)

```bash
cd /path/to/node-backend
# Ensure .env contains JWT_SECRET=... and optionally SCRAPER_SECRET=...
node scripts/generateScraperToken.js
```

Copy the printed **TOKEN** line only into GitHub → **Settings → Secrets and variables → Actions → New repository secret** → name **`SCRAPER_TOKEN`**.

**Important:** The script signs a payload with `type: 'scraper'` and `purpose: 'automated_content_import'`. The **same** secret (`SCRAPER_SECRET` or `JWT_SECRET`) must be what the **deployed** API uses to verify the JWT.

### 3.3 Manual workflow run

GitHub → **Actions** → **Culture Magazine Scraper** → **Run workflow**.

### 3.4 If scraping fails

1. Open the failed job log.
2. From your machine: `curl -s "$BACKEND_URL/scraper/health"` (adjust path if your mount differs).
3. Re-read `SCRAPER_API_SETUP.md` for bulk endpoint paths and headers (`Authorization: Bearer <token>`).

---

## 4. Database seeding — commands and prerequisites

Run from **backend root** after `npm ci` and **`npm run build`** (compiled `dist/` required for `:dist` scripts).

### 4.1 Prerequisite

| Variable | Example |
|----------|---------|
| `MONGODB_URI` | Same as production or a **staging** URI if you do not want to touch prod. |

Load via `.env` in the backend directory (`dotenv` in scripts) or export in shell:

```bash
export MONGODB_URI='mongodb+srv://...'
```

### 4.2 Historical personas (~100)

**TypeScript (dev):**

```bash
npm run seed:personalities
```

**Compiled (production server):**

```bash
npm run seed:personalities:dist
```

### 4.3 Culture magazine seed data

**TS:**

```bash
npm run seed:culture-magazine
# With publish flag if your script supports it:
npm run seed:culture-magazine:publish
```

**Dist:**

```bash
npm run seed:culture-magazine:dist
npm run seed:culture-magazine:dist:publish
```

### 4.4 One-shot “core content” (personas + magazine)

```bash
npm run seed:core-content:dist
# or with publish:
npm run seed:core-content:dist:publish
```

### 4.5 Recommended order on a fresh database

1. `npm ci`
2. `npm run build`
3. Set `MONGODB_URI` (and `JWT_SECRET` if scripts need auth — follow script docs)
4. `npm run seed:core-content:dist:publish` *(or non-publish if you want drafts)*

---

## 5. Flutter app — `.env` (points at your API)

File: `mobile-app-main/.env` (loaded in `main.dart` via `flutter_dotenv`).

| Key | Example | Notes |
|-----|---------|-------|
| `BACKEND_API_URL` | `https://api.yourdomain.com` | Primary; aligns with `SecretsManager`. |
| `BACKEND_URL` | Same as above | Alias supported by mapping in `secrets_manager.dart`. |

Optional (only if you use those features):

| Key | Example |
|-----|---------|
| `PRONUNCIATION_API_URL` | `https://pronunciation.yourdomain.com` |
| `NLLB_API_URL` | `https://nllb.yourdomain.com` |

**Do not** put `JWT_SECRET`, `SCRAPER_TOKEN`, or `MONGODB_URI` in the Flutter app.

---

## 6. Quick verification checklist

- [ ] `mongosh` or app can connect with `MONGODB_URI`
- [ ] `curl http://127.0.0.1:8001/health` returns OK
- [ ] Node `.env` has `TTS_SERVICE_URL=http://127.0.0.1:8001`
- [ ] GitHub Actions secrets `BACKEND_URL` + `SCRAPER_TOKEN` set on backend repo
- [ ] `npm run build` succeeds; seed commands run without Mongo errors
- [ ] Flutter `.env` `BACKEND_API_URL` matches your deployed API

---

## 7. Reference paths in this workspace

| Document / code | Path |
|-----------------|------|
| Backend services overview | `node-backend-safe-push/BACKEND_SERVICES_SETUP.md` |
| Scraper API detail | `node-backend-safe-push/SCRAPER_API_SETUP.md` |
| Token generator | `node-backend-safe-push/scripts/generateScraperToken.js` |
| Cron workflow | `node-backend-safe-push/.github/workflows/scraper-cron.yml` |
| MMS-TTS app | `node-backend-safe-push/mms-tts-service/main.py` |
| Node TTS proxy | `node-backend-safe-push/src/routes/mmsTts.route.ts` |
| `package.json` seed scripts | `node-backend-safe-push/package.json` |
| UI / design tokens (mockups) | This folder: `DESIGN.md` + `stitch_private_chat/...` |

Replace all example URLs, passwords, and tokens with your own before production.

---

## 8. Tailored ops — your environment (step-by-step)

This section matches **your** typical layout: **local MongoDB**, **local Redis**, **Node on port 4000**, **voice/Wav2Vec2 on 5051**, optional **MFA (5052)** and **tone (5053)**, **Ollama** for chat (`11434`), and **Hugging Face** for Whisper/NLLB inference. Values below use **placeholders** — never commit a real `.env`.

### 8.0 Security first (non-negotiable)

1. **If any real secret was ever pasted into chat, email, or a ticket, rotate it** (Hugging Face token, Groq, Stability AI, LiveKit API secret, SMTP app password, JWT secrets, MongoDB password).
2. **Do not** copy live secrets into this markdown file or into Git.
3. Keep **production** `JWT_SECRET`, `JWT_REFRESH_SECRET`, and `EVENT_SECRET` long, random, and **different from development** if dev and prod are separate deployments.
4. **SMTP `SMTP_PASS`** must be a Google **App Password** (16 characters), not your normal Gmail password.

---

### 8.1 One-page map: what each variable is for

| Area | Variable(s) | Your intended use |
|------|-------------|-------------------|
| **HF / Whisper** | `HUGGINGFACE_TOKEN` | Authenticate to Hugging Face Inference API (Whisper and similar models). |
| **Voice / pronunciation** | `VOICE_SERVICE_URL`, `WAV2VEC2_SERVICE_URL`, `PRONUNCIATION_API_URL` | All point at the same local service on **5051** in your setup (aliases for different call sites in code). |
| **Optional aligner** | `MFA_SERVICE_URL` | Montreal Forced Aligner microservice on **5052** if you run it. |
| **Optional tone** | `TONE_ANALYSIS_URL` | Tone analysis on **5053** if you run it. |
| **Database** | `MONGODB_URI` | Local Mongo with database name **`lingafriq`** (adjust user/password/host for your machine). |
| **API core** | `PORT`, `NODE_ENV`, `JWT_SECRET`, `JWT_REFRESH_SECRET` | Node listens on **4000**; JWT pair signs access/refresh tokens. |
| **Redis** | `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD` | `127.0.0.1:6379`, empty password if local default. |
| **Anti-cheat / events** | `EVENT_SECRET` | Server-side secret for event integrity; must be a **static random string** in `.env` (see 8.4). |
| **Translation** | `NLLB_API_URL`, `TRANSLATION_PROVIDER` | NLLB via HF inference URL; `TRANSLATION_PROVIDER=free-google` for your Google path. |
| **Local LLM** | `AI_CHAT_SERVICE_URL` | **`http://localhost:11434/api/generate`** = Ollama; ensure Ollama is running and a model is pulled. |
| **Optional cloud LLM** | `GROQ_API_KEY` | Groq API when code paths use it. |
| **Images** | `STABILITY_AI_KEY` | Stability AI when image features call it. |
| **Realtime** | `LIVEKIT_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` | LiveKit Cloud project for voice/video rooms. |
| **Browser access** | `CORS_ORIGINS` | Comma-separated admin + site origins. |
| **Email** | `SMTP_*`, `FROM_EMAIL`, `HOSTNAME` | Gmail SMTP + **admin** public URL for links. |

---

### 8.2 Bring-up order (local full stack)

Do these **in order** the first time (or after a reboot).

#### Step 1 — MongoDB

1. Start **MongoDB** on `localhost:27017`.
2. Ensure a user/database exist that match **`MONGODB_URI`** (format: `mongodb://USER:PASSWORD@localhost:27017/lingafriq`).
3. Verify:

   ```bash
   mongosh "YOUR_MONGODB_URI_HERE" --eval "db.runCommand({ ping: 1 })"
   ```

#### Step 2 — Redis

1. Start **Redis** on `127.0.0.1:6379` with **no password** if `REDIS_PASSWORD` is empty.
2. Verify:

   ```bash
   redis-cli -h 127.0.0.1 -p 6379 ping
   ```

   Expect `PONG`.

#### Step 3 — `EVENT_SECRET` (correct `.env` shape)

Many `.env` loaders **do not** expand `$(openssl ...)`. Do **not** leave a literal `$(openssl rand -base64 32)` in the file unless your tooling explicitly supports it.

1. In a terminal:

   ```bash
   openssl rand -base64 32
   ```

2. Put **one line** in backend `.env`:

   ```env
   EVENT_SECRET=paste_the_single_line_output_here
   ```

3. Restart Node after any change to `EVENT_SECRET`.

#### Step 4 — Hugging Face token (Whisper / NLLB)

1. Create or open a Hugging Face access token with **read** access to the models you use.
2. In backend `.env`:

   ```env
   HUGGINGFACE_TOKEN=hf_your_token_here
   ```

3. For **`NLLB_API_URL`**, keep the full inference endpoint URL your backend expects (same host pattern as in your current config).
4. Quick check (replace token and URL if your route differs):

   ```bash
   curl -s -H "Authorization: Bearer hf_your_token_here" "YOUR_NLLB_API_URL" -H "Content-Type: application/json" -d '{"inputs":"Hello"}' | head -c 200
   ```

   If you get **401**, the token or model access is wrong.

#### Step 5 — Voice / Wav2Vec2 / pronunciation service (port 5051)

1. Start your **voice** service so it listens on **`http://localhost:5051`** (or bind `127.0.0.1:5051`).
2. In backend `.env`, align **all three** to the same base URL (no trailing slash):

   ```env
   VOICE_SERVICE_URL=http://localhost:5051
   WAV2VEC2_SERVICE_URL=http://localhost:5051
   PRONUNCIATION_API_URL=http://localhost:5051
   ```

3. Verify health (adjust path to your service’s real health route):

   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://localhost:5051/health
   ```

4. If **5051** is down, any code path that calls these URLs will fail at runtime even if Node is up.

#### Step 6 — Optional MFA (5052) and tone (5053)

1. Only set if the services are actually running:

   ```env
   MFA_SERVICE_URL=http://localhost:5052
   TONE_ANALYSIS_URL=http://localhost:5053
   ```

2. If you **do not** run them, either omit these lines or expect feature-specific errors until you add stubs or disable those features in code/config.

#### Step 7 — Ollama (local chat — port 11434)

1. Install and start **Ollama**; pull at least one model (example: `ollama pull llama3.2`).
2. Confirm:

   ```bash
   curl -s http://localhost:11434/api/tags
   ```

3. Backend `.env`:

   ```env
   AI_CHAT_SERVICE_URL=http://localhost:11434/api/generate
   ```

4. Node code must send the **body shape Ollama expects** (`model`, `prompt`, etc.). If chat fails, compare your route handler to Ollama’s `/api/generate` docs.

#### Step 8 — Node API (port 4000)

1. In backend `.env`, set:

   ```env
   PORT=4000
   NODE_ENV=production
   ```

   For **local debugging only**, you may use `NODE_ENV=development` to get richer errors; production deployments should use `production`.

2. Set **`JWT_SECRET`** and **`JWT_REFRESH_SECRET`** to long random strings (generate with `openssl rand -hex 32` twice — **two different** values).

3. Install and build:

   ```bash
   cd /path/to/node-backend
   npm ci
   npm run build
   ```

4. Start the server (however you usually do: `node dist/index.js`, `pm2`, etc.).

5. Verify:

   ```bash
   curl -s -o /dev/null -w "%{http_code}" http://localhost:4000/
   ```

#### Step 9 — MMS-TTS sidecar (if you use `/api/tts` → Python)

This doc’s sections **2** and **6** still apply. Your **voice** URLs (5051) are **separate** from **MMS-TTS** (typically **8001**). Set **`TTS_SERVICE_URL=http://127.0.0.1:8001`** only when the MMS service is running; otherwise TTS proxy routes will fail.

#### Step 10 — LiveKit (cloud)

1. Keep **`LIVEKIT_URL`**, **`LIVEKIT_API_KEY`**, and **`LIVEKIT_API_SECRET`** in sync with the **same** LiveKit project.
2. **Never** expose the API secret to the Flutter app; only server-side code should use it to mint tokens.

#### Step 11 — CORS

1. Set **`CORS_ORIGINS`** to a **comma-separated** list with **no spaces** (unless your parser trims them — verify in `node-backend` CORS config):

   ```env
   CORS_ORIGINS=https://lingafriq.com,https://admin.lingafriq.com,https://lingafriq-admin.web.app
   ```

2. After changing CORS, restart Node and test a browser request from each origin.

#### Step 12 — Translation provider

1. **`TRANSLATION_PROVIDER=free-google`** — ensure any Google-related credentials or API enablement your code expects are satisfied (see backend docs for that provider path).
2. **`NLLB_API_URL`** + **`HUGGINGFACE_TOKEN`** — used when code calls Hugging Face inference; token must be valid for that model.

#### Step 13 — SMTP / email

1. Use **`SMTP_HOST=smtp.gmail.com`**, **`SMTP_PORT=587`**, **`SMTP_USER`** / **`FROM_EMAIL`** as the same Gmail account.
2. **`SMTP_PASS`**: 16-character **App Password** (spaces removed).
3. **`HOSTNAME`**: public admin base URL used in emailed links (e.g. `https://admin.lingafriq.com`).

4. Send a test from the server (if you have a script) or trigger a password-reset flow and watch logs.

#### Step 14 — Flutter app `.env`

1. Point the app at your API, e.g.:

   ```env
   BACKEND_API_URL=http://localhost:4000
   ```

   or your deployed HTTPS URL.

2. **Do not** put `MONGODB_URI`, `JWT_SECRET`, `GROQ_API_KEY`, `HUGGINGFACE_TOKEN`, `LIVEKIT_API_SECRET`, or `SMTP_PASS` in the mobile `.env`.

---

### 8.3 Scraper + seeding (unchanged flow, your DB)

1. **Seeding** still needs **`MONGODB_URI`** reachable from the machine running `npm run seed:*` (section **4**).
2. **GitHub Actions scraper** still needs **`BACKEND_URL`** + **`SCRAPER_TOKEN`** as **repository secrets**, not in server `.env` only (section **3**).
3. After changing **`JWT_SECRET`** or **`SCRAPER_SECRET`**, **regenerate** `SCRAPER_TOKEN` and update the GitHub secret.

---

### 8.4 Duplicate lines in `.env`

If **`VOICE_SERVICE_URL`** / **`WAV2VEC2_SERVICE_URL`** / **`PRONUNCIATION_API_URL`** appear twice in the file, **only the last occurrence wins** in many loaders — or behavior may be undefined. **Consolidate** to one block per variable.

---

### 8.5 Updated checklist (additions for your stack)

- [ ] MongoDB reachable with `MONGODB_URI`; `mongosh` ping OK  
- [ ] Redis `PONG` on `REDIS_HOST`/`REDIS_PORT`  
- [ ] `EVENT_SECRET` is a **literal** random string, not a shell `$(...)` fragment  
- [ ] `HUGGINGFACE_TOKEN` set; NLLB/Whisper calls return not-401 for a smoke test  
- [ ] Voice service up on **5051**; three URL vars agree  
- [ ] Ollama up on **11434**; `AI_CHAT_SERVICE_URL` matches  
- [ ] MMS-TTS on **8001** if using `TTS_SERVICE_URL` to MMS  
- [ ] Node on **4000**; CORS includes your real admin/app origins  
- [ ] LiveKit secrets match one project  
- [ ] Flutter `BACKEND_API_URL` points at the same API you tested with `curl`  
- [ ] GitHub `SCRAPER_TOKEN` regenerated if JWT/scraper secret rotated  

---

### 8.6 Where to edit (workspace)

| What | Where |
|------|--------|
| Backend secrets | `node-backend-safe-push/.env` (or your deployed server path) — use intermediary clone per your push rules |
| App API base | `mobile-app-main/.env` or `mobile-app-safe-push-michael/.env` (whichever you build) |
| MMS-TTS | `mms-tts-service/` env + `TTS_SERVICE_URL` on Node |
| This guide | `mobile-app-main/Elite Features to implement/TTS_SCRAPER_SEEDING_FULL_OPS.md` |
