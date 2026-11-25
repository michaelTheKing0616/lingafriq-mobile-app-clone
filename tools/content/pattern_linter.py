"""Pattern Library schema validation and PL-001 linter (P5-020, CURRICULUM §4)."""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

import yaml
from jsonschema import Draft202012Validator

from tools.content.placeholder_linter import repo_root
from tools.content_pipeline.schema_loader import (
    CommonSchemaError,
    validate_content_envelope,
)

CARD_ID = "P5-020"
SCHEMA_REL = "schemas/v2/pattern.schema.json"
RULE_PL001 = "PL-001"
STAGE1_LANGUAGES: tuple[str, ...] = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")
KIT_DIR_REL = "tools/content_engine/kits"
PATTERNS_DATA_REL = "assets/data/patterns"

_PATTERN_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.pat\.[a-z0-9._-]+$")


class PatternLintError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class PatternFinding:
    rule_id: str
    pattern_id: str
    detail: str


@dataclass(frozen=True)
class PatternMissing:
    """Typed gap when a kit-listed A1 pattern has no library entry (AC3)."""

    pattern_id: str
    language: str
    status: str = "PatternMissing"

    def to_dict(self) -> dict[str, str]:
        return {
            "pattern_id": self.pattern_id,
            "language": self.language,
            "status": self.status,
        }


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def schema_path(root: Path | None = None) -> Path:
    return repo_root(root) / SCHEMA_REL


def load_pattern_schema(root: Path | None = None) -> dict[str, Any]:
    return json.loads(schema_path(root).read_text(encoding="utf-8"))


def _schema_registry(root: Path) -> Any:
    from referencing import Registry, Resource

    schema_dir = root / "schemas" / "v2"
    common = json.loads((schema_dir / "content" / "common.schema.json").read_text(encoding="utf-8"))
    pattern = load_pattern_schema(root)
    return (
        Registry()
        .with_resources(
            [
                (common["$id"], Resource.from_contents(common)),
                ("content/common.schema.json", Resource.from_contents(common)),
                (pattern["$id"], Resource.from_contents(pattern)),
                ("pattern.schema.json", Resource.from_contents(pattern)),
            ]
        )
    )


def pattern_validator(root: Path | None = None) -> Draft202012Validator:
    root_path = repo_root(root)
    schema = load_pattern_schema(root_path)
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema, registry=_schema_registry(root_path))


def _lang_from_pattern_id(pattern_id: str) -> str:
    match = _PATTERN_ID_RE.match(pattern_id)
    if not match:
        raise PatternLintError("PATTERN_INVALID", f"id must match <lang>.pat.<slug>: {pattern_id!r}")
    return match.group("lang")


def _has_citation(entry: Mapping[str, Any]) -> bool:
    provenance = entry.get("provenance")
    if isinstance(provenance, Mapping):
        sources = provenance.get("sources")
        if isinstance(sources, list):
            for source in sources:
                if not isinstance(source, Mapping):
                    continue
                citation = source.get("uri_or_citation")
                if isinstance(citation, str) and citation.strip():
                    return True
    claims = entry.get("claims")
    if isinstance(claims, list):
        for claim in claims:
            if not isinstance(claim, Mapping):
                continue
            ref = claim.get("source_ref")
            if isinstance(ref, str) and ref.strip():
                return True
    return False


def pl001_findings(entry: Mapping[str, Any]) -> list[PatternFinding]:
    pattern_id = entry.get("id")
    pid = pattern_id if isinstance(pattern_id, str) else "<unknown>"
    findings: list[PatternFinding] = []
    examples = entry.get("examples")
    if not isinstance(examples, list) or len(examples) < 1:
        findings.append(
            PatternFinding(RULE_PL001, pid, "at least one example is required")
        )
    elif not any(isinstance(row, str) and row.strip() for row in examples):
        findings.append(
            PatternFinding(RULE_PL001, pid, "examples must contain a non-empty string")
        )
    if not _has_citation(entry):
        findings.append(
            PatternFinding(RULE_PL001, pid, "citation required in provenance.sources or claims")
        )
    return findings


def lint_pattern_entry(
    entry: Mapping[str, Any],
    *,
    root: Path | None = None,
    validator: Draft202012Validator | None = None,
) -> list[PatternFinding]:
    """Validate one pattern against schema, envelope, and PL-001."""
    if not isinstance(entry, Mapping):
        raise PatternLintError("PATTERN_INVALID", "pattern entry must be a mapping")
    pattern_id = entry.get("id")
    if not isinstance(pattern_id, str) or not pattern_id.strip():
        raise PatternLintError("PATTERN_INVALID", "id is required")
    _lang_from_pattern_id(pattern_id)
    for field in ("description_l1", "form"):
        val = entry.get(field)
        if not isinstance(val, str) or not nfc(val):
            raise PatternLintError("PATTERN_INVALID", f"{field} is required")
        if unicodedata.normalize("NFC", val) != val:
            raise PatternLintError("PATTERN_INVALID", f"{field} must be NFC-normalised")
    label = entry.get("label")
    if label == "beta":
        raise PatternLintError("PATTERN_BETA_REJECTED", "grammar patterns reject label beta")
    try:
        validate_content_envelope(entry)
    except CommonSchemaError as exc:
        raise PatternLintError(exc.code, str(exc)) from exc
    v = validator or pattern_validator(root)
    errors = sorted(v.iter_errors(entry), key=lambda e: list(e.path))
    if errors:
        raise PatternLintError("PATTERN_INVALID", errors[0].message)
    return pl001_findings(entry)


def load_kit_a1_pattern_ids(language: str, root: Path | None = None) -> list[str]:
    """Read optional a1_patterns list from the language kit YAML."""
    root_path = repo_root(root)
    lang = language.strip().lower()
    candidates = [
        root_path / KIT_DIR_REL / lang / "kit.yaml",
        root_path / KIT_DIR_REL / f"{lang}.yaml",
    ]
    for path in candidates:
        if not path.is_file():
            continue
        with path.open(encoding="utf-8") as handle:
            data = yaml.safe_load(handle)
        if not isinstance(data, Mapping):
            return []
        rows = data.get("a1_patterns")
        if not isinstance(rows, list):
            return []
        return [row.strip() for row in rows if isinstance(row, str) and row.strip()]
    return []


def coverage_for_language(
    language: str,
    entries: Sequence[Mapping[str, Any]],
    *,
    kit_pattern_ids: Sequence[str] | None = None,
    root: Path | None = None,
) -> list[PatternMissing]:
    """Every kit-listed A1 pattern must exist in entries or be reported PatternMissing."""
    lang = language.strip().lower()
    expected = list(kit_pattern_ids) if kit_pattern_ids is not None else load_kit_a1_pattern_ids(lang, root)
    present = {
        row.get("id").strip()
        for row in entries
        if isinstance(row, Mapping) and isinstance(row.get("id"), str) and row.get("id").strip()
    }
    gaps: list[PatternMissing] = []
    for pattern_id in expected:
        if pattern_id not in present:
            gaps.append(PatternMissing(pattern_id=pattern_id, language=lang))
    return gaps


def lint_pattern_library(
    document: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> tuple[list[PatternFinding], list[PatternMissing]]:
    """Lint a pattern library document {language, patterns[], gaps?}."""
    if not isinstance(document, Mapping):
        raise PatternLintError("LIBRARY_INVALID", "library document must be a mapping")
    language = document.get("language")
    if not isinstance(language, str) or language.strip().lower() not in STAGE1_LANGUAGES:
        raise PatternLintError("LIBRARY_INVALID", "language must be one of the seven Stage-1 codes")
    lang = language.strip().lower()
    patterns = document.get("patterns")
    if not isinstance(patterns, list):
        raise PatternLintError("LIBRARY_INVALID", "patterns must be a list")
    validator = pattern_validator(root)
    findings: list[PatternFinding] = []
    for index, entry in enumerate(patterns):
        if not isinstance(entry, Mapping):
            raise PatternLintError("PATTERN_INVALID", f"patterns[{index}] must be a mapping")
        entry_lang = _lang_from_pattern_id(str(entry.get("id", "")))
        if entry_lang != lang:
            raise PatternLintError(
                "PATTERN_LANG_MISMATCH",
                f"patterns[{index}] language {entry_lang!r} does not match library {lang!r}",
            )
        findings.extend(lint_pattern_entry(entry, root=root, validator=validator))
    kit_ids = document.get("kit_pattern_ids")
    kit_list = kit_ids if isinstance(kit_ids, list) else None
    gaps = coverage_for_language(lang, patterns, kit_pattern_ids=kit_list, root=root)
    declared = document.get("gaps")
    if isinstance(declared, list):
        for gap in declared:
            if isinstance(gap, Mapping) and gap.get("status") == "PatternMissing":
                pid = gap.get("pattern_id")
                if isinstance(pid, str) and pid.strip():
                    gaps = [g for g in gaps if g.pattern_id != pid.strip()]
    return findings, gaps


def patterns_file_path(language: str, root: Path | None = None) -> Path:
    return repo_root(root) / PATTERNS_DATA_REL / f"{language.strip().lower()}.json"


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Pattern Library linter (P5-020)")
    parser.add_argument("path", nargs="?", help="pattern library JSON file")
    parser.add_argument("--language", help="Stage-1 language code (loads assets/data/patterns/<lang>.json)")
    args = parser.parse_args(list(argv) if argv is not None else None)
    root = repo_root()
    if args.path:
        target = Path(args.path)
    elif args.language:
        target = patterns_file_path(args.language, root)
    else:
        parser.error("provide a path or --language")
    if not target.is_file():
        print(f"{CARD_ID}: file not found: {target}", file=sys.stderr)
        return 2
    document = json.loads(target.read_text(encoding="utf-8"))
    findings, gaps = lint_pattern_library(document, root=root)
    if findings:
        for finding in findings:
            print(f"{finding.rule_id} {finding.pattern_id}: {finding.detail}", file=sys.stderr)
        return 1
    if gaps:
        for gap in gaps:
            print(f"PatternMissing {gap.pattern_id} ({gap.language})", file=sys.stderr)
        return 1
    print(f"{CARD_ID}: ok {target.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
