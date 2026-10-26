"""Rebuild legacy curriculum units against the CEFR map as signed packs (P4-086)."""

from __future__ import annotations

import argparse
import hashlib
import hmac
import json
import os
import re
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content_engine.legacy.dialogues import build_can_do_target, iter_unit_lessons
from tools.content_engine.legacy.quarantine import repo_root
from tools.content_engine.legacy.salvage import resolve_curriculum_path

CARD_ID = "P4-086"
MANIFEST_BASENAME = "legacy_structure_manifest.json"
DEFAULT_PACK_VERSION = "1.0.0"
SEMVER_PATTERN = re.compile(r"^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?$")


class StructureError(Exception):
    def __init__(self, code: str, message: str) -> None:
        super().__init__(message)
        self.code = code


@dataclass(frozen=True)
class StructureChange:
    unit_key: str
    action: str
    can_do_targets: tuple[str, ...]


@dataclass(frozen=True)
class StructureStats:
    units_total: int
    units_rebuilt: int
    packs_written: int


@dataclass(frozen=True)
class StructureResult:
    changes: tuple[StructureChange, ...]
    stats: StructureStats
    curriculum_path: Path
    packs_dir: Path
    manifest_path: Path
    changed: bool


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def unit_packs_dir(root: Path) -> Path:
    return repo_root(root).parent / "curriculum" / "pipeline" / "output" / "unit_packs"


def load_cefr_map(path: Path) -> dict[str, tuple[str, ...]]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, Mapping):
        raise StructureError("CEFR_MAP_INVALID", "CEFR map root must be an object")
    units = raw.get("units")
    if not isinstance(units, Mapping):
        raise StructureError("CEFR_MAP_INVALID", "CEFR map missing units object")
    out: dict[str, tuple[str, ...]] = {}
    for unit_key, targets in units.items():
        if not isinstance(unit_key, str):
            continue
        if not isinstance(targets, list):
            raise StructureError(
                "CEFR_MAP_INVALID",
                f"CEFR map entry for {unit_key!r} must be a list",
            )
        normalized = tuple(
            sorted({t for t in targets if isinstance(t, str) and t.strip()})
        )
        out[unit_key] = normalized
    return out


def derive_cefr_map(curriculum: Mapping[str, Any]) -> dict[str, tuple[str, ...]]:
    """Build required can-do targets per unit from lesson objectives."""
    derived: dict[str, set[str]] = {}
    for _lang, _kit, cefr, unit_key, lessons in iter_unit_lessons(curriculum):
        targets: set[str] = set()
        for _lesson_id, lesson in lessons:
            objective = lesson.get("objective")
            obj = objective if isinstance(objective, str) else ""
            targets.add(build_can_do_target(cefr, obj))
        derived[unit_key] = targets
    return {key: tuple(sorted(vals)) for key, vals in derived.items()}


def collect_lesson_targets(cefr: str, lessons: Sequence[tuple[str, Mapping[str, Any]]]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for _lesson_id, lesson in lessons:
        objective = lesson.get("objective")
        obj = objective if isinstance(objective, str) else ""
        target = build_can_do_target(cefr, obj)
        if target not in seen:
            seen.add(target)
            ordered.append(target)
    return ordered


def validate_cefr_coverage(
    unit_key: str,
    covered: Sequence[str],
    required: Sequence[str],
) -> None:
    covered_set = set(covered)
    for target in required:
        if target not in covered_set:
            raise StructureError(
                "CEFR_TARGET_MISSING",
                f"unit {unit_key} missing can-do target {target!r}",
            )


def audio_content_hash(text: str) -> str:
    return hashlib.sha256(nfc(text).encode("utf-8")).hexdigest()[:16]


def lesson_primary_text(lesson: Mapping[str, Any]) -> str:
    vocab = lesson.get("vocab")
    if isinstance(vocab, list):
        for entry in vocab:
            if isinstance(entry, Mapping):
                word = entry.get("word")
                if isinstance(word, str) and word.strip():
                    return nfc(word)
    objective = lesson.get("objective")
    if isinstance(objective, str) and objective.strip():
        return nfc(objective)
    lesson_id = lesson.get("id")
    if isinstance(lesson_id, str):
        return lesson_id
    return "lesson"


def lesson_pack_item(
    lesson_id: str,
    lesson: Mapping[str, Any],
    kit_lang: str,
    cefr: str,
    can_do: str,
) -> dict[str, Any]:
    text = lesson_primary_text(lesson)
    content_hash = audio_content_hash(text)
    return {
        "item_id": lesson_id,
        "quality_label": "Beta",
        "payload": {
            "id": lesson_id,
            "lang": kit_lang,
            "type": "lesson",
            "cefr": cefr,
            "can_do": [can_do],
            "text": text,
            "audio": [{"kind": "tts", "file": f"{content_hash}.mp3"}],
            "provenance": {"source": "legacy"},
            "claims": [],
            "confidence": 0.5,
            "risk_tags": [],
            "status": "needs-review",
            "label": "beta",
            "feature_hooks": {},
        },
    }


def _stable_stringify(value: Any) -> str:
    if value is None or not isinstance(value, (dict, list)):
        return json.dumps(value, separators=(",", ":"), ensure_ascii=False)
    if isinstance(value, list):
        return "[" + ",".join(_stable_stringify(entry) for entry in value) + "]"
    record = value
    keys = sorted(record.keys())
    body = ",".join(
        json.dumps(key, ensure_ascii=False)
        + ":"
        + _stable_stringify(record[key])
        for key in keys
    )
    return "{" + body + "}"


def resolve_signing_key(explicit: str | None = None) -> str | None:
    if isinstance(explicit, str) and explicit.strip():
        return explicit.strip()
    from_env = os.environ.get("CONTENT_PACK_SIGNING_KEY", "").strip()
    return from_env or None


def sign_content_pack(
    version: str,
    items: Sequence[Mapping[str, Any]],
    *,
    signing_key: str,
    built_at: str,
) -> dict[str, Any]:
    semver = version.strip()
    if not SEMVER_PATTERN.match(semver):
        raise StructureError("PACK_VERSION_INVALID", f"version must be semver, got {version!r}")
    manifest_items = [
        {
            "item_id": str(item["item_id"]),
            "quality_label": str(item["quality_label"]),
        }
        for item in items
    ]
    manifest = {
        "version": semver,
        "built_at": built_at,
        "items": manifest_items,
    }
    pack_items = [
        {"item_id": str(item["item_id"]), "payload": dict(item["payload"])}
        for item in items
    ]
    unsigned = {"manifest": manifest, "items": pack_items}
    payload = _stable_stringify(unsigned)
    signature = hmac.new(
        signing_key.encode("utf-8"),
        payload.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return {**unsigned, "signature": signature}


def build_unit_pack(
    unit_key: str,
    kit_lang: str,
    cefr: str,
    lessons: Sequence[tuple[str, Mapping[str, Any]]],
    *,
    version: str = DEFAULT_PACK_VERSION,
    signing_key: str,
    built_at: str,
) -> dict[str, Any]:
    pack_items: list[dict[str, Any]] = []
    for lesson_id, lesson in lessons:
        objective = lesson.get("objective")
        obj = objective if isinstance(objective, str) else ""
        can_do = build_can_do_target(cefr, obj)
        pack_items.append(lesson_pack_item(lesson_id, lesson, kit_lang, cefr, can_do))
    pack = sign_content_pack(
        version,
        pack_items,
        signing_key=signing_key,
        built_at=built_at,
    )
    pack["unit_key"] = unit_key
    pack["kit_lang"] = kit_lang
    pack["cefr"] = cefr
    return pack


def _unit_mapping(
    curriculum: Mapping[str, Any],
    lang_key: str,
    cefr: str,
    unit_key: str,
) -> dict[str, Any] | None:
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


def rebuild_unit_record(
    unit: dict[str, Any],
    unit_key: str,
    cefr: str,
    lessons: Sequence[tuple[str, Mapping[str, Any]]],
    required_targets: Sequence[str],
) -> tuple[dict[str, Any], StructureChange | None]:
    covered = collect_lesson_targets(cefr, lessons)
    validate_cefr_coverage(unit_key, covered, required_targets)
    previous = unit.get("can_do_targets")
    prev_tuple = tuple(previous) if isinstance(previous, list) else ()
    next_tuple = tuple(covered)
    unit["can_do_targets"] = list(covered)
    if prev_tuple == next_tuple:
        return unit, None
    return unit, StructureChange(unit_key, "rebuilt", next_tuple)


def run_structure_rebuild(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    curriculum_path: Path | None = None,
    cefr_map_path: Path | None = None,
    cefr_map: Mapping[str, Sequence[str]] | None = None,
    pack_version: str = DEFAULT_PACK_VERSION,
    signing_key: str | None = None,
    built_at: str | None = None,
) -> StructureResult:
    base = repo_root(root)
    src = curriculum_path if curriculum_path is not None else resolve_curriculum_path(base)
    curriculum = json.loads(src.read_text(encoding="utf-8"))
    if not isinstance(curriculum, dict):
        raise TypeError("curriculum root must be an object")

    if cefr_map is not None:
        required_by_unit = {
            key: tuple(sorted(set(targets)))
            for key, targets in cefr_map.items()
        }
    elif cefr_map_path is not None:
        required_by_unit = load_cefr_map(cefr_map_path)
    else:
        required_by_unit = derive_cefr_map(curriculum)

    key = resolve_signing_key(signing_key)
    if not dry_run and not key:
        raise StructureError(
            "PACK_SIGNING_KEY_MISSING",
            "CONTENT_PACK_SIGNING_KEY is not configured",
        )

    changes: list[StructureChange] = []
    units_rebuilt = 0
    packs_written = 0
    stamp = built_at or "1970-01-01T00:00:00.000Z"

    unit_rows = iter_unit_lessons(curriculum)
    packs_dir = unit_packs_dir(base)

    for lang_key, kit_lang, cefr, unit_key, unit_lessons in unit_rows:
        required = required_by_unit.get(unit_key, ())
        covered = collect_lesson_targets(cefr, unit_lessons)
        validate_cefr_coverage(unit_key, covered, required)

        unit = _unit_mapping(curriculum, lang_key, cefr, unit_key)
        if unit is None:
            continue

        if dry_run:
            prev = unit.get("can_do_targets")
            prev_tuple = tuple(prev) if isinstance(prev, list) else ()
            next_tuple = tuple(covered)
            if prev_tuple != next_tuple:
                changes.append(StructureChange(unit_key, "would_rebuild", next_tuple))
            continue

        unit_dict = dict(unit)
        _, change = rebuild_unit_record(
            unit_dict,
            unit_key,
            cefr,
            unit_lessons,
            required,
        )
        unit.clear()
        unit.update(unit_dict)
        if change is not None:
            changes.append(change)
            units_rebuilt += 1

        pack = build_unit_pack(
            unit_key,
            kit_lang,
            cefr,
            unit_lessons,
            version=pack_version,
            signing_key=key or "",
            built_at=stamp,
        )
        packs_dir.mkdir(parents=True, exist_ok=True)
        pack_path = packs_dir / f"{unit_key}.json"
        serialized = json.dumps(pack, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        if not (pack_path.is_file() and pack_path.read_text(encoding="utf-8") == serialized):
            pack_path.write_text(serialized, encoding="utf-8")
            packs_written += 1

    changed = bool(changes) or packs_written > 0
    manifest_path = src.parent / MANIFEST_BASENAME

    if not dry_run:
        src.write_text(
            json.dumps(curriculum, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        manifest = {
            "card": CARD_ID,
            "curriculum": str(src.relative_to(base)) if src.is_relative_to(base) else str(src),
            "units_total": len(unit_rows),
            "units_rebuilt": units_rebuilt,
            "packs_written": packs_written,
            "pack_version": pack_version,
            "packs_dir": str(packs_dir),
        }
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    stats = StructureStats(
        units_total=len(unit_rows),
        units_rebuilt=units_rebuilt,
        packs_written=packs_written,
    )
    return StructureResult(tuple(changes), stats, src, packs_dir, manifest_path, changed)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Rebuild curriculum units against the CEFR map and emit signed unit packs.",
    )
    parser.add_argument("--dry-run", action="store_true", help="List changes without writing.")
    parser.add_argument("--repo-root", type=Path, default=None, help="Mobile app repository root.")
    parser.add_argument("--curriculum", type=Path, default=None, help="Override curriculum JSON.")
    parser.add_argument("--cefr-map", type=Path, default=None, help="CEFR map JSON with units object.")
    parser.add_argument("--pack-version", default=DEFAULT_PACK_VERSION, help="Semver pack version.")
    args = parser.parse_args(argv)

    try:
        result = run_structure_rebuild(
            args.repo_root,
            dry_run=args.dry_run,
            curriculum_path=args.curriculum,
            cefr_map_path=args.cefr_map,
            pack_version=args.pack_version,
        )
    except StructureError as err:
        print(f"{err.code}\t{err}", file=sys.stderr)
        return 1

    s = result.stats
    print(
        f"units_total={s.units_total}\t"
        f"units_rebuilt={s.units_rebuilt}\t"
        f"packs_written={s.packs_written}"
    )
    for change in result.changes:
        print(f"change\t{change.unit_key}\t{change.action}\t{len(change.can_do_targets)}")
    if not args.dry_run:
        print(f"curriculum\t{result.curriculum_path}")
        print(f"packs_dir\t{result.packs_dir}")
        print(f"manifest\t{result.manifest_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
