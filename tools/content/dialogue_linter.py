"""Dialogue library linter: DL-001 repeats, i+1 lexicon window, content-graph surfaces (P5-030)."""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from jsonschema import Draft202012Validator

from tools.content.placeholder_linter import repo_root
from tools.content_pipeline.schema_loader import (
    SYNTHETIC_VOICE_TAG,
    CommonSchemaError,
    validate_content_envelope,
)
from tools.content_engine.legacy.structure import audio_content_hash

CARD_ID = "P5-030"
DIALOGUES_REL = "assets/data/dialogues"
RULE_DL001 = "DL-001"
RULE_DL002 = "DL-002"
RULE_DL003 = "DL-003"
RULE_DL004 = "DL-004"

STAGE1_LANGS: tuple[str, ...] = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")
TONAL_LANGS = frozenset({"yo", "ig", "ha"})
_KIT_TO_LANG_KEY: dict[str, str] = {
    "yo": "yoruba",
    "ha": "hausa",
    "ig": "igbo",
    "sw": "swahili",
    "zu": "zulu",
    "xh": "xhosa",
    "pcm": "nigerian_pidgin",
}
_REQUIRED_SURFACES: tuple[str, ...] = (
    "lessons",
    "scenario_theatre",
    "market_haggle",
    "greeting_gauntlet",
)
_DIALOGUE_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.dlg\.[a-z0-9._-]+$")
_UNIT_SUFFIX = re.compile(r"-u(\d+)$", re.IGNORECASE)
_TOKEN_SPLIT = re.compile(r"[^\w\u0300-\u036f\u1e00-\u1eff']+", re.UNICODE)
_ENGLISH_PAREN = re.compile(r"\([^)]*\)")
_ASCII_TOKEN = re.compile(r"^[A-Za-z][A-Za-z'-]*$")
_A1_UNITS_PER_LANG = 42
_A1_LEXEME_TARGET = 700


class DialogueLintError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class DialogueFinding:
    rule_id: str
    dialogue_id: str
    detail: str


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def dialogue_library_path(language: str, root: Path | None = None) -> Path:
    lang = language.strip().lower()
    return repo_root(root) / DIALOGUES_REL / f"{lang}.json"


def load_dialogue_library(language: str, root: Path | None = None) -> dict[str, Any]:
    path = dialogue_library_path(language, root)
    if not path.is_file():
        raise FileNotFoundError(path)
    doc = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(doc, Mapping):
        raise DialogueLintError("LIBRARY_INVALID", f"{path}: root must be an object")
    return dict(doc)


def _schema_registry(root: Path) -> Any:
    from referencing import Registry, Resource

    schema_dir = root / "schemas" / "v2" / "content"
    common = json.loads((schema_dir / "common.schema.json").read_text(encoding="utf-8"))
    dialogue = json.loads((schema_dir / "dialogue.schema.json").read_text(encoding="utf-8"))
    return (
        Registry()
        .with_resources(
            [
                (common["$id"], Resource.from_contents(common)),
                ("common.schema.json", Resource.from_contents(common)),
                (dialogue["$id"], Resource.from_contents(dialogue)),
                ("dialogue.schema.json", Resource.from_contents(dialogue)),
            ]
        )
    )


def dialogue_validator(root: Path | None = None) -> Draft202012Validator:
    root_path = repo_root(root)
    schema = json.loads(
        (root_path / "schemas" / "v2" / "content" / "dialogue.schema.json").read_text(
            encoding="utf-8"
        )
    )
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema, registry=_schema_registry(root_path))


def turn_audio(text: str, lang: str) -> dict[str, str]:
    digest = audio_content_hash(text)
    return {
        "kind": "tts_synthetic",
        "uri": f"audio/{lang}/{digest}.ogg",
        "text_hash": digest,
        "synthetic_voice_tag": SYNTHETIC_VOICE_TAG,
    }


def reference_tone_pattern(text: str) -> list[str]:
    """Placeholder syllable slots — tone marks come from cited pattern/FSI examples, not invented H/M/L."""
    words = [w for w in _TOKEN_SPLIT.split(nfc(text)) if w]
    return ["REF"] * max(1, len(words))


def collect_turn_lines(dialogue: Mapping[str, Any]) -> list[str]:
    turns = dialogue.get("turns")
    if not isinstance(turns, list):
        return []
    lines: list[str] = []
    for turn in turns:
        if not isinstance(turn, Mapping):
            continue
        text = turn.get("text")
        if isinstance(text, str) and nfc(text):
            lines.append(nfc(text))
    return lines


def dl001_findings(
    dialogue_id: str,
    lines: Sequence[str],
    *,
    cross_lang_seen: Mapping[str, int] | None = None,
) -> list[DialogueFinding]:
    findings: list[DialogueFinding] = []
    normalised = [nfc(line) for line in lines if nfc(line)]
    counts: dict[str, int] = {}
    for line in normalised:
        counts[line] = counts.get(line, 0) + 1
    for line, count in counts.items():
        if count > 1:
            findings.append(
                DialogueFinding(
                    RULE_DL001,
                    dialogue_id,
                    f"repeated line within dialogue ({count}x): {line[:48]}",
                )
            )
    if cross_lang_seen is not None:
        for line in normalised:
            prior = cross_lang_seen.get(line, 0)
            if prior > 0:
                findings.append(
                    DialogueFinding(
                        RULE_DL001,
                        dialogue_id,
                        f"repeated line across library ({prior + 1}x): {line[:48]}",
                    )
                )
    return findings


def unit_rank_cap(unit_key: str) -> int:
    match = _UNIT_SUFFIX.search(unit_key)
    if not match:
        raise DialogueLintError("UNIT_INVALID", f"unit_key must end with -uN: {unit_key}")
    unit_n = int(match.group(1))
    if unit_n < 1:
        raise DialogueLintError("UNIT_INVALID", f"invalid unit index in {unit_key}")
    per_unit = max(1, _A1_LEXEME_TARGET // _A1_UNITS_PER_LANG)
    return min(_A1_LEXEME_TARGET, unit_n * per_unit)


def load_a1_lemma_set(lang: str, rank_cap: int, root: Path | None = None) -> frozenset[str]:
    path = repo_root(root) / "assets/data/lexicon/a1" / f"{lang}.json"
    if not path.is_file():
        raise FileNotFoundError(path)
    doc = json.loads(path.read_text(encoding="utf-8"))
    rows = doc.get("lexemes")
    if not isinstance(rows, list):
        raise DialogueLintError("LEXICON_INVALID", f"{path}: missing lexemes")
    lemmas: set[str] = set()
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        rank = row.get("adjusted_rank", row.get("frequency_rank"))
        lemma = row.get("lemma")
        if not isinstance(lemma, str) or not lemma.strip():
            continue
        if isinstance(rank, int) and rank <= rank_cap:
            lemmas.add(nfc(lemma).casefold())
    return frozenset(lemmas)


def _target_language_tokens(line: str) -> list[str]:
    """Drop English glosses in parentheses and ASCII-only meta tokens from pattern contrasts."""
    stripped = _ENGLISH_PAREN.sub("", nfc(line))
    tokens: list[str] = []
    for token in _TOKEN_SPLIT.split(stripped):
        if not token or _ASCII_TOKEN.match(token):
            continue
        tokens.append(token)
    return tokens


def dl002_i_plus_one(
    dialogue_id: str,
    lines: Sequence[str],
    lang: str,
    rank_cap: int,
    *,
    root: Path | None = None,
) -> list[DialogueFinding]:
    """At most one target-language token may sit outside the cumulative lexicon at rank_cap."""
    prior = load_a1_lemma_set(lang, rank_cap, root)
    novel: set[str] = set()
    for line in lines:
        for token in _target_language_tokens(line):
            key = nfc(token).casefold()
            if key not in prior:
                novel.add(token)
    if len(novel) > 1:
        sample = ", ".join(sorted(novel)[:6])
        return [
            DialogueFinding(
                RULE_DL002,
                dialogue_id,
                f"i+1 violated: {len(novel)} novel tokens vs rank≤{rank_cap} window ({sample})",
            )
        ]
    return []


def dl003_content_graph(dialogue: Mapping[str, Any]) -> list[DialogueFinding]:
    dialogue_id = str(dialogue.get("id") or "<unknown>")
    graph = dialogue.get("content_graph")
    if not isinstance(graph, Mapping):
        return [
            DialogueFinding(
                RULE_DL003,
                dialogue_id,
                "content_graph mapping required for feature surfaces",
            )
        ]
    surfaces = graph.get("surfaces")
    if not isinstance(surfaces, list):
        return [
            DialogueFinding(
                RULE_DL003,
                dialogue_id,
                "content_graph.surfaces must be a list",
            )
        ]
    present = {str(s) for s in surfaces}
    missing = [s for s in _REQUIRED_SURFACES if s not in present]
    if missing:
        return [
            DialogueFinding(
                RULE_DL003,
                dialogue_id,
                f"missing surfaces: {', '.join(missing)}",
            )
        ]
    return []


def dl004_audio_dialogue(dialogue: Mapping[str, Any]) -> list[DialogueFinding]:
    dialogue_id = str(dialogue.get("id") or "<unknown>")
    turns = dialogue.get("turns")
    if not isinstance(turns, list) or len(turns) < 1:
        return [DialogueFinding(RULE_DL004, dialogue_id, "turns required for audio dialogue")]
    for index, turn in enumerate(turns):
        if not isinstance(turn, Mapping):
            return [DialogueFinding(RULE_DL004, dialogue_id, f"turns[{index}] invalid")]
        audio = turn.get("audio")
        if not isinstance(audio, Mapping):
            return [DialogueFinding(RULE_DL004, dialogue_id, f"turns[{index}].audio missing")]
        kind = audio.get("kind")
        if kind not in ("human", "tts_synthetic"):
            return [
                DialogueFinding(
                    RULE_DL004,
                    dialogue_id,
                    f"turns[{index}].audio.kind must be human or tts_synthetic",
                )
            ]
    return []


def lint_dialogue_entry(
    dialogue: Mapping[str, Any],
    *,
    lang: str,
    rank_cap: int | None = None,
    cross_lang_seen: dict[str, int] | None = None,
    root: Path | None = None,
    validator: Draft202012Validator | None = None,
) -> list[DialogueFinding]:
    if not isinstance(dialogue, Mapping):
        raise DialogueLintError("DIALOGUE_INVALID", "dialogue must be a mapping")
    dialogue_id = dialogue.get("id")
    if not isinstance(dialogue_id, str) or not _DIALOGUE_ID_RE.match(dialogue_id):
        raise DialogueLintError("DIALOGUE_INVALID", "id must match <lang>.dlg.<slug>")
    if dialogue_id.split(".", 1)[0] != lang:
        raise DialogueLintError("DIALOGUE_INVALID", f"id language must be {lang}")
    try:
        validate_content_envelope(dialogue)
    except CommonSchemaError as exc:
        raise DialogueLintError(exc.code, str(exc)) from exc
    v = validator or dialogue_validator(root)
    errors = sorted(v.iter_errors(dialogue), key=lambda e: list(e.path))
    if errors:
        raise DialogueLintError("DIALOGUE_INVALID", errors[0].message)
    lines = collect_turn_lines(dialogue)
    findings = (
        dl001_findings(dialogue_id, lines, cross_lang_seen=cross_lang_seen)
        + dl003_content_graph(dialogue)
        + dl004_audio_dialogue(dialogue)
    )
    if rank_cap is not None:
        findings.extend(dl002_i_plus_one(dialogue_id, lines, lang, rank_cap, root=root))
    if cross_lang_seen is not None:
        for line in lines:
            cross_lang_seen[line] = cross_lang_seen.get(line, 0) + 1
    return findings


def lint_dialogue_library(
    document: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> list[DialogueFinding]:
    lang = document.get("language")
    if not isinstance(lang, str) or lang not in STAGE1_LANGS:
        raise DialogueLintError("LIBRARY_INVALID", "language must be a Stage-1 kit code")
    bindings = document.get("unit_bindings")
    dialogues = document.get("dialogues")
    if not isinstance(bindings, list) or not isinstance(dialogues, list):
        raise DialogueLintError("LIBRARY_INVALID", "unit_bindings and dialogues arrays required")
    by_id: dict[str, Mapping[str, Any]] = {}
    for row in dialogues:
        if isinstance(row, Mapping) and isinstance(row.get("id"), str):
            by_id[row["id"]] = row
    findings: list[DialogueFinding] = []
    cross_seen: dict[str, int] = {}
    validator = dialogue_validator(root)
    for binding in bindings:
        if not isinstance(binding, Mapping):
            continue
        unit_key = binding.get("unit_key")
        dialogue_id = binding.get("dialogue_id")
        if not isinstance(unit_key, str) or not isinstance(dialogue_id, str):
            findings.append(
                DialogueFinding(RULE_DL004, dialogue_id or "<binding>", "unit binding incomplete")
            )
            continue
        dialogue = by_id.get(dialogue_id)
        if dialogue is None:
            findings.append(
                DialogueFinding(
                    RULE_DL004,
                    dialogue_id,
                    f"unit {unit_key} references missing dialogue",
                )
            )
            continue
        rank_cap = unit_rank_cap(unit_key)
        findings.extend(
            lint_dialogue_entry(
                dialogue,
                lang=lang,
                rank_cap=rank_cap,
                cross_lang_seen=cross_seen,
                root=root,
                validator=validator,
            )
        )
    return findings


def _legacy_script_lines(lesson: Mapping[str, Any]) -> list[str]:
    dialogue = lesson.get("dialogue")
    if not isinstance(dialogue, Mapping):
        return []
    script = dialogue.get("script")
    if not isinstance(script, list):
        return []
    lines: list[str] = []
    for turn in script:
        if isinstance(turn, Mapping):
            text = turn.get("text") or turn.get("line")
            if isinstance(text, str) and nfc(text):
                lines.append(nfc(text))
    return lines


def lint_legacy_bundle(bundle_path: Path) -> list[DialogueFinding]:
    """AC2: legacy 126/126 repeated-line defect must fail DL-001."""
    data = json.loads(bundle_path.read_text(encoding="utf-8"))
    languages = data.get("languages")
    if not isinstance(languages, Mapping):
        return []
    findings: list[DialogueFinding] = []
    for lang_key, levels in languages.items():
        if not isinstance(levels, Mapping):
            continue
        for _cefr, units in levels.items():
            if not isinstance(units, list):
                continue
            for unit in units:
                if not isinstance(unit, Mapping):
                    continue
                lessons = unit.get("lessons") or [unit]
                if not isinstance(lessons, list):
                    continue
                for lesson in lessons:
                    if not isinstance(lesson, Mapping):
                        continue
                    lesson_id = str(lesson.get("id") or "legacy")
                    lines = _legacy_script_lines(lesson)
                    findings.extend(dl001_findings(lesson_id, lines))
    return findings


def lint_all_stage1_libraries(root: Path | None = None) -> list[DialogueFinding]:
    findings: list[DialogueFinding] = []
    for lang in STAGE1_LANGS:
        try:
            doc = load_dialogue_library(lang, root)
        except FileNotFoundError:
            findings.append(
                DialogueFinding(RULE_DL004, lang, "dialogue library file missing")
            )
            continue
        findings.extend(lint_dialogue_library(doc, root=root))
    return findings


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Lint dialogue libraries (P5-030).")
    parser.add_argument("--language", choices=STAGE1_LANGS, help="Single language file")
    parser.add_argument("--legacy", type=Path, help="Lint a legacy curriculum bundle for DL-001")
    parser.add_argument("--all", action="store_true", help="Lint all Stage-1 libraries")
    args = parser.parse_args(list(argv) if argv is not None else None)
    findings: list[DialogueFinding] = []
    if args.legacy:
        findings = lint_legacy_bundle(args.legacy)
    elif args.all:
        findings = lint_all_stage1_libraries()
    elif args.language:
        findings = lint_dialogue_library(load_dialogue_library(args.language), root=None)
    else:
        parser.error("specify --language, --all, or --legacy")
    for row in findings:
        print(f"{row.rule_id}\t{row.dialogue_id}\t{row.detail}")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
