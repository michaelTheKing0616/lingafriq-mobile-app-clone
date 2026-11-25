#!/usr/bin/env python3
"""P10-940: Three-part error copy and village-voice scope for app_en.arb."""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_ARB = ROOT / "lib" / "l10n" / "app_en.arb"
MARKERS_PATH = Path(__file__).resolve().parent / "village_voice_markers.txt"

WORD_RE = re.compile(r"[A-Za-z']+")
PLACEHOLDER_RE = re.compile(r"\{[^}]+\}")

# System-scope keys that are never three-part errors (actions, not messages).
ERROR_EXEMPT_KEYS = frozenset({"tryAgain"})

HAPPENED_RE = re.compile(
    r"\b("
    r"could\s*n'?t|could not|cannot|can'?t|did not|does not|do not|"
    r"is not|are not|was not|were not|not available|unavailable|"
    r"missing|failed|failure|lost|disconnected|blocked|rejected|"
    r"went wrong|hit a|something went wrong|invalid|error"
    r")\b",
    re.IGNORECASE,
)

NEXT_STEP_RE = re.compile(
    r"\b("
    r"try again|retry|tap|pull|open|go back|wait|leave|start|reconnect|"
    r"allow|check|hear|type|restart|refresh|continue|turn on|enable"
    r")\b",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class CopyFinding:
    key: str
    rule: str
    message: str


def load_village_markers(path: Path) -> list[str]:
    markers: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        token = line.strip()
        if not token or token.startswith("#"):
            continue
        markers.append(token)
    return markers


def parse_arb(path: Path) -> tuple[dict[str, str], dict[str, dict]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    strings: dict[str, str] = {}
    meta: dict[str, dict] = {}
    for key, value in data.items():
        if key.startswith("@@"):
            continue
        if key.startswith("@") and isinstance(value, dict):
            meta[key[1:]] = value
        elif isinstance(value, str) and not key.startswith("@"):
            strings[key] = value
    return strings, meta


def is_character_dialogue(key: str, meta: dict[str, dict]) -> bool:
    entry = meta.get(key) or {}
    voice = entry.get("voice")
    if isinstance(voice, str) and voice.lower() == "character":
        return True
    if key.startswith("character_dialogue_") or key.startswith("persona_dialogue_"):
        return True
    return False


def is_error_string(key: str, meta: dict[str, dict]) -> bool:
    if key in ERROR_EXEMPT_KEYS:
        return False
    if key.endswith("Button") or key.endswith("Action"):
        return False
    entry = meta.get(key)
    if entry:
        desc = entry.get("description", "")
        if isinstance(desc, str):
            lower = desc.lower()
            if "error when" in lower or "error shown" in lower or "error message" in lower:
                return True
            if lower.startswith("route error"):
                return True
            if "shown when" in lower and "fail" in lower:
                return True
    key_lower = key.lower()
    if "error" in key_lower or key_lower.endswith("failed"):
        return True
    if "_unavailable" in key_lower:
        return True
    if key_lower.endswith("_retry") and "error" in key_lower:
        return True
    return False


def normalize_for_sentences(text: str) -> str:
    return PLACEHOLDER_RE.sub("detail", text).strip()


def split_sentences(text: str) -> list[str]:
    normalized = normalize_for_sentences(text)
    if not normalized:
        return []
    parts = [p.strip() for p in re.split(r"(?<=[.!?])\s+", normalized) if p.strip()]
    return parts


def lint_three_part_error(key: str, text: str) -> CopyFinding | None:
    parts = split_sentences(text)
    if len(parts) < 3:
        return CopyFinding(
            key,
            "ERROR_THREE_PART",
            f"{key}: error copy needs what happened, why, and what next (got {len(parts)} sentence(s))",
        )
    if not HAPPENED_RE.search(parts[0]):
        return CopyFinding(
            key,
            "ERROR_WHAT",
            f"{key}: first sentence must state what happened",
        )
    why = " ".join(parts[1:-1])
    if len(WORD_RE.findall(why)) < 2:
        return CopyFinding(
            key,
            "ERROR_WHY",
            f"{key}: middle sentence(s) must explain why",
        )
    if not NEXT_STEP_RE.search(parts[-1]):
        return CopyFinding(
            key,
            "ERROR_NEXT",
            f"{key}: final sentence must tell the learner what to do next",
        )
    return None


def lint_village_voice_scope(
    key: str, text: str, meta: dict[str, dict], markers: list[str]
) -> CopyFinding | None:
    if is_character_dialogue(key, meta):
        return None
    lower = text.lower()
    for marker in markers:
        if marker.startswith("re:"):
            if re.search(marker[3:], lower):
                return CopyFinding(
                    key,
                    "VILLAGE_VOICE_SYSTEM",
                    f"{key}: village-voice marker in system copy ({marker})",
                )
        elif re.search(rf"\b{re.escape(marker)}\b", lower):
            return CopyFinding(
                key,
                "VILLAGE_VOICE_SYSTEM",
                f"{key}: village-voice marker in system copy ({marker})",
            )
    return None


def lint_arb(arb_path: Path, markers_path: Path) -> list[CopyFinding]:
    markers = load_village_markers(markers_path)
    strings, meta = parse_arb(arb_path)
    findings: list[CopyFinding] = []
    for key, text in strings.items():
        village_issue = lint_village_voice_scope(key, text, meta, markers)
        if village_issue:
            findings.append(village_issue)
        if is_error_string(key, meta):
            err = lint_three_part_error(key, text)
            if err:
                findings.append(err)
    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description="Lint error copy and village voice (P10-940)")
    parser.add_argument("--arb", type=Path, default=DEFAULT_ARB)
    parser.add_argument("--markers", type=Path, default=MARKERS_PATH)
    args = parser.parse_args()

    if not args.arb.is_file():
        print(f"ARB file missing: {args.arb}", file=sys.stderr)
        return 1
    if not args.markers.is_file():
        print(f"Village markers file missing: {args.markers}", file=sys.stderr)
        return 1

    findings = lint_arb(args.arb, args.markers)
    if findings:
        for f in findings:
            print(f"{f.rule}: {f.message}", file=sys.stderr)
        return 1
    strings, _ = parse_arb(args.arb)
    print(f"OK: {args.arb} ({len(strings)} strings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
