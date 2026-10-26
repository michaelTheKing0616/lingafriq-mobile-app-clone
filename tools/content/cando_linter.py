"""CEFR / ACTFL can-do map linter and builder (P5-014)."""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content.placeholder_linter import repo_root
from tools.content_engine.legacy.dialogues import iter_unit_lessons
from tools.content_engine.legacy.salvage import resolve_curriculum_path

CARD_ID = "P5-014"
MAP_REL = "assets/data/cando_map.json"
SCHEMA_REL = "schemas/v2/cando.schema.json"

RULE_CD001 = "CD-001"
RULE_CD002 = "CD-002"
RULE_CD003 = "CD-003"
RULE_CD004 = "CD-004"

CEFR_ACTFL_PRIMARY: dict[str, str] = {
    "A1": "Novice Low",
    "A2": "Novice High",
    "B1": "Intermediate Low",
    "B2": "Intermediate Mid",
    "C1": "Advanced Low",
    "C2": "Advanced Mid",
}

_LEGACY_TEMPLATE_OBJECTIVE = re.compile(
    r"^Understand basic phrases in .+ unit \d+$",
    re.IGNORECASE,
)
_LEGACY_TEMPLATE_OBJECTIVE_2 = re.compile(
    r"^Produce simple sentences relevant to the unit topic\.?$",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class CanDoFinding:
    rule_id: str
    unit_key: str
    field: str
    detail: str


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def map_path(root: Path | None = None) -> Path:
    return repo_root(root) / MAP_REL


def is_legacy_template_objective(objective: str) -> bool:
    obj = nfc(objective)
    if not obj:
        return False
    return bool(
        _LEGACY_TEMPLATE_OBJECTIVE.match(obj)
        or _LEGACY_TEMPLATE_OBJECTIVE_2.match(obj)
    )


def objective_to_statement_en(objective: str) -> str:
    obj = nfc(objective).rstrip(".")
    if not obj:
        return "I can practice core phrases in this unit."
    if is_legacy_template_objective(obj):
        return f"I can {obj[0].lower()}{obj[1:]}."
    first = obj[0].lower() + obj[1:] if len(obj) > 1 else obj.lower()
    return f"I can {first}."


def actfl_for_cefr(cefr: str, row_map: Mapping[str, Any] | None = None) -> str:
    level = cefr.strip().upper()
    if row_map and level in row_map:
        row = row_map[level]
        if isinstance(row, Mapping) and "actfl" in row:
            return str(row["actfl"])
        if isinstance(row, Mapping) and "gap" in row:
            raise ValueError(f"MappingGap for CEFR {level}")
    primary = CEFR_ACTFL_PRIMARY.get(level)
    if primary is None:
        raise ValueError(f"unsupported CEFR band {level!r}")
    return primary


def default_cefr_actfl_rows() -> dict[str, Any]:
    return {
        "A1": {
            "cefr": "A1",
            "actfl": "Novice Low",
            "actfl_descriptor": "ACTFL Novice Low aligns with CEFR A1 (approximate; school reporting band).",
        },
        "A2": {
            "cefr": "A2",
            "actfl": "Novice High",
            "actfl_descriptor": "ACTFL Novice High aligns with CEFR A2 (approximate).",
        },
        "B1": {
            "cefr": "B1",
            "actfl": "Intermediate Low",
            "actfl_descriptor": "ACTFL Intermediate Low aligns with CEFR B1 (approximate).",
        },
    }


def _can_do_id(kit_lang: str, unit_key: str, index: int) -> str:
    safe = unit_key.replace("-", "_").lower()
    return f"{kit_lang}.cando.{safe}.l{index}"


def infer_skill(objective: str) -> str:
    low = objective.lower()
    if "listen" in low or "understand" in low:
        return "LISTEN"
    if "read" in low:
        return "READ"
    if "write" in low or "spell" in low:
        return "WRITE"
    if "vocab" in low or "word" in low:
        return "LEX"
    if "dialogue" in low or "conversation" in low:
        return "INTERACT"
    return "SPEAK"


def collect_source_objectives(
    lessons: Sequence[tuple[str, Mapping[str, Any]]],
    unit_objectives: Sequence[str] = (),
) -> list[str]:
    seen: list[str] = []
    for _lid, lesson in lessons:
        objective = lesson.get("objective")
        obj = objective if isinstance(objective, str) else ""
        obj_n = nfc(obj)
        if obj_n and obj_n not in seen:
            seen.append(obj_n)
    for obj in unit_objectives:
        obj_n = nfc(obj)
        if obj_n and obj_n not in seen:
            seen.append(obj_n)
    if len(seen) < 2:
        for _lid, lesson in lessons:
            vocab = lesson.get("vocab")
            if not isinstance(vocab, list):
                continue
            for entry in vocab:
                if not isinstance(entry, Mapping):
                    continue
                meaning = entry.get("meaning")
                if not isinstance(meaning, str) or not meaning.strip():
                    continue
                derived = f"Practice: {nfc(meaning).rstrip('.')}"
                if derived not in seen:
                    seen.append(derived)
                if len(seen) >= 2:
                    break
            if len(seen) >= 2:
                break
    return seen


def _unit_mapping(
    curriculum: Mapping[str, Any],
    lang_key: str,
    cefr: str,
    unit_key: str,
) -> Mapping[str, Any] | None:
    languages = curriculum.get("languages")
    if not isinstance(languages, Mapping):
        return None
    levels = languages.get(lang_key)
    if not isinstance(levels, Mapping):
        return None
    units = levels.get(cefr)
    if not isinstance(units, list):
        return None
    for unit in units:
        if not isinstance(unit, Mapping):
            continue
        unit_num = unit.get("unit", 0)
        if f"{lang_key}-{cefr}-u{unit_num}" == unit_key:
            return unit
    return None


def build_unit_entry(
    kit_lang: str,
    cefr: str,
    unit_key: str,
    lessons: Sequence[tuple[str, Mapping[str, Any]]],
    row_map: Mapping[str, Any],
    unit_objectives: Sequence[str] = (),
) -> dict[str, Any]:
    actfl = actfl_for_cefr(cefr, row_map)
    seen_objectives = collect_source_objectives(lessons, unit_objectives)
    if len(seen_objectives) < 2:
        raise ValueError(f"unit {unit_key} has fewer than 2 sourced objectives")
    if len(seen_objectives) > 4:
        seen_objectives = seen_objectives[:4]

    can_dos: list[dict[str, Any]] = []
    for idx, obj in enumerate(seen_objectives, start=1):
        can_dos.append(
            {
                "can_do_id": _can_do_id(kit_lang, unit_key, idx),
                "cefr": cefr,
                "actfl": actfl,
                "statement_en": objective_to_statement_en(obj),
                "skill": infer_skill(obj),
                "source_objective": obj,
            }
        )
    return {
        "unit_key": unit_key,
        "kit_lang": kit_lang,
        "cefr_band": cefr,
        "can_dos": can_dos,
    }


def build_map_from_curriculum(
    curriculum: Mapping[str, Any],
    *,
    cefr_actfl: Mapping[str, Any] | None = None,
) -> dict[str, Any]:
    rows = default_cefr_actfl_rows()
    if cefr_actfl:
        rows.update({k: v for k, v in cefr_actfl.items() if k in ("A1", "A2", "B1")})
    units: dict[str, Any] = {}
    for lang_key, kit_lang, cefr, unit_key, unit_lessons in iter_unit_lessons(curriculum):
        unit_row = _unit_mapping(curriculum, lang_key, cefr, unit_key)
        unit_objs: list[str] = []
        if unit_row is not None:
            raw = unit_row.get("objectives")
            if isinstance(raw, list):
                unit_objs = [o for o in raw if isinstance(o, str)]
        units[unit_key] = build_unit_entry(
            kit_lang, cefr, unit_key, unit_lessons, rows, unit_objectives=unit_objs
        )
    return {
        "charter": "v2",
        "card_id": CARD_ID,
        "cefr_actfl": rows,
        "units": units,
    }


def load_map(root: Path | None = None) -> dict[str, Any]:
    return json.loads(map_path(root).read_text(encoding="utf-8"))


def lint_objective(objective: str, *, unit_key: str = "") -> CanDoFinding | None:
    if is_legacy_template_objective(objective):
        return CanDoFinding(
            RULE_CD001,
            unit_key,
            "source_objective",
            "legacy template unit objective",
        )
    return None


def lint_unit_entry(unit_key: str, entry: Mapping[str, Any]) -> list[CanDoFinding]:
    findings: list[CanDoFinding] = []
    can_dos = entry.get("can_dos")
    if not isinstance(can_dos, list):
        findings.append(CanDoFinding(RULE_CD002, unit_key, "can_dos", "missing can_dos array"))
        return findings

    if not (2 <= len(can_dos) <= 4):
        findings.append(
            CanDoFinding(
                RULE_CD002,
                unit_key,
                "can_dos",
                f"expected 2–4 can-dos, got {len(can_dos)}",
            )
        )

    cefr_band = entry.get("cefr_band")
    for row in can_dos:
        if not isinstance(row, Mapping):
            findings.append(CanDoFinding(RULE_CD003, unit_key, "can_dos", "entry not an object"))
            continue
        obj = row.get("source_objective")
        if isinstance(obj, str):
            hit = lint_objective(obj, unit_key=unit_key)
            if hit:
                findings.append(hit)
        cefr = row.get("cefr")
        actfl = row.get("actfl")
        if not isinstance(cefr, str) or not isinstance(actfl, str):
            findings.append(
                CanDoFinding(RULE_CD003, unit_key, "can_dos", "missing cefr or actfl")
            )
            continue
        if isinstance(cefr_band, str) and cefr != cefr_band:
            findings.append(
                CanDoFinding(
                    RULE_CD004,
                    unit_key,
                    "cefr",
                    f"can-do CEFR {cefr} != unit band {cefr_band}",
                )
            )
        stmt = row.get("statement_en")
        if not isinstance(stmt, str) or not stmt.startswith("I can "):
            findings.append(
                CanDoFinding(RULE_CD003, unit_key, "statement_en", "must be I can …")
            )
    return findings


def lint_cefr_actfl_table(cefr_actfl: Mapping[str, Any]) -> list[CanDoFinding]:
    findings: list[CanDoFinding] = []
    for level in ("A1", "A2", "B1"):
        row = cefr_actfl.get(level)
        if not isinstance(row, Mapping):
            findings.append(
                CanDoFinding(RULE_CD003, "", f"cefr_actfl.{level}", "missing row")
            )
            continue
        if "gap" in row:
            gap = row.get("gap")
            if not isinstance(gap, Mapping) or gap.get("kind") != "MappingGap":
                findings.append(
                    CanDoFinding(
                        RULE_CD003,
                        "",
                        f"cefr_actfl.{level}",
                        "gap must be typed MappingGap",
                    )
                )
            continue
        if "actfl" not in row or "cefr" not in row:
            findings.append(
                CanDoFinding(
                    RULE_CD003,
                    "",
                    f"cefr_actfl.{level}",
                    "incomplete CEFR–ACTFL row",
                )
            )
    return findings


def lint_map_document(doc: Mapping[str, Any]) -> list[CanDoFinding]:
    findings = lint_cefr_actfl_table(doc.get("cefr_actfl", {}))
    units = doc.get("units")
    if not isinstance(units, Mapping):
        findings.append(CanDoFinding(RULE_CD002, "", "units", "missing units object"))
        return findings
    for unit_key, entry in units.items():
        if not isinstance(entry, Mapping):
            findings.append(CanDoFinding(RULE_CD002, str(unit_key), "unit", "not an object"))
            continue
        findings.extend(lint_unit_entry(str(unit_key), entry))
    return findings


def sync_map_to_curriculum(root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    curriculum_path = resolve_curriculum_path(base)
    curriculum = json.loads(curriculum_path.read_text(encoding="utf-8"))
    doc = build_map_from_curriculum(curriculum)
    out = map_path(base)
    out.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return doc


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="P5-014 can-do map linter")
    parser.add_argument("--sync", action="store_true", help="Rebuild cando_map.json from authentic curriculum.")
    parser.add_argument("--lint", action="store_true", help="Lint committed cando_map.json.")
    args = parser.parse_args(list(argv) if argv is not None else None)

    if args.sync:
        sync_map_to_curriculum()
        print(f"synced {MAP_REL}")
        return 0

    if args.lint or not args.sync:
        findings = lint_map_document(load_map())
        if findings:
            for f in findings[:20]:
                print(f"{f.rule_id}\t{f.unit_key}\t{f.field}\t{f.detail}")
            if len(findings) > 20:
                print(f"... and {len(findings) - 20} more")
            return 1
        print("ok")
        return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
