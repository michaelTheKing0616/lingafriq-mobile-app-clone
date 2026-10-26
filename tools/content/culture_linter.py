"""Culture card author lint: cited claims, no Beta, cultural reviewer (P5-034)."""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-034"
CULTURE_DATA_REL = "assets/data/culture"
RULE_CU001 = "CU-001"
RULE_CU002 = "CU-002"
RULE_CU003 = "CU-003"

STAGE1_LANGUAGES: tuple[str, ...] = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")
_REQUIRED_THEMES: tuple[str, ...] = ("greetings", "kinship", "food", "festivals")


class CultureLintError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class CultureFinding:
    rule_id: str
    card_id: str
    detail: str


def culture_dir(root: Path | None = None) -> Path:
    return repo_root(root) / CULTURE_DATA_REL


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


def _has_cultural_reviewer(entry: Mapping[str, Any]) -> bool:
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
        if role == "reviewer" and isinstance(reviewer_id, str) and reviewer_id.strip():
            return True
    return False


def cu_findings(entry: Mapping[str, Any]) -> list[CultureFinding]:
    card_id = entry.get("id")
    cid = card_id if isinstance(card_id, str) else "<unknown>"
    findings: list[CultureFinding] = []

    if entry.get("label") == "beta":
        findings.append(
            CultureFinding(RULE_CU002, cid, "culture cards cannot carry label beta")
        )

    if not _has_cultural_reviewer(entry):
        findings.append(
            CultureFinding(
                RULE_CU003,
                cid,
                "published culture card requires an approved cultural reviewer (role reviewer)",
            )
        )

    allowed = _provenance_source_keys(entry)
    claims = entry.get("claims")
    if not isinstance(claims, list) or len(claims) < 1:
        findings.append(CultureFinding(RULE_CU001, cid, "claims must be a non-empty list"))
        return findings

    for index, claim in enumerate(claims):
        if not isinstance(claim, Mapping):
            findings.append(
                CultureFinding(RULE_CU001, cid, f"claims[{index}] must be a mapping")
            )
            continue
        if not _claim_has_citation(claim, allowed):
            findings.append(
                CultureFinding(
                    RULE_CU001,
                    cid,
                    f"claims[{index}] lacks a citation linked to provenance.sources",
                )
            )
    return findings


def _culture_schema_module(root: Path | None = None) -> Any:
    path = repo_root(root) / "test" / "content" / "test_culture_card_schema.py"
    spec = importlib.util.spec_from_file_location("test_culture_card_schema", path)
    if spec is None or spec.loader is None:
        raise CultureLintError("CULTURE_LINT_SETUP", f"cannot load schema helper at {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def lint_culture_card(
    entry: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> list[CultureFinding]:
    """Schema + envelope validation, then CU-001..003."""
    if not isinstance(entry, Mapping):
        raise CultureLintError("CULTURE_CARD_INVALID", "culture card must be a mapping")

    schema_mod = _culture_schema_module(root)
    try:
        schema_mod.validate_culture_card(entry)
    except schema_mod.CultureCardSchemaError as exc:
        raise CultureLintError(exc.code, str(exc)) from exc

    return cu_findings(entry)


def lint_culture_library(
    document: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> list[CultureFinding]:
    if not isinstance(document, Mapping):
        raise CultureLintError("CULTURE_LIBRARY_INVALID", "document must be a mapping")
    language = document.get("language")
    if not isinstance(language, str) or not language.strip():
        raise CultureLintError("CULTURE_LIBRARY_INVALID", "language is required")
    cards = document.get("cards")
    if not isinstance(cards, list):
        raise CultureLintError("CULTURE_LIBRARY_INVALID", "cards must be a list")

    findings: list[CultureFinding] = []
    for row in cards:
        if not isinstance(row, Mapping):
            findings.append(CultureFinding(RULE_CU001, "<unknown>", "card entry must be a mapping"))
            continue
        findings.extend(lint_culture_card(row, root=root))

    present_themes: set[str] = set()
    for row in cards:
        if not isinstance(row, Mapping):
            continue
        card_id = row.get("id")
        if isinstance(card_id, str):
            for theme in _REQUIRED_THEMES:
                if card_id.endswith(f".{theme}") or f".{theme}." in card_id:
                    present_themes.add(theme)
                    break
            for theme in _REQUIRED_THEMES:
                if card_id.endswith(f".culture.{theme}"):
                    present_themes.add(theme)

    lang = language.strip().lower()
    for theme in _REQUIRED_THEMES:
        expected_suffix = f"{lang}.culture.{theme}"
        if not any(
            isinstance(row, Mapping)
            and isinstance(row.get("id"), str)
            and row["id"] == expected_suffix
            for row in cards
        ):
            findings.append(
                CultureFinding(
                    RULE_CU001,
                    expected_suffix,
                    f"missing required culture theme card {expected_suffix}",
                )
            )
    return findings


def load_culture_file(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def lint_all_culture_files(root: Path | None = None) -> list[CultureFinding]:
    root_path = repo_root(root)
    data_dir = culture_dir(root_path)
    if not data_dir.is_dir():
        return [
            CultureFinding(
                RULE_CU001,
                CULTURE_DATA_REL,
                "culture data directory is missing",
            )
        ]
    findings: list[CultureFinding] = []
    paths = sorted(data_dir.glob("*.json"))
    if not paths:
        findings.append(
            CultureFinding(RULE_CU001, CULTURE_DATA_REL, "no culture library JSON files")
        )
        return findings
    for path in paths:
        document = load_culture_file(path)
        findings.extend(lint_culture_library(document, root=root_path))
    return findings


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=f"Culture card linter ({CARD_ID})")
    parser.add_argument(
        "path",
        nargs="?",
        help="Optional path to one culture library JSON; default lint all under assets/data/culture",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)
    if args.path:
        document = load_culture_file(Path(args.path))
        findings = lint_culture_library(document)
    else:
        findings = lint_all_culture_files()
    if findings:
        for row in findings:
            print(f"{row.rule_id}\t{row.card_id}\t{row.detail}", file=sys.stderr)
        return 1
    print(f"{CARD_ID}: culture libraries clean")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
