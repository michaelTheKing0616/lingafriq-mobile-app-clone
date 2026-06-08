# -*- coding: utf-8 -*-
"""Extra vocabulary for games + supplemental curriculum lessons."""

from __future__ import annotations

from typing import Any

# (surface_form, english_gloss, part_of_speech, phonetic_or_tone, cultural_note, cefr)
WordRow = tuple[str, str, str, str, str, str]

_LEVEL_KEYS: list[tuple[str, str]] = [
    ("units", "A1"),
    ("units_a2", "A2"),
    ("units_b1", "B1"),
    ("units_b2", "B2"),
    ("units_c1", "C1"),
    ("units_c2", "C2"),
]

# Target ≥120 lessons per language on the full A1–C2 track (~1,680 total for 14 langs).
_TARGET_LESSONS_PER_LEVEL = 20


def _vocab_from_units(units: list, cefr: str) -> list[WordRow]:
    rows: list[WordRow] = []
    seen: set[str] = set()
    for _title, _sub, lessons in units:
        for lesson_title, vocab, _obj, note in lessons:
            topic = lesson_title[:40]
            for token in vocab:
                key = token.strip().lower()
                if not key or key in seen:
                    continue
                seen.add(key)
                rows.append(
                    (
                        token,
                        topic,
                        "phrase",
                        "",
                        note or "",
                        cefr,
                    )
                )
    return rows


def collect_curriculum_vocab_rows(pack: dict[str, Any]) -> list[WordRow]:
    """Harvest lesson tokens from all CEFR unit blocks in a language pack."""
    out: list[WordRow] = []
    seen: set[str] = set()
    for key, cefr in _LEVEL_KEYS:
        units = pack.get(key) or []
        for row in _vocab_from_units(units, cefr):
            k = row[0].strip().lower()
            if k in seen:
                continue
            seen.add(k)
            out.append(row)
    return out


def merge_expansion_words(pack: dict[str, Any]) -> list[tuple]:
    """Return pack['words'] plus curriculum-derived tokens (deduped)."""
    base = list(pack.get("words") or [])
    seen = {w[0].strip().lower() for w in base}
    merged = list(base)
    for row in collect_curriculum_vocab_rows(pack):
        key = row[0].strip().lower()
        if key in seen:
            continue
        seen.add(key)
        merged.append(row[:5])
    return merged


def _chunk(items: list, size: int) -> list[list]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def _build_units_from_vocab(
    vocab: list[str],
    level: str,
    unit_prefix: str,
) -> list:
    """Build (title, subtitle, lessons) unit tuples from a flat vocab list."""
    if len(vocab) < 6:
        return []
    units = []
    lesson_groups = _chunk(vocab, 3)
    unit_groups = _chunk(lesson_groups, 3)
    for u_idx, group in enumerate(unit_groups, start=1):
        lessons = []
        for l_idx, triple in enumerate(group, start=1):
            lessons.append(
                (
                    f"{level} practice {l_idx}",
                    triple,
                    f"Use these {level} phrases in context.",
                    f"Supplemental {level} track — unit {u_idx}.",
                )
            )
        units.append(
            (
                f"{unit_prefix} {u_idx}",
                f"Extended {level}",
                lessons,
            )
        )
    return units


def augment_curriculum_units(pack: dict[str, Any]) -> None:
    """
    Append supplemental units per level until each level has at least
    _TARGET_LESSONS_PER_LEVEL lessons (in-place on pack).
    """
    for key, level in _LEVEL_KEYS:
        existing = list(pack.get(key) or [])
        lesson_count = sum(len(u[2]) for u in existing)
        if lesson_count >= _TARGET_LESSONS_PER_LEVEL:
            continue
        needed = _TARGET_LESSONS_PER_LEVEL - lesson_count
        # Pool: level vocab + all expansion words for this CEFR
        pool: list[str] = []
        seen: set[str] = set()
        for _t, _s, lessons in existing:
            for _lt, vocab, _o, _n in lessons:
                for v in vocab:
                    k = v.strip().lower()
                    if k and k not in seen:
                        seen.add(k)
                        pool.append(v)
        for row in collect_curriculum_vocab_rows(pack):
            if row[5] != level:
                continue
            k = row[0].strip().lower()
            if k not in seen:
                seen.add(k)
                pool.append(row[0])
        if len(pool) < 6:
            continue
        offset = 0
        guard = 0
        while lesson_count < _TARGET_LESSONS_PER_LEVEL and guard < 24:
            guard += 1
            if offset + 9 > len(pool):
                offset = 0
            take = min(9, len(pool) - offset)
            if take < 6:
                break
            slice_vocab = pool[offset : offset + take]
            offset += take
            extra = _build_units_from_vocab(
                slice_vocab,
                level,
                f"{pack.get('display', level)} depth",
            )
            if not extra:
                break
            for unit in extra:
                if lesson_count >= _TARGET_LESSONS_PER_LEVEL:
                    break
                existing.append(unit)
                lesson_count += len(unit[2])
        pack[key] = existing
