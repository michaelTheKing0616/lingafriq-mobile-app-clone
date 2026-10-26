"""Spiral exposure planner for A1 lexemes (P5-018, CURRICULUM §4)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content.cando_linter import load_map
from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-018"
LEXICON_REL = "assets/data/lexicon/a1"
MIN_EXPOSURES = 6
STAGE1_LANGS: tuple[str, ...] = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")

EXPOSURE_PHASES: tuple[str, ...] = (
    "input",
    "controlled_practice",
    "speaking",
    "review",
    "input",
    "controlled_practice",
)


class SpiralPlannerError(Exception):
    """Planner failed. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class SpiralShortfall(SpiralPlannerError):
    """One or more lexemes have fewer than [MIN_EXPOSURES] unit exposures."""

    def __init__(self, lexeme_ids: Sequence[str]) -> None:
        ordered = sorted(dict.fromkeys(lexeme_ids))
        self.lexeme_ids = list(ordered)
        super().__init__(
            "SpiralShortfall",
            f"{len(self.lexeme_ids)} lexeme(s) below {MIN_EXPOSURES} exposures: "
            + ", ".join(self.lexeme_ids[:12])
            + ("…" if len(self.lexeme_ids) > 12 else ""),
        )


@dataclass(frozen=True)
class SpiralExposure:
    lexeme_id: str
    unit_key: str
    phase: str
    sequence: int

    def to_dict(self) -> dict[str, Any]:
        return {
            "lexeme_id": self.lexeme_id,
            "unit_key": self.unit_key,
            "phase": self.phase,
            "sequence": self.sequence,
        }


_UNIT_SUFFIX = re.compile(r"-u(\d+)$", re.IGNORECASE)


def _unit_order_key(unit_key: str) -> tuple[str, int]:
    match = _UNIT_SUFFIX.search(unit_key)
    return (unit_key[: match.start()] if match else unit_key, int(match.group(1)) if match else 0)


def list_a1_units(map_doc: Mapping[str, Any], lang: str) -> list[str]:
    units = map_doc.get("units")
    if not isinstance(units, Mapping):
        return []
    keys: list[str] = []
    for unit_key, entry in units.items():
        if not isinstance(entry, Mapping):
            continue
        if entry.get("kit_lang") == lang and entry.get("cefr_band") == "A1":
            keys.append(str(unit_key))
    return sorted(keys, key=_unit_order_key)


def load_a1_lexicon(lang: str, root: Path | None = None) -> list[dict[str, Any]]:
    path = repo_root(root) / LEXICON_REL / f"{lang}.json"
    if not path.is_file():
        raise FileNotFoundError(f"A1 lexicon manifest not found: {path}")
    doc = json.loads(path.read_text(encoding="utf-8"))
    rows = doc.get("lexemes")
    if not isinstance(rows, list):
        raise SpiralPlannerError("LEXICON_INVALID", f"{path}: missing lexemes array")
    out: list[dict[str, Any]] = []
    for row in rows:
        if isinstance(row, Mapping) and row.get("id"):
            out.append(dict(row))
    if not out:
        raise SpiralPlannerError("LEXICON_EMPTY", f"{path}: no lexeme rows")
    return out


def plan_lexeme_exposures(
    lexeme_id: str,
    lexeme_index: int,
    unit_keys: Sequence[str],
) -> list[SpiralExposure]:
    if len(unit_keys) < MIN_EXPOSURES:
        raise SpiralPlannerError(
            "INSUFFICIENT_UNITS",
            f"need at least {MIN_EXPOSURES} A1 units, got {len(unit_keys)}",
        )
    exposures: list[SpiralExposure] = []
    for seq in range(MIN_EXPOSURES):
        unit_key = unit_keys[(lexeme_index + seq) % len(unit_keys)]
        phase = EXPOSURE_PHASES[seq]
        exposures.append(
            SpiralExposure(
                lexeme_id=lexeme_id,
                unit_key=unit_key,
                phase=phase,
                sequence=seq + 1,
            )
        )
    return exposures


def build_spiral_plan(
    lang: str,
    *,
    lexemes: Sequence[Mapping[str, Any]],
    unit_keys: Sequence[str],
) -> dict[str, Any]:
    if len(unit_keys) < MIN_EXPOSURES:
        raise SpiralPlannerError(
            "INSUFFICIENT_UNITS",
            f"{lang}: need at least {MIN_EXPOSURES} A1 units, got {len(unit_keys)}",
        )
    exposures: list[dict[str, Any]] = []
    for index, row in enumerate(lexemes):
        lexeme_id = str(row["id"])
        for exp in plan_lexeme_exposures(lexeme_id, index, unit_keys):
            exposures.append(exp.to_dict())
    lexeme_ids = [str(row["id"]) for row in lexemes]
    plan = {
        "card": CARD_ID,
        "lang": lang,
        "level": "A1",
        "min_exposures": MIN_EXPOSURES,
        "exposure_phases": list(EXPOSURE_PHASES),
        "units": list(unit_keys),
        "lexeme_count": len(lexemes),
        "lexeme_ids": lexeme_ids,
        "exposures": exposures,
    }
    lint_spiral_plan(plan)
    return plan


def build_spiral_plan_for_language(lang: str, root: Path | None = None) -> dict[str, Any]:
    base = repo_root(root)
    map_doc = load_map(base)
    unit_keys = list_a1_units(map_doc, lang)
    lexemes = load_a1_lexicon(lang, base)
    return build_spiral_plan(lang, lexemes=lexemes, unit_keys=unit_keys)


def exposure_counts_by_lexeme(plan: Mapping[str, Any]) -> dict[str, int]:
    counts: dict[str, int] = {}
    rows = plan.get("exposures")
    if not isinstance(rows, list):
        return counts
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        lexeme_id = str(row.get("lexeme_id", ""))
        if not lexeme_id:
            continue
        counts[lexeme_id] = counts.get(lexeme_id, 0) + 1
    return counts


def phases_for_lexeme(plan: Mapping[str, Any], lexeme_id: str) -> list[str]:
    rows = plan.get("exposures")
    if not isinstance(rows, list):
        return []
    picked: list[tuple[int, str]] = []
    for row in rows:
        if not isinstance(row, Mapping):
            continue
        if str(row.get("lexeme_id")) != lexeme_id:
            continue
        seq = int(row.get("sequence", 0))
        picked.append((seq, str(row.get("phase", ""))))
    picked.sort(key=lambda pair: pair[0])
    return [phase for _, phase in picked]


def lint_spiral_plan(plan: Mapping[str, Any]) -> None:
    """Raise [SpiralShortfall] when any lexeme has fewer than six exposures."""
    min_exp = int(plan.get("min_exposures", MIN_EXPOSURES))
    counts = exposure_counts_by_lexeme(plan)
    lexeme_ids = plan.get("lexeme_ids")
    if isinstance(lexeme_ids, list) and lexeme_ids:
        candidates = [str(row) for row in lexeme_ids]
    else:
        candidates = list(counts.keys())
    shortfall = [lexeme_id for lexeme_id in candidates if counts.get(lexeme_id, 0) < min_exp]
    if shortfall:
        raise SpiralShortfall(shortfall)
    for lexeme_id in counts:
        phases = phases_for_lexeme(plan, lexeme_id)
        if phases[:4] != list(EXPOSURE_PHASES[:4]):
            raise SpiralPlannerError(
                "PHASE_ORDER",
                f"{lexeme_id}: expected input→controlled_practice→speaking→review",
            )


def _main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Plan spiral A1 lexeme exposures (P5-018).")
    parser.add_argument("--lang", action="append", dest="langs", help="Stage-1 language code")
    parser.add_argument(
        "--lint-only",
        action="store_true",
        help="Build plan from repo assets and lint (default action).",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)
    langs = tuple(args.langs) if args.langs else STAGE1_LANGS
    try:
        for lang in langs:
            plan = build_spiral_plan_for_language(lang)
            print(
                f"{lang}: {plan['lexeme_count']} lexemes, "
                f"{len(plan['exposures'])} exposures across {len(plan['units'])} units"
            )
    except SpiralPlannerError as exc:
        print(f"{exc.code}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
