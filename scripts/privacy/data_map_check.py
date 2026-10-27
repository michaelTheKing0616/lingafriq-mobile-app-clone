#!/usr/bin/env python3
"""P10-920: Validate Mongo data map coverage and RETENTION.yaml schema.

Discovers Mongoose models under node-backend/src/models (and admin history quiz model).
Fails CI when a registered model is missing from RETENTION.yaml or schema is invalid.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = ROOT.parent
BACKEND_MODELS = REPO_ROOT / "node-backend" / "src" / "models"
BACKEND_ADMIN_MODEL = REPO_ROOT / "node-backend" / "src" / "routes" / "admin" / "historyQuiz.model.ts"
BACKEND_PURGE_LOG_MODEL = REPO_ROOT / "node-backend" / "src" / "models" / "PurgeLog.ts"
RETENTION_PATH = ROOT / "docs" / "privacy" / "RETENTION.yaml"
DATA_MAP_PATH = ROOT / "docs" / "privacy" / "DATA_MAP.md"

MODEL_RE = re.compile(
    r"(?:mongoose\.)?model(?:<[^>]+>)?\(\s*['\"]([^'\"]+)['\"]",
    re.MULTILINE,
)
COLLECTION_RE = re.compile(r"collection:\s*['\"]([^'\"]+)['\"]")
THIRD_ARG_COLL_RE = re.compile(
    r"model(?:<[^>]+>)?\(\s*['\"][^'\"]+['\"]\s*,\s*[^,]+,\s*['\"]([^'\"]+)['\"]",
)

VOICE_HINTS = (
    "voice",
    "audio",
    "recording",
    "polie",
    "mentor",
    "call",
    "snap",
    "speak",
    "pronunciation",
    "scorer",
    "lexiconaudio",
    "pointandsay",
    "proficiency",
    "personalitychat",
    "syntheticvoice",
)
MINOR_HINTS = ("user", "onboarding", "guardian", "passkey", "learner", "child")


def _pluralize_model(name: str) -> str:
    if name.endswith("s"):
        return name.lower()
    if name.endswith("y") and len(name) > 1 and name[-2] not in "aeiou":
        return (name[:-1] + "ies").lower()
    return (name[0].lower() + name[1:] + "s") if name else name.lower()


def discover_models() -> dict[str, dict[str, str]]:
    """Return map collection_name -> {model, source_file}."""
    files: list[Path] = []
    if BACKEND_MODELS.is_dir():
        files.extend(sorted(BACKEND_MODELS.rglob("*.model.ts")))
    if BACKEND_ADMIN_MODEL.is_file():
        files.append(BACKEND_ADMIN_MODEL)
    if BACKEND_PURGE_LOG_MODEL.is_file():
        files.append(BACKEND_PURGE_LOG_MODEL)

    discovered: dict[str, dict[str, str]] = {}
    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        collections = list(COLLECTION_RE.findall(text))
        third = list(THIRD_ARG_COLL_RE.findall(text))
        names = MODEL_RE.findall(text)
        if not names:
            continue
        rel = str(path.relative_to(REPO_ROOT))
        for idx, model_name in enumerate(names):
            coll = None
            if idx < len(third):
                coll = third[idx]
            elif collections:
                coll = collections[min(idx, len(collections) - 1)]
            else:
                coll = _pluralize_model(model_name)
            if coll in discovered and discovered[coll]["model"] != model_name:
                coll = f"{coll}__{model_name.lower()}"
            discovered[coll] = {"model": model_name, "source": rel}
    return discovered


def _is_high_risk(collection: str, model: str) -> bool:
    blob = (collection + model).lower()
    if any(h in blob for h in VOICE_HINTS):
        return True
    return any(h in blob for h in MINOR_HINTS) and "badge" not in blob


def _default_entry(collection: str, meta: dict[str, str]) -> dict[str, Any]:
    model = meta["model"]
    high = _is_high_risk(collection, model)
    blob = (collection + model).lower()
    if "config" in blob or "catalog" in blob or "template" in blob or model in {
        "Language",
        "Grammar",
        "Lesson",
        "Item",
        "Badge",
        "FeatureFlag",
    }:
        personal: list[str] = []
        purpose = "Curriculum, product configuration, or reference catalogue"
        basis = "legitimate_interest"
        retention: dict[str, Any] = {"keep_until": "content_deprecation_or_superseded"}
    elif high and any(v in blob for v in VOICE_HINTS):
        personal = ["user_id", "audio_blob_or_url", "transcript_metadata"]
        purpose = "Speech practice, scoring, or licensed voice assets"
        basis = "consent"
        retention = {
            "days": 0,
            "note": "Delete raw audio after scoring unless separate training consent (P10-923)",
        }
    elif high:
        personal = ["user_id", "birth_year_or_age_band", "guardian_consent_metadata"]
        purpose = "Account, learner profile, or child-safety policy"
        basis = "contract"
        retention = {"keep_until": "account_deletion"}
    elif "telemetry" in blob or "analytics" in blob or "audit" in blob or "log" in blob:
        personal = ["pseudonymous_user_id", "event_payload"]
        purpose = "Security, reliability, and product analytics"
        basis = "legitimate_interest"
        retention = {"days": 365}
    elif "message" in blob or "chat" in blob or "feed" in blob or "snap" in blob:
        personal = ["user_id", "message_body", "media_metadata"]
        purpose = "Social and messaging features"
        basis = "contract"
        retention = {"keep_until": "account_deletion"}
    else:
        personal = ["user_id"]
        purpose = "Learning progress and gamification state"
        basis = "contract"
        retention = {"keep_until": "account_deletion"}

    entry: dict[str, Any] = {
        "model": model,
        "source": meta["source"],
        "owner": "node-backend-platform",
        "purpose": purpose,
        "legal_basis": basis,
        "personal_data_fields": personal,
        "retention": retention,
    }
    if high:
        entry["high_risk"] = True
        if "audio" in blob or "voice" in blob or "recording" in blob:
            entry["default_deletion_rule"] = "delete_raw_audio_after_scoring_unless_training_opt_in"
        elif "user" in blob or "onboarding" in blob or "passkey" in blob:
            entry["default_deletion_rule"] = "erase_on_account_deletion_and_guardian_request"
        else:
            entry["default_deletion_rule"] = "apply_collection_retention_job"
    else:
        entry["high_risk"] = False
    return entry


def validate_retention_doc(doc: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    cols = doc.get("collections")
    if not isinstance(cols, dict):
        return ["collections must be a mapping"]
    for coll, entry in cols.items():
        if not isinstance(entry, dict):
            errors.append(f"{coll}: entry must be a mapping")
            continue
        for key in ("owner", "purpose", "legal_basis", "personal_data_fields", "retention"):
            if key not in entry:
                errors.append(f"{coll}: missing {key}")
        ret = entry.get("retention")
        if isinstance(ret, dict):
            has_days = ret.get("days") is not None
            has_keep = bool(ret.get("keep_until"))
            if not has_days and not has_keep:
                errors.append(f"{coll}: retention needs days or keep_until")
            if has_days and not isinstance(ret.get("days"), int):
                errors.append(f"{coll}: retention.days must be integer")
        else:
            errors.append(f"{coll}: retention must be a mapping")
        if entry.get("high_risk") and not entry.get("default_deletion_rule"):
            errors.append(f"{coll}: high_risk requires default_deletion_rule")
    return errors


def check_coverage(discovered: dict[str, dict[str, str]], doc: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    mapped = set((doc.get("collections") or {}).keys())
    for coll in sorted(discovered):
        if coll not in mapped:
            errors.append(f"missing from RETENTION.yaml: {coll} ({discovered[coll]['model']})")
    extra = mapped - set(discovered)
    for coll in sorted(extra):
        errors.append(f"stale RETENTION.yaml entry (no model file): {coll}")
    return errors


def render_data_map(doc: dict[str, Any], discovered: dict[str, dict[str, str]]) -> str:
    cols = doc.get("collections") or {}
    high = [c for c, e in cols.items() if e.get("high_risk")]
    lines = [
        "# LingAfriq data map (P10-920)",
        "",
        "Machine-readable retention schedule: [`RETENTION.yaml`](./RETENTION.yaml).",
        "Counsel review for NDPC/DPIA remains **EXT-18** (not a substitute for legal sign-off).",
        "",
        f"- **Mongo collections mapped:** {len(cols)} (discovered models: {len(discovered)})",
        f"- **High-risk (voice / minors):** {len(high)}",
        "",
        "## High-risk collections",
        "",
        "| Collection | Model | Default deletion rule | Retention |",
        "|---|---|---|---|",
    ]
    for coll in sorted(high):
        e = cols[coll]
        ret = e.get("retention") or {}
        if ret.get("days") is not None:
            ret_s = f"{ret['days']} days"
        else:
            ret_s = f"keep_until={ret.get('keep_until', '?')}"
        lines.append(
            f"| `{coll}` | {e.get('model', '?')} | {e.get('default_deletion_rule', '—')} | {ret_s} |"
        )
    lines.extend(
        [
            "",
            "## CI",
            "",
            "Run `python3 scripts/privacy/data_map_check.py --gate` in CI; fails when a new",
            "`*.model.ts` is added without a matching `RETENTION.yaml` row.",
            "",
        ]
    )
    return "\n".join(lines)


def bootstrap_retention(discovered: dict[str, dict[str, str]]) -> dict[str, Any]:
    return {
        "version": 1,
        "card": "P10-920",
        "collections": {
            coll: _default_entry(coll, meta) for coll, meta in sorted(discovered.items())
        },
    }


def run_self_test() -> int:
    errors: list[str] = []
    sample = {
        "collections": {
            "users": {
                "owner": "platform",
                "purpose": "auth",
                "legal_basis": "contract",
                "personal_data_fields": ["email"],
                "retention": {"keep_until": "account_deletion"},
                "high_risk": True,
                "default_deletion_rule": "erase_on_account_deletion",
            },
            "logs": {
                "owner": "platform",
                "purpose": "ops",
                "legal_basis": "legitimate_interest",
                "personal_data_fields": [],
                "retention": {"days": 30},
                "high_risk": False,
            },
        }
    }
    errors.extend(validate_retention_doc(sample))
    if errors:
        print("self-test failed:", errors)
        return 1
    bad = {"collections": {"x": {"owner": "a"}}}
    if not validate_retention_doc(bad):
        print("self-test failed: expected validation errors for incomplete entry")
        return 1
    print("self-test ok")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gate", action="store_true", help="Exit 1 on any validation/coverage error")
    parser.add_argument("--self-test", action="store_true", help="Run built-in schema tests")
    parser.add_argument(
        "--bootstrap",
        action="store_true",
        help="Regenerate RETENTION.yaml + DATA_MAP.md from discovered models (maintainer)",
    )
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    discovered = discover_models()
    if not discovered:
        print("No models discovered under node-backend", file=sys.stderr)
        return 1

    if args.bootstrap:
        doc = bootstrap_retention(discovered)
        RETENTION_PATH.parent.mkdir(parents=True, exist_ok=True)
        RETENTION_PATH.write_text(
            yaml.safe_dump(doc, sort_keys=False, allow_unicode=True, width=120),
            encoding="utf-8",
        )
        DATA_MAP_PATH.write_text(render_data_map(doc, discovered), encoding="utf-8")
        print(f"wrote {RETENTION_PATH} ({len(doc['collections'])} collections)")
        print(f"wrote {DATA_MAP_PATH}")
        return 0

    if not RETENTION_PATH.is_file():
        print(f"Missing {RETENTION_PATH}; run with --bootstrap once", file=sys.stderr)
        return 1

    doc = yaml.safe_load(RETENTION_PATH.read_text(encoding="utf-8")) or {}
    errors = validate_retention_doc(doc)
    errors.extend(check_coverage(discovered, doc))

    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        return 1 if args.gate else 0

    print(f"data map ok ({len(discovered)} models, {len(doc.get('collections') or {})} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
