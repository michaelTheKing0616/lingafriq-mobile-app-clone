#!/usr/bin/env python3
"""P9-934: Gate safety lead, incident response, and moderator training artefacts."""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
INCIDENT_PATH = ROOT / "docs" / "safety" / "INCIDENT_RESPONSE.md"
TRAINING_PATH = ROOT / "docs" / "safety" / "MODERATOR_TRAINING.md"
GROOMING_RULES = (
    ROOT.parent / "node-backend" / "src" / "services" / "moderation" / "groomingRules.json"
)

FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
HEADING_RE = re.compile(r"^## (.+)$", re.MULTILINE)

REQUIRED_IR_SECTIONS = {
    "detection": "Detection",
    "containment": "Containment",
    "notification": "Notification",
    "regulator_and_hotline_reporting": "Regulator and hotline reporting",
    "post_incident_review": "Post-incident review",
}


def load_md(path: Path) -> tuple[dict, str]:
    text = path.read_text(encoding="utf-8")
    m = FM_RE.match(text)
    if not m:
        raise ValueError(f"{path.name}: missing YAML front matter")
    meta = yaml.safe_load(m.group(1)) or {}
    return meta, text[m.end() :]


def check_incident(errors: list[str]) -> None:
    if not INCIDENT_PATH.is_file():
        errors.append("INCIDENT_RESPONSE.md missing")
        return
    try:
        meta, body = load_md(INCIDENT_PATH)
    except ValueError as exc:
        errors.append(str(exc))
        return

    lead = meta.get("safety_lead") or {}
    deputy = meta.get("deputy_safety_lead") or {}
    for field, obj in (("safety_lead", lead), ("deputy_safety_lead", deputy)):
        for key in ("name", "contact_email"):
            if not (obj.get(key) or "").strip():
                errors.append(f"{field} missing {key}")

    sig = meta.get("owner_signature") or {}
    if (sig.get("signed_by") or "").strip() != "Tope":
        errors.append("owner_signature.signed_by must be Tope")
    if not sig.get("signed_date"):
        errors.append("owner_signature.signed_date required")

    tabletop = meta.get("tabletop_exercise") or {}
    if not tabletop.get("last_completed"):
        errors.append("tabletop_exercise.last_completed required")

    declared = meta.get("incident_response_sections") or []
    headings = {h.strip() for h in HEADING_RE.findall(body)}
    for key in REQUIRED_IR_SECTIONS:
        if key not in declared:
            errors.append(f"incident_response_sections missing {key}")
    for _key, title in REQUIRED_IR_SECTIONS.items():
        if title not in headings:
            errors.append(f"INCIDENT_RESPONSE.md missing heading: {title}")


def check_training(errors: list[str]) -> None:
    if not TRAINING_PATH.is_file():
        errors.append("MODERATOR_TRAINING.md missing")
        return
    try:
        meta, body = load_md(TRAINING_PATH)
    except ValueError as exc:
        errors.append(str(exc))
        return

    if not meta.get("grooming_training_required"):
        errors.append("grooming_training_required must be true")

    modules = meta.get("training_modules") or []
    grooming = [m for m in modules if m.get("id") == "mod-102"]
    if not grooming:
        errors.append("training_modules must include mod-102 grooming module")
    elif "grooming" not in (grooming[0].get("title") or "").lower():
        errors.append("mod-102 title must reference grooming")

    if "grooming-pattern" not in body.lower() and "grooming" not in body.lower():
        errors.append("MODERATOR_TRAINING body must cover grooming patterns")

    if GROOMING_RULES.is_file():
        if "groomingRules.json" not in body:
            errors.append("training must cite groomingRules.json")
    else:
        errors.append(f"grooming rules source missing: {GROOMING_RULES}")

    active = meta.get("active_moderators") or []
    if not active:
        errors.append("active_moderators must list at least one moderator")
    required_modules = {m.get("id") for m in modules if m.get("id")}
    for row in active:
        mid = row.get("moderator_id")
        if not mid:
            errors.append("active_moderator missing moderator_id")
            continue
        if not row.get("completed_at"):
            errors.append(f"moderator {mid} missing completed_at")
        done = set(row.get("modules_completed") or [])
        if not done >= {m for m in required_modules if m.startswith("mod-")}:
            errors.append(f"moderator {mid} incomplete modules_completed")


def run_gate() -> list[str]:
    errors: list[str] = []
    check_incident(errors)
    check_training(errors)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Run gate (default)")
    _ = parser.parse_args()
    errors = run_gate()
    if errors:
        for e in errors:
            print(f"safety_ops_check: {e}", file=sys.stderr)
        return 1
    print("safety_ops_check: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
