"""Publish gate for proverbs and idioms: cited collection + linguist review (P5-035)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-035"
PROVERB_DATA_REL = "assets/data/proverbs"
CODE_PROVERB_UNREVIEWED = "ProverbUnreviewed"
CODE_PROVERB_UNCITED = "ProverbUncited"

RULE_PV001 = "PV-001"
RULE_PV002 = "PV-002"
RULE_PV003 = "PV-003"

STAGE1_LANGUAGES: tuple[str, ...] = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")
_EXPERT_OR_BETTER: frozenset[str] = frozenset({"expert_reviewed", "native_verified"})
_RISK_KINDS: frozenset[str] = frozenset({"proverb", "idiom"})


class ProverbGateError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class ProverbFinding:
    code: str
    rule_id: str
    entry_id: str
    detail: str


def proverb_dir(root: Path | None = None) -> Path:
    return repo_root(root) / PROVERB_DATA_REL


def _entry_id(entry: Mapping[str, Any]) -> str:
    raw = entry.get("id")
    if isinstance(raw, str) and raw.strip():
        return raw.strip()
    if isinstance(raw, int):
        return str(raw)
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


def _risk_tags(entry: Mapping[str, Any]) -> set[str]:
    raw = entry.get("risk_tags")
    if not isinstance(raw, list):
        return set()
    tags: set[str] = set()
    for item in raw:
        if isinstance(item, str) and item.strip():
            tags.add(item.strip())
    return tags


def is_proverb_or_idiom_entry(entry: Mapping[str, Any]) -> bool:
    tags = _risk_tags(entry)
    if tags & _RISK_KINDS:
        return True
    entry_id = _entry_id(entry)
    return ".proverb." in entry_id or entry_id.endswith(".proverb") or ".idiom." in entry_id


def pv_findings(entry: Mapping[str, Any]) -> list[ProverbFinding]:
    """Lint one publishable proverb/idiom envelope."""
    eid = _entry_id(entry)
    findings: list[ProverbFinding] = []

    if not is_proverb_or_idiom_entry(entry):
        return findings

    label = _label(entry)
    if label not in _EXPERT_OR_BETTER:
        findings.append(
            ProverbFinding(
                CODE_PROVERB_UNREVIEWED,
                RULE_PV002,
                eid,
                "label must be expert_reviewed or native_verified",
            )
        )

    if not _has_linguist_approval(entry):
        findings.append(
            ProverbFinding(
                CODE_PROVERB_UNREVIEWED,
                RULE_PV003,
                eid,
                "published proverb requires an approved linguist reviewer",
            )
        )

    allowed = _provenance_source_keys(entry)
    if not allowed:
        findings.append(
            ProverbFinding(
                CODE_PROVERB_UNCITED,
                RULE_PV001,
                eid,
                "provenance.sources must cite a published collection",
            )
        )

    claims = entry.get("claims")
    if not isinstance(claims, list) or len(claims) < 1:
        findings.append(
            ProverbFinding(
                CODE_PROVERB_UNCITED,
                RULE_PV001,
                eid,
                "claims must be a non-empty list",
            )
        )
        return findings

    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            findings.append(
                ProverbFinding(
                    CODE_PROVERB_UNCITED,
                    RULE_PV001,
                    eid,
                    f"claims[{index}] must be a mapping",
                )
            )
            continue
        if not _claim_has_citation(claim, allowed):
            findings.append(
                ProverbFinding(
                    CODE_PROVERB_UNCITED,
                    RULE_PV001,
                    eid,
                    f"claims[{index}] lacks a citation linked to provenance.sources",
                )
            )
    return findings


def lint_proverb_entry(entry: Mapping[str, Any]) -> list[ProverbFinding]:
    if not isinstance(entry, Mapping):
        raise ProverbGateError("PROVERB_ENTRY_INVALID", "proverb entry must be a mapping")
    return pv_findings(entry)


def lint_proverb_library(
    document: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> list[ProverbFinding]:
    if not isinstance(document, Mapping):
        raise ProverbGateError("PROVERB_LIBRARY_INVALID", "document must be a mapping")
    language = document.get("language")
    if not isinstance(language, str) or not language.strip():
        raise ProverbGateError("PROVERB_LIBRARY_INVALID", "language is required")
    rows = document.get("proverbs")
    if rows is None:
        rows = document.get("entries")
    if not isinstance(rows, list):
        raise ProverbGateError("PROVERB_LIBRARY_INVALID", "proverbs must be a list")

    findings: list[ProverbFinding] = []
    for row in rows:
        if not isinstance(row, Mapping):
            findings.append(
                ProverbFinding(
                    CODE_PROVERB_UNCITED,
                    RULE_PV001,
                    "<unknown>",
                    "proverb entry must be a mapping",
                )
            )
            continue
        findings.extend(lint_proverb_entry(row))
    return findings


def load_proverb_file(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def lint_all_proverb_files(root: Path | None = None) -> list[ProverbFinding]:
    root_path = repo_root(root)
    data_dir = proverb_dir(root_path)
    if not data_dir.is_dir():
        return []
    paths = sorted(data_dir.glob("*.json"))
    if not paths:
        return []
    findings: list[ProverbFinding] = []
    for path in paths:
        document = load_proverb_file(path)
        findings.extend(lint_proverb_library(document, root=root_path))
    return findings


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=f"Proverb publish gate ({CARD_ID})")
    parser.add_argument(
        "path",
        nargs="?",
        help="Optional path to one proverb library JSON; default lint all under assets/data/proverbs",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)
    if args.path:
        document = load_proverb_file(Path(args.path))
        findings = lint_proverb_library(document)
    else:
        findings = lint_all_proverb_files()
    if findings:
        for row in findings:
            print(f"{row.code}\t{row.rule_id}\t{row.entry_id}\t{row.detail}", file=sys.stderr)
        return 1
    print(f"{CARD_ID}: proverb libraries clean (or none published)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
