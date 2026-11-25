#!/usr/bin/env python3
"""P10-927: Plain-language privacy policy — readability and data-map coverage."""
from __future__ import annotations

import argparse
import math
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
POLICY_PATH = ROOT / "docs" / "privacy" / "PRIVACY_POLICY.md"
RETENTION_PATH = ROOT / "docs" / "privacy" / "RETENTION.yaml"

FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
HEADING_RE = re.compile(r"^## (.+)$", re.MULTILINE)
GLOSSARY_ROW_RE = re.compile(r"^\| ([^|]+) \|", re.MULTILINE)


def load_policy() -> tuple[dict, str]:
    text = POLICY_PATH.read_text(encoding="utf-8")
    m = FM_RE.match(text)
    if not m:
        raise ValueError("PRIVACY_POLICY.md: missing YAML front matter")
    meta = yaml.safe_load(m.group(1)) or {}
    body = text[m.end() :]
    return meta, body


def flesch_kincaid_grade(text: str) -> float:
    sentences = max(1, len(re.findall(r"[.!?]+", text)))
    words = re.findall(r"[A-Za-z']+", text)
    word_count = max(1, len(words))
    syllables = 0
    for w in words:
        w = w.lower()
        groups = re.findall(r"[aeiouy]+", w)
        syllables += max(1, len(groups))
    return 0.39 * (word_count / sentences) + 11.8 * (syllables / word_count) - 15.59


def run_gate() -> list[str]:
    errors: list[str] = []
    if not POLICY_PATH.is_file():
        return ["PRIVACY_POLICY.md missing"]
    try:
        meta, body = load_policy()
    except ValueError as exc:
        return [str(exc)]

    for key in ("version", "effective_date", "policy_purposes"):
        if not meta.get(key):
            errors.append(f"front matter missing {key}")

    purposes = meta.get("policy_purposes") or []
    headings = {h.strip() for h in HEADING_RE.findall(body)}
    for purpose in purposes:
        if purpose not in headings:
            errors.append(f"missing section for data-map purpose: {purpose}")

    retention = yaml.safe_load(RETENTION_PATH.read_text(encoding="utf-8")) or {}
    coll = retention.get("collections") or {}
    map_purposes = {v.get("purpose") for v in coll.values() if v.get("purpose")}
    listed = set(purposes)
    if map_purposes != listed:
        missing = map_purposes - listed
        extra = listed - map_purposes
        if missing:
            errors.append(f"policy_purposes missing retention purposes: {sorted(missing)}")
        if extra:
            errors.append(f"policy_purposes not in retention map: {sorted(extra)}")

    readable_body = body.split("## Words we use", 1)[0]
    grade = flesch_kincaid_grade(readable_body)
    if round(grade, 1) > 8.0:
        errors.append(f"readability grade {grade:.1f} exceeds 8.0 (Flesch-Kincaid)")

    glossary_terms = [
        line.group(1).strip()
        for line in GLOSSARY_ROW_RE.finditer(body)
        if not line.group(1).strip().startswith("---") and line.group(1).strip() != "Term"
    ]
    if len(glossary_terms) < 4:
        errors.append("glossary must define at least four legal terms")

    for phrase in (
        "delete raw audio after scoring",
        "guardian",
        "minors are not offered",
        "opt-in",
    ):
        if phrase.lower() not in body.lower():
            errors.append(f"missing required phrase: {phrase}")

    for purpose in purposes:
        section = _section_text(body, purpose)
        for label in ("What we collect", "Why", "How long", "Who sees it"):
            if label not in section:
                errors.append(f"{purpose}: missing '{label}'")

    return errors


def _section_text(body: str, heading: str) -> str:
    pattern = rf"^## {re.escape(heading)}\s*\n(.*?)(?=^## |\Z)"
    m = re.search(pattern, body, re.MULTILINE | re.DOTALL)
    return m.group(1) if m else ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--gate", action="store_true")
    args = parser.parse_args()
    errors = run_gate()
    if errors:
        for e in errors:
            print(e, file=sys.stderr)
        return 1
    if args.gate:
        print("privacy_policy_check: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
