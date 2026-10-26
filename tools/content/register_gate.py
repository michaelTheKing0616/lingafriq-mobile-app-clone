"""Publish gate for register and honorific practice units (P5-036)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-036"
REGISTER_DATA_REL = "assets/data/units/register"

CODE_REGISTER_UNREVIEWED = "RegisterUnreviewed"
CODE_REGISTER_NOTES_ONLY = "RegisterNotesOnly"
CODE_REGISTER_FORMAL_REQUIRED = "RegisterFormalRequired"
CODE_REGISTER_UNCITED = "RegisterUncited"

RULE_RG001 = "RG-001"
RULE_RG002 = "RG-002"
RULE_RG003 = "RG-003"
RULE_RG004 = "RG-004"

STAGE1_LANGUAGES: tuple[str, ...] = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")
_REQUIRED_UNIT_KEYS: tuple[str, ...] = (
    "greetings_elder",
    "honorific_address",
    "kinship_respect",
)
_EXPERT_OR_BETTER: frozenset[str] = frozenset({"expert_reviewed", "native_verified"})
_PRACTICE_KINDS: frozenset[str] = frozenset(
    {"choose_register", "speak_line", "match_kinship", "listen_choose"}
)


class RegisterGateError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class RegisterFinding:
    code: str
    rule_id: str
    unit_id: str
    detail: str


def register_dir(root: Path | None = None) -> Path:
    return repo_root(root) / REGISTER_DATA_REL


def _unit_id(entry: Mapping[str, Any]) -> str:
    raw = entry.get("id")
    if isinstance(raw, str) and raw.strip():
        return raw.strip()
    return "<unknown>"


def _provenance_source_keys(entry: Mapping[str, Any]) -> set[str]:
    keys: set[str] = set()
    provenance = entry.get("provenance")
    if not isinstance(provenance, Mapping):
        return keys
    sources = provenance.get("sources")
    if not isinstance(sources, list):
        return keys
    for source in sources:
        if not isinstance(source, Mapping):
            continue
        citation = source.get("uri_or_citation")
        if isinstance(citation, str) and citation.strip():
            keys.add(citation.strip())
            if "register:" in citation:
                for part in citation.split(";"):
                    part = part.strip()
                    if part.startswith("register:"):
                        keys.add(part)
    return keys


def _claim_has_citation(claim: Mapping[str, Any], allowed_refs: set[str]) -> bool:
    ref = claim.get("source_ref")
    if not isinstance(ref, str) or not ref.strip():
        return False
    ref = ref.strip()
    if ref in allowed_refs:
        return True
    return any(ref in key or key in ref for key in allowed_refs)


def _has_linguist_approval(entry: Mapping[str, Any]) -> bool:
    review = entry.get("review")
    if not isinstance(review, Mapping):
        return False
    reviewers = review.get("reviewers")
    if not isinstance(reviewers, list):
        return False
    for row in reviewers:
        if not isinstance(row, Mapping):
            continue
        if row.get("approved") is not True:
            continue
        role = row.get("role")
        reviewer_id = row.get("reviewer_id")
        if role == "linguist" and isinstance(reviewer_id, str) and reviewer_id.strip():
            return True
    return False


def _label(entry: Mapping[str, Any]) -> str | None:
    label = entry.get("label")
    if not isinstance(label, str):
        return None
    return label.strip()


def _requires_formal_register(unit: Mapping[str, Any]) -> bool:
    if unit.get("respect_sensitive") is True:
        return True
    ctx = unit.get("addressee_context")
    if isinstance(ctx, str) and ctx.strip().lower() == "elder":
        return True
    req = unit.get("required_register")
    return isinstance(req, str) and req.strip().lower() == "formal"


def _practice_items(unit: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    raw = unit.get("practice_items")
    if not isinstance(raw, list):
        return []
    items: list[Mapping[str, Any]] = []
    for row in raw:
        if isinstance(row, Mapping):
            items.append(row)
    return items


def _option_register(option: Mapping[str, Any]) -> str | None:
    reg = option.get("register")
    if not isinstance(reg, str):
        return None
    return reg.strip().lower()


def _item_register(item: Mapping[str, Any]) -> str | None:
    reg = item.get("register")
    if isinstance(reg, str) and reg.strip():
        return reg.strip().lower()
    role = item.get("role")
    if role == "learner_response" and isinstance(reg, str):
        return reg.strip().lower()
    return None


def _formal_marker_check(unit: Mapping[str, Any], text: str) -> bool:
    markers = unit.get("register_markers")
    if not isinstance(markers, Mapping):
        return True
    forbidden = markers.get("informal_forbidden_in_responses")
    if isinstance(forbidden, list):
        for surface in forbidden:
            if isinstance(surface, str) and surface and surface in text:
                return False
    required_any = markers.get("formal_contains_any")
    if isinstance(required_any, list) and required_any:
        return any(isinstance(s, str) and s and s in text for s in required_any)
    return True


def _practice_requires_formal(item: Mapping[str, Any]) -> bool:
    kind = item.get("kind")
    if isinstance(kind, str) and kind in _PRACTICE_KINDS:
        return True
    return item.get("role") == "learner_response"


def rg_findings(unit: Mapping[str, Any]) -> list[RegisterFinding]:
    uid = _unit_id(unit)
    findings: list[RegisterFinding] = []

    practice = _practice_items(unit)
    if len(practice) < 1:
        findings.append(
            RegisterFinding(
                CODE_REGISTER_NOTES_ONLY,
                RULE_RG003,
                uid,
                "register unit must include at least one practice_items entry",
            )
        )

    respect = unit.get("respect_sensitive") is True or _requires_formal_register(unit)
    if respect:
        label = _label(unit)
        if label not in _EXPERT_OR_BETTER:
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_UNREVIEWED,
                    RULE_RG002,
                    uid,
                    "respect-sensitive unit label must be expert_reviewed or native_verified",
                )
            )
        if label == "beta":
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_UNREVIEWED,
                    RULE_RG002,
                    uid,
                    "respect-sensitive units cannot be Beta",
                )
            )
        if not _has_linguist_approval(unit):
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_UNREVIEWED,
                    RULE_RG003,
                    uid,
                    "respect-sensitive unit requires an approved linguist reviewer",
                )
            )

    allowed = _provenance_source_keys(unit)
    claims = unit.get("claims")
    if not isinstance(claims, list) or len(claims) < 1:
        findings.append(
            RegisterFinding(
                CODE_REGISTER_UNCITED,
                RULE_RG001,
                uid,
                "claims must be a non-empty list",
            )
        )
    elif allowed:
        for index, claim in enumerate(claims):
            if not isinstance(claim, Mapping):
                findings.append(
                    RegisterFinding(
                        CODE_REGISTER_UNCITED,
                        RULE_RG001,
                        uid,
                        f"claims[{index}] must be a mapping",
                    )
                )
                continue
            if not _claim_has_citation(claim, allowed):
                findings.append(
                    RegisterFinding(
                        CODE_REGISTER_UNCITED,
                        RULE_RG001,
                        uid,
                        f"claims[{index}] lacks a citation linked to provenance.sources",
                    )
                )
    else:
        findings.append(
            RegisterFinding(
                CODE_REGISTER_UNCITED,
                RULE_RG001,
                uid,
                "provenance.sources must cite a licensed source",
            )
        )

    if not _requires_formal_register(unit):
        return findings

    for index, item in enumerate(practice):
        if not _practice_requires_formal(item):
            continue
        kind = item.get("kind")
        if kind in ("choose_register", "match_kinship", "listen_choose"):
            options = item.get("options")
            correct = item.get("correct_index")
            if not isinstance(options, list) or not isinstance(correct, int):
                findings.append(
                    RegisterFinding(
                        CODE_REGISTER_FORMAL_REQUIRED,
                        RULE_RG004,
                        uid,
                        f"practice_items[{index}] choose_register needs options and correct_index",
                    )
                )
                continue
            if correct < 0 or correct >= len(options):
                findings.append(
                    RegisterFinding(
                        CODE_REGISTER_FORMAL_REQUIRED,
                        RULE_RG004,
                        uid,
                        f"practice_items[{index}] correct_index out of range",
                    )
                )
                continue
            chosen = options[correct]
            if not isinstance(chosen, Mapping):
                continue
            if _option_register(chosen) != "formal":
                findings.append(
                    RegisterFinding(
                        CODE_REGISTER_FORMAL_REQUIRED,
                        RULE_RG004,
                        uid,
                        f"practice_items[{index}] elder context requires formal correct option",
                    )
                )
            text = chosen.get("text")
            if isinstance(text, str) and not _formal_marker_check(unit, text):
                findings.append(
                    RegisterFinding(
                        CODE_REGISTER_FORMAL_REQUIRED,
                        RULE_RG004,
                        uid,
                        f"practice_items[{index}] correct response violates register_markers",
                    )
                )
            continue

        reg = _item_register(item)
        if reg != "formal":
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_FORMAL_REQUIRED,
                    RULE_RG004,
                    uid,
                    f"practice_items[{index}] must set register formal for elder addressee",
                )
            )
        text = item.get("text")
        if isinstance(text, str) and not _formal_marker_check(unit, text):
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_FORMAL_REQUIRED,
                    RULE_RG004,
                    uid,
                    f"practice_items[{index}] text violates register_markers",
                )
            )

    return findings


def lint_register_unit(unit: Mapping[str, Any]) -> list[RegisterFinding]:
    if not isinstance(unit, Mapping):
        raise RegisterGateError("REGISTER_UNIT_INVALID", "register unit must be a mapping")
    return rg_findings(unit)


def lint_register_library(
    document: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> list[RegisterFinding]:
    if not isinstance(document, Mapping):
        raise RegisterGateError("REGISTER_LIBRARY_INVALID", "document must be a mapping")
    language = document.get("language")
    if not isinstance(language, str) or not language.strip():
        raise RegisterGateError("REGISTER_LIBRARY_INVALID", "language is required")
    lang = language.strip().lower()
    rows = document.get("units")
    if not isinstance(rows, list):
        raise RegisterGateError("REGISTER_LIBRARY_INVALID", "units must be a list")

    findings: list[RegisterFinding] = []
    for row in rows:
        if not isinstance(row, Mapping):
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_UNCITED,
                    RULE_RG001,
                    "<unknown>",
                    "unit entry must be a mapping",
                )
            )
            continue
        findings.extend(lint_register_unit(row))

    for key in _REQUIRED_UNIT_KEYS:
        expected = f"{lang}.register.{key}"
        if not any(
            isinstance(row, Mapping) and isinstance(row.get("id"), str) and row["id"] == expected
            for row in rows
        ):
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_NOTES_ONLY,
                    RULE_RG003,
                    expected,
                    f"missing required register unit {expected}",
                )
            )
    return findings


def load_register_file(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def lint_all_register_files(root: Path | None = None) -> list[RegisterFinding]:
    root_path = repo_root(root)
    data_dir = register_dir(root_path)
    if not data_dir.is_dir():
        return []
    paths = sorted(data_dir.glob("*.json"))
    if not paths:
        return []
    findings: list[RegisterFinding] = []
    present_langs = {p.stem.lower() for p in paths}
    for lang in STAGE1_LANGUAGES:
        if lang not in present_langs:
            findings.append(
                RegisterFinding(
                    CODE_REGISTER_NOTES_ONLY,
                    RULE_RG003,
                    lang,
                    f"missing register library JSON for language {lang}",
                )
            )
    for path in paths:
        document = load_register_file(path)
        findings.extend(lint_register_library(document, root=root_path))
    return findings


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=f"Register unit publish gate ({CARD_ID})")
    parser.add_argument(
        "path",
        nargs="?",
        help="Optional path to one register library JSON; default lint all",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)
    if args.path:
        document = load_register_file(Path(args.path))
        findings = lint_register_library(document)
    else:
        findings = lint_all_register_files()
    if findings:
        for row in findings:
            print(f"{row.code}\t{row.rule_id}\t{row.unit_id}\t{row.detail}", file=sys.stderr)
        return 1
    print(f"{CARD_ID}: register libraries clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
