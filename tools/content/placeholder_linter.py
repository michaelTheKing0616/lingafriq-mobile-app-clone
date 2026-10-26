"""Placeholder linter and legacy curriculum quarantine manifest (P5-002, ELEVATION §6.1)."""

from __future__ import annotations

import json
import re
import unicodedata
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Callable, Iterable, Mapping, Sequence

CARD_ID = "P5-002"
MANIFEST_REL = "assets/data/legacy_quarantine.json"

# Roots scanned for legacy template curriculum (not canonical ../curriculum/packs).
LEGACY_BUNDLE_ROOTS: tuple[str, ...] = (
    "assets/data/lingafriq_authentic_curriculum_a1.json",
    "assets/data/lingafriq_authentic_curriculum_a1_a2_b1.json",
    "assets/data/lingafriq_authentic_curriculum_a1_c1.json",
    "assets/data/lingafriq_authentic_curriculum_a1_c2.json",
    "curriculum_bundle",
    "lingafriq_FINAL_curriculum",
    "lingafriq_full_curriculum_bundle",
)

_LEARNER_LEGACY_REFERENCE_ALLOWLIST: frozenset[str] = frozenset(
    {
        "lib/services/curriculum_service.dart",
        "lib/services/content/bundled_lesson_content_service.dart",
        "lib/utils/curriculum_languages.dart",
        "lib/providers/curriculum_provider.dart",
    }
)

_LEARNER_BLOCKED_TOKENS: tuple[str, ...] = (
    "curriculum_bundle/",
    "lingafriq_full_curriculum_bundle/",
    "lingafriq_FINAL_curriculum/",
)

_RE_PH002 = re.compile(r"\b(?:[A-Za-z]{2,4}_)?word\d+[a-z]?\b")
_RE_PH003 = re.compile(r"Example sentence with\b", re.IGNORECASE)
_RE_PH004 = re.compile(r"cultural immersion for\b", re.IGNORECASE)
_RE_MARKED = re.compile(
    r"[\u0300-\u036f\u1dc0-\u1dff\u0300-\u034f]|"
    r"[\u1e00-\u1eff]|"
    r"[ọọ̀ọ́ọ̣ọ̄ọ̃Ẹẹ̀ẹ́ẹ̣ẹ̄ẹ̃Ọọ̀ọ́ọ̣ọ̄ọ̃Ụụ̀ụ́ụ̣ụ̄ụ̃ụ̀ụ́ụ̣ụ̄ụ̃Ṣṣ̀ṣ́ṣ̣ṣ̄ṣ̃ṣ̀ṣ́ṣ̣ṣ̄ṣ̃]"
)

LexiconLookup = Callable[[str, str], Mapping[str, Any] | None]


@dataclass(frozen=True)
class LintFinding:
    rule_id: str
    field: str
    detail: str
    severity: str  # "reject" | "unverified"


@dataclass(frozen=True)
class LessonLintResult:
    lesson_id: str
    bundle_relpath: str
    language: str
    findings: tuple[LintFinding, ...]

    @property
    def publishable(self) -> bool:
        return not any(f.severity == "reject" for f in self.findings)

    @property
    def max_quality_label(self) -> str:
        if not self.publishable:
            return "blocked"
        if any(f.severity == "unverified" for f in self.findings):
            return "beta-eligible-pending"
        return "review-pending"


def repo_root(explicit: Path | None = None) -> Path:
    if explicit is not None:
        return explicit.resolve()
    return Path(__file__).resolve().parents[2]


def manifest_path(root: Path | None = None) -> Path:
    return repo_root(root) / MANIFEST_REL


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def has_marked_diacritics(text: str) -> bool:
    return bool(_RE_MARKED.search(nfc(text)))


def _ph001_vocab_hit(word: str, meaning: str) -> bool:
    w, m = word.strip().lower(), meaning.strip().lower()
    if w == "example" and m == "sample":
        return True
    if w == "example" or m == "sample":
        return True
    return False


def _scan_text_ph002_ph003(text: str, field: str) -> list[LintFinding]:
    findings: list[LintFinding] = []
    if _RE_PH002.search(text):
        findings.append(LintFinding("PH-002", field, "numbered word slot", "reject"))
    if _RE_PH003.search(text):
        findings.append(LintFinding("PH-003", field, "example sentence template", "reject"))
    return findings


def _scan_cultural_notes(text: str, field: str) -> list[LintFinding]:
    if _RE_PH004.search(text):
        return [
            LintFinding(
                "PH-004",
                field,
                "unit cultural_notes template",
                "reject",
            )
        ]
    return []


def _walk_strings(node: Any, prefix: str) -> Iterable[tuple[str, str]]:
    if isinstance(node, str):
        yield prefix, node
    elif isinstance(node, Mapping):
        for key, value in node.items():
            child = f"{prefix}.{key}" if prefix else str(key)
            yield from _walk_strings(value, child)
    elif isinstance(node, list):
        for idx, value in enumerate(node):
            yield from _walk_strings(value, f"{prefix}[{idx}]")


def lint_vocab_entry(
    entry: Mapping[str, Any],
    field: str,
    *,
    kit_lang: str,
    lookup: LexiconLookup | None,
) -> list[LintFinding]:
    findings: list[LintFinding] = []
    word = entry.get("word")
    meaning = entry.get("meaning")
    if isinstance(word, str) and isinstance(meaning, str) and _ph001_vocab_hit(word, meaning):
        findings.append(LintFinding("PH-001", field, "generic example/sample vocab", "reject"))
    if isinstance(word, str):
        findings.extend(_scan_text_ph002_ph003(word, f"{field}.word"))
        if has_marked_diacritics(word) and not _is_lexicon_anchored(kit_lang, word, lookup):
            findings.append(
                LintFinding("PH-UNANCHORED", field, "diacritics without lexicon anchor", "unverified")
            )
    if isinstance(meaning, str):
        findings.extend(_scan_text_ph002_ph003(meaning, f"{field}.meaning"))
    example = entry.get("example")
    if isinstance(example, str):
        findings.extend(_scan_text_ph002_ph003(example, f"{field}.example"))
    return findings


def _is_lexicon_anchored(kit_lang: str, phrase: str, lookup: LexiconLookup | None) -> bool:
    if lookup is None:
        return False
    lexeme = lookup(kit_lang, nfc(phrase))
    if lexeme is None:
        return False
    status = lexeme.get("anchoring_status") or lexeme.get("status")
    return status == "anchored"


def lint_lesson(
    lesson: Mapping[str, Any],
    *,
    bundle_relpath: str,
    language: str,
    kit_lang: str,
    unit_cultural_notes: str | None = None,
    lookup: LexiconLookup | None = None,
) -> LessonLintResult:
    lesson_id = str(lesson.get("id") or lesson.get("title") or "unknown")
    findings: list[LintFinding] = []

    if unit_cultural_notes:
        findings.extend(_scan_cultural_notes(unit_cultural_notes, "unit.cultural_notes"))

    cultural = lesson.get("cultural_notes")
    if isinstance(cultural, str):
        findings.extend(_scan_cultural_notes(cultural, "lesson.cultural_notes"))

    vocab = lesson.get("vocab")
    if isinstance(vocab, list):
        for idx, entry in enumerate(vocab):
            if isinstance(entry, Mapping):
                findings.extend(
                    lint_vocab_entry(
                        entry,
                        f"vocab[{idx}]",
                        kit_lang=kit_lang,
                        lookup=lookup,
                    )
                )

    for field, text in _walk_strings(lesson.get("exercises"), "exercises"):
        if isinstance(text, str):
            findings.extend(_scan_text_ph002_ph003(text, field))

    for field, text in _walk_strings(lesson.get("dialogue"), "dialogue"):
        if isinstance(text, str):
            findings.extend(_scan_text_ph002_ph003(text, field))
            if has_marked_diacritics(text) and not _is_lexicon_anchored(kit_lang, text, lookup):
                findings.append(
                    LintFinding("PH-UNANCHORED", field, "diacritics without lexicon anchor", "unverified")
                )

    dedup: dict[tuple[str, str, str], LintFinding] = {}
    for f in findings:
        dedup[(f.rule_id, f.field, f.detail)] = f
    return LessonLintResult(lesson_id, bundle_relpath, language, tuple(dedup.values()))


def _kit_lang_from_name(name: str) -> str:
    key = name.strip().lower().replace(" ", "_")
    aliases = {"nigerian_pidgin": "pcm", "pidgin": "pcm"}
    return aliases.get(key, key[:2] if len(key) == 2 else key)


def _iter_lessons_in_bundle(
    payload: Mapping[str, Any],
    bundle_relpath: str,
) -> Iterable[tuple[str, str, Mapping[str, Any], str | None]]:
    """Yield (language, kit_lang, lesson, unit_cultural_notes)."""
    languages = payload.get("languages")
    if isinstance(languages, Mapping):
        for lang_name, lang_body in languages.items():
            if not isinstance(lang_body, Mapping):
                continue
            kit = _kit_lang_from_name(str(lang_name))
            for level_key, level_val in lang_body.items():
                if not isinstance(level_val, list):
                    continue
                for unit in level_val:
                    if not isinstance(unit, Mapping):
                        continue
                    unit_notes = unit.get("cultural_notes")
                    unit_notes_s = unit_notes if isinstance(unit_notes, str) else None
                    lessons = unit.get("lessons")
                    if isinstance(lessons, list):
                        for lesson in lessons:
                            if isinstance(lesson, Mapping):
                                yield str(lang_name), kit, lesson, unit_notes_s
        return

    units = payload.get("units")
    meta = payload.get("meta")
    lang_name = "unknown"
    if isinstance(meta, Mapping):
        code = meta.get("code") or meta.get("language")
        if isinstance(code, str):
            lang_name = code
    kit = _kit_lang_from_name(lang_name)
    if isinstance(units, list):
        for unit in units:
            if not isinstance(unit, Mapping):
                continue
            unit_notes = unit.get("cultural_notes")
            unit_notes_s = unit_notes if isinstance(unit_notes, str) else None
            lessons = unit.get("lessons")
            if isinstance(lessons, list):
                for lesson in lessons:
                    if isinstance(lesson, Mapping):
                        yield lang_name, kit, lesson, unit_notes_s
            elif unit.get("vocab") is not None:
                yield lang_name, kit, unit, unit_notes_s


def iter_legacy_json_files(root: Path) -> list[Path]:
    base = repo_root(root)
    paths: list[Path] = []
    for rel in LEGACY_BUNDLE_ROOTS:
        path = base / rel
        if path.is_file() and path.suffix.lower() == ".json":
            paths.append(path)
        elif path.is_dir():
            paths.extend(
                sorted(
                    p
                    for p in path.rglob("*.json")
                    if p.is_file() and ".git" not in p.parts
                )
            )
    return paths


def lint_bundle_file(
    path: Path,
    root: Path | None = None,
    *,
    lookup: LexiconLookup | None = None,
) -> list[LessonLintResult]:
    base = repo_root(root)
    rel = path.resolve().relative_to(base.resolve()).as_posix()
    payload = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(payload, Mapping):
        return []
    results: list[LessonLintResult] = []
    for language, kit, lesson, unit_notes in _iter_lessons_in_bundle(payload, rel):
        results.append(
            lint_lesson(
                lesson,
                bundle_relpath=rel,
                language=language,
                kit_lang=kit,
                unit_cultural_notes=unit_notes,
                lookup=lookup,
            )
        )
    return results


def run_quarantine_job(
    root: Path | None = None,
    *,
    lookup: LexiconLookup | None = None,
    write: bool = True,
) -> dict[str, Any]:
    base = repo_root(root)
    all_results: list[LessonLintResult] = []
    bundles_seen: list[str] = []
    for path in iter_legacy_json_files(base):
        if not path.is_file():
            continue
        rel = path.relative_to(base).as_posix()
        bundles_seen.append(rel)
        all_results.extend(lint_bundle_file(path, base, lookup=lookup))

    publishable = sum(1 for r in all_results if r.publishable)
    payload: dict[str, Any] = {
        "card": CARD_ID,
        "quarantined_at": datetime.now(timezone.utc).isoformat(),
        "legacy_roots": list(LEGACY_BUNDLE_ROOTS),
        "bundles_scanned": bundles_seen,
        "lesson_count": len(all_results),
        "publishable_lessons": publishable,
        "learner_reference_allowlist": sorted(_LEARNER_LEGACY_REFERENCE_ALLOWLIST),
        "lessons": [
            {
                "id": r.lesson_id,
                "bundle": r.bundle_relpath,
                "language": r.language,
                "publishable": r.publishable,
                "max_quality_label": r.max_quality_label,
                "findings": [
                    {"rule": f.rule_id, "field": f.field, "severity": f.severity, "detail": f.detail}
                    for f in r.findings
                ],
            }
            for r in all_results
        ],
    }
    if write:
        out = manifest_path(base)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return payload


def load_manifest(root: Path | None = None) -> dict[str, Any] | None:
    path = manifest_path(root)
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def learner_surface_legacy_violations(root: Path | None = None) -> list[tuple[str, str]]:
    """Return (dart_relpath, token) for disallowed legacy path references in lib/."""
    base = repo_root(root)
    lib_dir = base / "lib"
    if not lib_dir.is_dir():
        return []
    violations: list[tuple[str, str]] = []
    for dart in sorted(lib_dir.rglob("*.dart")):
        rel = dart.relative_to(base).as_posix()
        if rel in _LEARNER_LEGACY_REFERENCE_ALLOWLIST:
            continue
        text = dart.read_text(encoding="utf-8")
        for token in _LEARNER_BLOCKED_TOKENS:
            if token in text:
                violations.append((rel, token))
    return violations
