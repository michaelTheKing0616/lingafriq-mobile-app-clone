#!/usr/bin/env python3
"""LingAfriq STT bake-off probe: Intron Sahara vs Sunbird vs Whisper sidecar.

Stdlib only. Missing provider keys skip that provider instead of crashing.

Examples:
  python3 tool/stt_bakeoff/probe.py --self-test
  python3 tool/stt_bakeoff/probe.py --dry-run
  python3 tool/stt_bakeoff/probe.py --providers intron,sunbird,whisper \\
      --priority core --audio-dir tool/stt_bakeoff/audio
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import unicodedata
import uuid
from dataclasses import dataclass
from http.client import HTTPConnection, HTTPSConnection
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
EVAL_SET_PATH = ROOT / "eval_set.json"

INTRON_SYNC_URL = "https://infer.voice.intron.io/file/v1/upload/sync"
INTRON_STATUS_URL = "https://infer.voice.intron.io/file/v1/status/{file_id}"
SUNBIRD_URL = "https://api.sunbird.ai/tasks/audio/transcriptions"


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------

def normalize_text(text: str, *, strip_diacritics: bool = True) -> list[str]:
    """Tokenize for WER. Language-learning eval uses diacritic-stripped tokens
    so tone-mark differences do not dominate isolated-word scoring."""
    folded = unicodedata.normalize("NFKC", text or "").lower()
    if strip_diacritics:
        folded = "".join(
            ch
            for ch in unicodedata.normalize("NFD", folded)
            if unicodedata.category(ch) != "Mn"
        )
    cleaned = []
    for ch in folded:
        if ch.isalnum() or ch.isspace() or ch in "'’-":
            cleaned.append(ch)
        else:
            cleaned.append(" ")
    return [tok for tok in "".join(cleaned).replace("'", " ").split() if tok]


def levenshtein(a: list[str], b: list[str]) -> int:
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, start=1):
        cur = [i]
        for j, cb in enumerate(b, start=1):
            ins = cur[j - 1] + 1
            delete = prev[j] + 1
            sub = prev[j - 1] + (0 if ca == cb else 1)
            cur.append(min(ins, delete, sub))
        prev = cur
    return prev[-1]


def word_error_rate(reference: str, hypothesis: str) -> float:
    ref = normalize_text(reference)
    hyp = normalize_text(hypothesis)
    if not ref:
        return 0.0 if not hyp else 1.0
    return levenshtein(ref, hyp) / len(ref)


def char_error_rate(reference: str, hypothesis: str) -> float:
    ref = list(" ".join(normalize_text(reference)))
    hyp = list(" ".join(normalize_text(hypothesis)))
    if not ref:
        return 0.0 if not hyp else 1.0
    return levenshtein(ref, hyp) / len(ref)


# ---------------------------------------------------------------------------
# HTTP multipart (stdlib)
# ---------------------------------------------------------------------------

def _multipart_body(
    fields: dict[str, str],
    files: dict[str, tuple[str, bytes, str]],
) -> tuple[bytes, str]:
    boundary = f"----LingAfriqBakeoff{uuid.uuid4().hex}"
    chunks: list[bytes] = []
    for name, value in fields.items():
        chunks.append(f"--{boundary}\r\n".encode())
        chunks.append(
            f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode()
        )
        chunks.append(value.encode("utf-8"))
        chunks.append(b"\r\n")
    for name, (filename, data, content_type) in files.items():
        chunks.append(f"--{boundary}\r\n".encode())
        chunks.append(
            (
                f'Content-Disposition: form-data; name="{name}"; '
                f'filename="{filename}"\r\n'
            ).encode()
        )
        chunks.append(f"Content-Type: {content_type}\r\n\r\n".encode())
        chunks.append(data)
        chunks.append(b"\r\n")
    chunks.append(f"--{boundary}--\r\n".encode())
    return b"".join(chunks), f"multipart/form-data; boundary={boundary}"


def http_request(
    method: str,
    url: str,
    *,
    headers: dict[str, str] | None = None,
    body: bytes | None = None,
    timeout: float = 120.0,
) -> tuple[int, dict[str, str], bytes]:
    parsed = urlparse(url)
    conn_cls = HTTPSConnection if parsed.scheme == "https" else HTTPConnection
    port = parsed.port or (443 if parsed.scheme == "https" else 80)
    conn = conn_cls(parsed.hostname or "", port=port, timeout=timeout)
    path = parsed.path or "/"
    if parsed.query:
        path = f"{path}?{parsed.query}"
    try:
        conn.request(method, path, body=body, headers=headers or {})
        resp = conn.getresponse()
        data = resp.read()
        hdrs = {k.lower(): v for k, v in resp.getheaders()}
        return resp.status, hdrs, data
    finally:
        conn.close()


def parse_json(data: bytes) -> Any:
    if not data:
        return {}
    return json.loads(data.decode("utf-8"))


# ---------------------------------------------------------------------------
# Providers
# ---------------------------------------------------------------------------

@dataclass
class TranscriptResult:
    provider: str
    clip_id: str
    ok: bool
    transcript: str
    latency_ms: int
    error: str = ""
    raw_status: str = ""


def transcribe_intron(
    audio_path: Path,
    language_code: str,
    api_key: str,
) -> TranscriptResult:
    blob = audio_path.read_bytes()
    body, content_type = _multipart_body(
        {
            "audio_file_name": audio_path.name,
            "use_language_asr_input": language_code,
            "use_category": "file_category_general",
            "use_disable_llm_corrections": "TRUE",
        },
        {
            "audio_file_blob": (audio_path.name, blob, "audio/wav"),
        },
    )
    started = time.perf_counter()
    status, _, data = http_request(
        "POST",
        INTRON_SYNC_URL,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": content_type,
        },
        body=body,
        timeout=130.0,
    )
    elapsed = int((time.perf_counter() - started) * 1000)
    payload = parse_json(data)
    inner = payload.get("data") if isinstance(payload, dict) else {}
    if not isinstance(inner, dict):
        inner = {}
    if status == 503 and inner.get("file_id"):
        inner = _poll_intron_status(str(inner["file_id"]), api_key) or inner
        status = 200 if inner.get("audio_transcript") else status
    transcript = str(inner.get("audio_transcript") or "").strip()
    if status >= 400 or not transcript:
        return TranscriptResult(
            provider="intron",
            clip_id="",
            ok=False,
            transcript="",
            latency_ms=elapsed,
            error=f"HTTP {status}: {payload}",
            raw_status=str(inner.get("processing_status") or ""),
        )
    return TranscriptResult(
        provider="intron",
        clip_id="",
        ok=True,
        transcript=transcript,
        latency_ms=elapsed,
        raw_status=str(inner.get("processing_status") or ""),
    )


def _poll_intron_status(file_id: str, api_key: str, attempts: int = 20) -> dict[str, Any] | None:
    url = INTRON_STATUS_URL.format(file_id=file_id)
    for _ in range(attempts):
        status, _, data = http_request(
            "GET",
            url,
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=30.0,
        )
        payload = parse_json(data)
        inner = payload.get("data") if isinstance(payload, dict) else {}
        if not isinstance(inner, dict):
            inner = {}
        proc = str(inner.get("processing_status") or "")
        if proc == "FILE_TRANSCRIBED" or inner.get("audio_transcript"):
            return inner
        if proc == "FILE_PROCESSING_FAILED" or status >= 400:
            return inner
        time.sleep(2.0)
    return None


def transcribe_sunbird(
    audio_path: Path,
    language_code: str,
    api_key: str,
) -> TranscriptResult:
    blob = audio_path.read_bytes()
    body, content_type = _multipart_body(
        {"language": language_code},
        {"audio": (audio_path.name, blob, "audio/wav")},
    )
    started = time.perf_counter()
    status, _, data = http_request(
        "POST",
        SUNBIRD_URL,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Accept": "application/json",
            "Content-Type": content_type,
        },
        body=body,
        timeout=120.0,
    )
    elapsed = int((time.perf_counter() - started) * 1000)
    payload = parse_json(data)
    transcript = ""
    if isinstance(payload, dict):
        transcript = str(
            payload.get("audio_transcription")
            or payload.get("transcription")
            or payload.get("text")
            or ""
        ).strip()
    if status >= 400 or not transcript:
        return TranscriptResult(
            provider="sunbird",
            clip_id="",
            ok=False,
            transcript="",
            latency_ms=elapsed,
            error=f"HTTP {status}: {payload}",
        )
    return TranscriptResult(
        provider="sunbird",
        clip_id="",
        ok=True,
        transcript=transcript,
        latency_ms=elapsed,
    )


def transcribe_whisper(
    audio_path: Path,
    language_name: str,
    reference: str,
    *,
    score_url: str,
    token: str,
) -> TranscriptResult:
    """Hit LingAfriq `POST /api/v2/asr/score` (Whisper sidecar via Node)."""
    blob = audio_path.read_bytes()
    body, content_type = _multipart_body(
        {
            "target_text": reference,
            "language": language_name,
            "model_size": os.environ.get("ASR_MODEL_SIZE", "small"),
        },
        {"audio": (audio_path.name, blob, "audio/wav")},
    )
    headers = {"Accept": "application/json", "Content-Type": content_type}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    started = time.perf_counter()
    status, _, data = http_request(
        "POST",
        score_url,
        headers=headers,
        body=body,
        timeout=90.0,
    )
    elapsed = int((time.perf_counter() - started) * 1000)
    payload = parse_json(data)
    inner = payload
    if isinstance(payload, dict) and isinstance(payload.get("data"), dict):
        inner = payload["data"]
    transcript = ""
    if isinstance(inner, dict):
        transcript = str(inner.get("transcript") or inner.get("text") or "").strip()
    if status >= 400 or not transcript:
        return TranscriptResult(
            provider="whisper",
            clip_id="",
            ok=False,
            transcript="",
            latency_ms=elapsed,
            error=f"HTTP {status}: {payload}",
        )
    return TranscriptResult(
        provider="whisper",
        clip_id="",
        ok=True,
        transcript=transcript,
        latency_ms=elapsed,
    )


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

def load_eval_set(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def pass_threshold(scenario: str, wer: float, thresholds: dict[str, Any]) -> bool:
    mapping = {
        "isolated_word": float(thresholds.get("isolated_word_max_wer", 0.15)),
        "short_phrase": float(thresholds.get("short_phrase_max_wer", 0.20)),
        "code_switch": float(thresholds.get("code_switch_max_wer", 0.35)),
        "learner": float(thresholds.get("short_phrase_max_wer", 0.20)),
    }
    return wer <= mapping.get(scenario, 0.25)


def run_bakeoff(args: argparse.Namespace) -> int:
    spec = load_eval_set(Path(args.eval_set))
    providers_wanted = [p.strip() for p in args.providers.split(",") if p.strip()]
    audio_dir = Path(args.audio_dir)
    clips = spec["clips"]
    if args.priority != "all":
        clips = [c for c in clips if c.get("priority") == args.priority]
    if args.language:
        clips = [c for c in clips if c.get("language") == args.language]

    intron_key = os.environ.get("INTRON_API_KEY", "").strip()
    sunbird_key = os.environ.get("SUNBIRD_API_TOKEN", "").strip() or os.environ.get(
        "AUTH_TOKEN", ""
    ).strip()
    whisper_url = (
        os.environ.get("LINGAFRIQ_ASR_URL", "").strip()
        or f"{os.environ.get('BACKEND_URL', 'https://admin.lingafriq.com').rstrip('/')}/api/v2/asr/score"
    )
    whisper_token = (
        os.environ.get("LINGAFRIQ_AUTH_TOKEN", "").strip()
        or os.environ.get("ASR_INTERNAL_TOKEN", "").strip()
    )

    available = {
        "intron": bool(intron_key),
        "sunbird": bool(sunbird_key),
        "whisper": bool(whisper_token) or args.allow_whisper_unauth,
    }

    rows: list[dict[str, Any]] = []
    skipped_audio = 0

    for clip in clips:
        audio_path = audio_dir / clip["audio"]
        if not audio_path.is_file():
            skipped_audio += 1
            if args.dry_run:
                print(f"[dry-run] {clip['id']}: missing {audio_path.name}")
            continue
        if args.dry_run:
            print(f"[dry-run] {clip['id']} {clip['language']} {clip['scenario']}")
            continue

        for provider in providers_wanted:
            if not available.get(provider):
                rows.append(
                    {
                        "clip_id": clip["id"],
                        "language": clip["language"],
                        "scenario": clip["scenario"],
                        "provider": provider,
                        "ok": False,
                        "error": f"{provider} credentials missing",
                        "wer": None,
                    }
                )
                continue
            codes = spec["providers"][provider]["stt_codes"]
            started = time.perf_counter()
            try:
                if provider == "intron":
                    result = transcribe_intron(audio_path, codes[clip["language"]], intron_key)
                elif provider == "sunbird":
                    result = transcribe_sunbird(
                        audio_path, codes[clip["language"]], sunbird_key
                    )
                else:
                    lang_field = spec["providers"]["whisper"]["lingafriq_language_field"][
                        clip["language"]
                    ]
                    result = transcribe_whisper(
                        audio_path,
                        lang_field,
                        clip["reference"],
                        score_url=whisper_url,
                        token=whisper_token,
                    )
            except Exception as exc:  # noqa: BLE001 — probe must keep going
                result = TranscriptResult(
                    provider=provider,
                    clip_id=clip["id"],
                    ok=False,
                    transcript="",
                    latency_ms=int((time.perf_counter() - started) * 1000),
                    error=str(exc),
                )
            result.clip_id = clip["id"]
            wer = (
                word_error_rate(clip["reference"], result.transcript)
                if result.ok
                else None
            )
            cer = (
                char_error_rate(clip["reference"], result.transcript)
                if result.ok
                else None
            )
            rows.append(
                {
                    "clip_id": clip["id"],
                    "language": clip["language"],
                    "scenario": clip["scenario"],
                    "priority": clip["priority"],
                    "speaker": clip["speaker"],
                    "reference": clip["reference"],
                    "provider": provider,
                    "ok": result.ok,
                    "transcript": result.transcript,
                    "wer": None if wer is None else round(wer, 4),
                    "cer": None if cer is None else round(cer, 4),
                    "latency_ms": result.latency_ms,
                    "pass": (
                        pass_threshold(clip["scenario"], wer, spec["decision_thresholds"])
                        if wer is not None
                        else False
                    ),
                    "error": result.error,
                }
            )
            time.sleep(args.sleep)

    if args.dry_run:
        print(
            f"Clips selected: {len(clips)}; audio missing: {skipped_audio}; "
            f"providers: {providers_wanted}"
        )
        print(
            "Keys present: "
            f"intron={bool(intron_key)} sunbird={bool(sunbird_key)} "
            f"whisper_token={bool(whisper_token)}"
        )
        return 0 if clips else 1

    summary = _summarize(rows, providers_wanted)
    out = {
        "eval_set": spec["name"],
        "whisper_url": whisper_url,
        "clip_count": len(clips),
        "audio_missing": skipped_audio,
        "rows": rows,
        "summary": summary,
    }
    results_dir = Path(args.results_dir)
    results_dir.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    out_path = results_dir / f"bakeoff-{stamp}.json"
    out_path.write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    _print_table(summary)
    print(f"\nWrote {out_path}")
    if skipped_audio == len(clips):
        print(
            "No audio files found. Drop 16 kHz mono WAVs into "
            f"{audio_dir} using the names in eval_set.json.",
            file=sys.stderr,
        )
        return 2
    return 0


def _summarize(rows: list[dict[str, Any]], providers: list[str]) -> dict[str, Any]:
    summary: dict[str, Any] = {}
    for provider in providers:
        subset = [r for r in rows if r["provider"] == provider and r.get("wer") is not None]
        if not subset:
            summary[provider] = {"n": 0, "mean_wer": None, "pass_rate": None}
            continue
        mean_wer = sum(r["wer"] for r in subset) / len(subset)
        by_scenario: dict[str, list[float]] = {}
        for r in subset:
            by_scenario.setdefault(r["scenario"], []).append(r["wer"])
        summary[provider] = {
            "n": len(subset),
            "mean_wer": round(mean_wer, 4),
            "pass_rate": round(sum(1 for r in subset if r["pass"]) / len(subset), 4),
            "mean_latency_ms": round(
                sum(r["latency_ms"] for r in subset) / len(subset)
            ),
            "by_scenario": {
                k: round(sum(v) / len(v), 4) for k, v in sorted(by_scenario.items())
            },
        }
    return summary


def _print_table(summary: dict[str, Any]) -> None:
    print("\nprovider        n  mean_wer  pass_rate  latency_ms")
    for provider, stats in summary.items():
        n = stats["n"]
        wer = stats["mean_wer"]
        pr = stats["pass_rate"]
        lat = stats.get("mean_latency_ms")
        wer_s = "   n/a " if wer is None else f"{wer:7.3f}"
        pr_s = "   n/a " if pr is None else f"{pr:7.3f}"
        lat_s = "   n/a" if not lat else f"{lat:8.0f}"
        print(f"{provider:14} {n:2} {wer_s}  {pr_s}  {lat_s}")


# ---------------------------------------------------------------------------
# Self-test (no network)
# ---------------------------------------------------------------------------

def self_test() -> int:
    spec = load_eval_set(EVAL_SET_PATH)
    ids = {c["id"] for c in spec["clips"]}
    assert "yo-cs-01" in ids
    assert "pcm-cs-01" in ids
    langs = {c["language"] for c in spec["clips"]}
    for required in (
        "yoruba",
        "hausa",
        "igbo",
        "pidgin",
        "swahili",
        "zulu",
        "xhosa",
        "amharic",
        "twi",
        "wolof",
        "afrikaans",
    ):
        assert required in langs, required
    for provider in ("intron", "sunbird", "whisper"):
        codes = spec["providers"][provider]["stt_codes"]
        for lang in langs:
            assert lang in codes, f"{provider} missing {lang}"

    assert word_error_rate("how you dey", "how you dey") == 0.0
    wer = word_error_rate("Please wait, e joor", "please wait e joor")
    assert wer == 0.0, wer
    # One substitution in a 4-word phrase.
    assert abs(word_error_rate("how you dey now", "how you dey nah") - 0.25) < 1e-9
    assert char_error_rate("ruwa", "ruwa") == 0.0
    assert pass_threshold("isolated_word", 0.0, spec["decision_thresholds"])
    assert not pass_threshold("isolated_word", 0.5, spec["decision_thresholds"])
    print("self-test ok")
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--eval-set", default=str(EVAL_SET_PATH))
    p.add_argument("--audio-dir", default=str(ROOT / "audio"))
    p.add_argument("--results-dir", default=str(ROOT / "results"))
    p.add_argument(
        "--providers",
        default="intron,sunbird,whisper",
        help="Comma list: intron,sunbird,whisper",
    )
    p.add_argument("--priority", choices=("core", "stretch", "all"), default="core")
    p.add_argument("--language", default="", help="Restrict to one hub slug")
    p.add_argument("--sleep", type=float, default=0.4, help="Seconds between API calls")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument(
        "--allow-whisper-unauth",
        action="store_true",
        help="Call LingAfriq ASR without a bearer token (local sidecar only)",
    )
    p.add_argument("--self-test", action="store_true")
    return p


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    if args.self_test:
        return self_test()
    return run_bakeoff(args)


if __name__ == "__main__":
    raise SystemExit(main())
