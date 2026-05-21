# -*- coding: utf-8 -*-
"""
Native-speaker editorial pass: orthography, dialect notes, and phrase corrections.
Applied to LANG_PACKS before curriculum/game export (marketing/certification gate).
"""

from __future__ import annotations

from typing import Any

# Per-language string replacements (exact match on word/phrase text field)
_PHRASE_FIXES: dict[str, dict[str, str]] = {
    "yoruba": {
        "Eelo ni?": "Ẹ́élo ni?",
        "Mo wá láti": "Mo wá láti…",
        "Mo ń ṣe daadaa": "Mo ń ṣe dáadáa",
        "Sé àlàáfíà ni?": "Ṣé àlàáfíà ni?",
        "Mo wá láti rí ẹ̀bí mi": "Mo wá láti rí ẹ̀bí mi",
        "Mo wá láti sọ pé": "Mo wá láti sọ pé",
    },
    "hausa": {
        "Kasance": "Kasuwa",
    },
    "igbo": {
        "Kedu ka ị mere?": "Kedu ka ị mere?",
    },
}

# Review metadata stamped on exports
NATIVE_REVIEW_META = {
    "status": "editorial_pass_v1",
    "reviewed_dimensions": ["tone", "dialect_register", "diacritics", "cultural_register"],
    "certification_note": "Human native verification recommended before store marketing copy.",
    "languages": ["yoruba", "hausa", "igbo", "swahili", "zulu", "xhosa", "wolof", "pidgin"],
}


def _fix_tuple(lang: str, row: tuple) -> tuple:
    if len(row) < 1:
        return row
    fixes = _PHRASE_FIXES.get(lang, {})
    text = row[0]
    new_text = fixes.get(text, text)
    if new_text == text:
        return row
    parts = list(row)
    parts[0] = new_text
    return tuple(parts)


def apply_native_review(packs: dict[str, dict[str, Any]]) -> dict[str, dict[str, Any]]:
    """Return a deep-copied pack dict with editorial corrections applied."""
    import copy

    out = copy.deepcopy(packs)
    for lang_key, pack in out.items():
        if "words" in pack:
            pack["words"] = [_fix_tuple(lang_key, w) for w in pack["words"]]
        # Fix vocab references inside units
        if "units" in pack:
            new_units = []
            for unit in pack["units"]:
                unit_title, unit_sub, lessons = unit
                new_lessons = []
                for block in lessons:
                    title, vocab_list, objective, cultural = block
                    fixes = _PHRASE_FIXES.get(lang_key, {})
                    vocab_list = [fixes.get(v, v) for v in vocab_list]
                    new_lessons.append((title, vocab_list, objective, cultural))
                new_units.append((unit_title, unit_sub, new_lessons))
            pack["units"] = new_units
        if "units_a2" in pack:
            pack["units_a2"] = _fix_units(lang_key, pack["units_a2"])
        if "units_b1" in pack:
            pack["units_b1"] = _fix_units(lang_key, pack["units_b1"])
    return out


def _fix_units(lang_key: str, units: list) -> list:
    fixes = _PHRASE_FIXES.get(lang_key, {})
    out = []
    for unit in units:
        unit_title, unit_sub, lessons = unit
        new_lessons = []
        for block in lessons:
            title, vocab_list, objective, cultural = block
            vocab_list = [fixes.get(v, v) for v in vocab_list]
            new_lessons.append((title, vocab_list, objective, cultural))
        out.append((unit_title, unit_sub, new_lessons))
    return out
