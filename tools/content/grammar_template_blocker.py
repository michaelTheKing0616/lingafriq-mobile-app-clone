"""Block banned generic grammar templates; per-language typology (P5-003)."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping, Sequence

from tools.content.placeholder_linter import LEGACY_BUNDLE_ROOTS, repo_root

CARD_ID = "P5-003"
RULE_GR001 = "GR-001"
TYPOLOGY_REL = "assets/data/language_typology.json"
EXPECTED_LEGACY_LESSONS_WITH_GENERIC = 1546

_GENERIC_PATTERNS = (
    re.compile(r"affixes carry tense and person", re.IGNORECASE),
    re.compile(
        r"pattern:\s*subject\s*(?:→|->)\s*verb\s*(?:→|->)",
        re.IGNORECASE,
    ),
)

_ENGLISH_SVO_TEACHING = re.compile(
    r"pattern:\s*subject\s*(?:→|->)\s*verb\s*(?:→|->)\s*object",
    re.IGNORECASE,
)


class PatternMissingError(Exception):
    """Grammar publish blocked: no Pattern Library entry for this item."""

    def __init__(self, pattern_id: str, item_id: str) -> None:
        self.pattern_id = pattern_id
        self.item_id = item_id
        super().__init__(
            f"pattern library missing entry {pattern_id!r} for grammar item {item_id!r}"
        )


@dataclass(frozen=True)
class GrammarBlockFinding:
    rule_id: str
    field: str
    detail: str
    language: str


def is_generic_grammar_template(text: str) -> bool:
    if not isinstance(text, str) or not text.strip():
        return False
    return any(p.search(text) for p in _GENERIC_PATTERNS)


def typology_path(root: Path | None = None) -> Path:
    return repo_root(root) / TYPOLOGY_REL


def load_typology(root: Path | None = None) -> Mapping[str, Any]:
    raw = json.loads(typology_path(root).read_text(encoding="utf-8"))
    if not isinstance(raw, Mapping):
        raise TypeError("language_typology.json root must be an object")
    languages = raw.get("languages")
    if not isinstance(languages, Mapping):
        raise TypeError("language_typology.json languages must be an object")
    return languages


def language_typology(lang_key: str, root: Path | None = None) -> Mapping[str, Any] | None:
    languages = load_typology(root)
    entry = languages.get(lang_key.strip().lower())
    return entry if isinstance(entry, Mapping) else None


def lint_grammar_string(text: str, *, language: str, field: str) -> GrammarBlockFinding | None:
    if is_generic_grammar_template(text):
        return GrammarBlockFinding(RULE_GR001, field, "generic grammar template", language)
    topo = language_typology(language)
    if topo and topo.get("forbid_english_svo_grammar_template") and _ENGLISH_SVO_TEACHING.search(
        text
    ):
        return GrammarBlockFinding(RULE_GR001, field, "english SVO template on SOV language", language)
    if topo and topo.get("forbid_affix_tense_person_template"):
        if re.search(r"affixes carry tense and person", text, re.IGNORECASE):
            return GrammarBlockFinding(
                RULE_GR001,
                field,
                "english affix tense/person template on particle language",
                language,
            )
    return None


def _iter_lessons(curriculum: Mapping[str, Any]) -> Iterable[tuple[str, Mapping[str, Any]]]:
    languages = curriculum.get("languages")
    if not isinstance(languages, Mapping):
        return
    for lang_key, levels in languages.items():
        if not isinstance(lang_key, str) or not isinstance(levels, Mapping):
            continue
        for _cefr, units in levels.items():
            if not isinstance(units, list):
                continue
            for unit in units:
                if not isinstance(unit, Mapping):
                    continue
                lessons = unit.get("lessons")
                if not isinstance(lessons, list):
                    continue
                for lesson in lessons:
                    if isinstance(lesson, Mapping):
                        yield lang_key.lower(), lesson


def scan_legacy_bundles(root: Path | None = None) -> list[GrammarBlockFinding]:
    base = repo_root(root)
    findings: list[GrammarBlockFinding] = []
    for rel in LEGACY_BUNDLE_ROOTS:
        path = base / rel
        if not path.exists():
            continue
        if path.is_dir():
            for json_path in sorted(path.rglob("*.json")):
                findings.extend(_scan_curriculum_file(json_path, str(json_path.relative_to(base))))
            continue
        if path.suffix.lower() != ".json":
            continue
        findings.extend(_scan_curriculum_file(path, rel))
    return findings


def _scan_curriculum_file(path: Path, bundle_relpath: str) -> list[GrammarBlockFinding]:
    try:
        curriculum = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if not isinstance(curriculum, Mapping):
        return []
    out: list[GrammarBlockFinding] = []
    for lang_key, lesson in _iter_lessons(curriculum):
        lesson_id = lesson.get("id")
        lid = lesson_id if isinstance(lesson_id, str) else "unknown"
        grammar = lesson.get("grammar")
        if not isinstance(grammar, list):
            continue
        for idx, entry in enumerate(grammar):
            if not isinstance(entry, str):
                continue
            field = f"{bundle_relpath}:{lid}.grammar[{idx}]"
            hit = lint_grammar_string(entry, language=lang_key, field=field)
            if hit is not None:
                out.append(hit)
    return out


def _pattern_ids(pattern_library: Sequence[Mapping[str, Any]] | None) -> frozenset[str]:
    if not pattern_library:
        return frozenset()
    ids: set[str] = set()
    for entry in pattern_library:
        if not isinstance(entry, Mapping):
            continue
        pid = entry.get("id")
        if isinstance(pid, str) and pid.strip():
            ids.add(pid.strip())
    return frozenset(ids)


def assert_grammar_item_publishable(
    item: Mapping[str, Any],
    *,
    pattern_library: Sequence[Mapping[str, Any]] | None,
    language: str,
) -> None:
    """Fail loud on GR-001 or missing Pattern Library entry (AC3)."""
    if not isinstance(item, Mapping):
        raise TypeError("item must be a mapping")
    section = item.get("section")
    if section != "grammar":
        return

    item_id = item.get("id")
    iid = item_id if isinstance(item_id, str) else "unknown"

    text = item.get("text")
    if isinstance(text, str):
        hit = lint_grammar_string(text, language=language, field="text")
        if hit is not None:
            raise ValueError(f"{hit.rule_id}: {hit.detail}")

    pattern_id = item.get("pattern_id")
    if not isinstance(pattern_id, str) or not pattern_id.strip():
        raise PatternMissingError("", iid)

    known = _pattern_ids(pattern_library)
    pid = pattern_id.strip()
    if pid not in known:
        raise PatternMissingError(pid, iid)
