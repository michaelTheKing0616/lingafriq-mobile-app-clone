# -*- coding: utf-8 -*-
"""Builds authentic curriculum lessons with real dialogues and MCQ distractors."""

from __future__ import annotations

import random
from typing import Any

from .native_review import NATIVE_REVIEW_META

# Dialogue templates keyed by lesson title keywords (first match wins)
_DIALOGUE_PATTERNS: list[tuple[str, list[tuple[str, str, str]]]] = [
    (
        "greet",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "thank",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "market|price|food|buy",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "transport|motor|direction|place",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "family|kin|elder|home",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "past|story|yesterday",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "work|office|plan|future",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "opinion|debate|news|health|community",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    ),
    (
        "professional|meeting|media|formal|office",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
            ("B", "{v0}", "{m0}"),
        ],
    ),
    (
        "idiom|proverb|rhetoric|monologue|certification|rebuttal|abstract",
        [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
            ("A", "{v0}", "{m0}"),
        ],
    ),
]

_DEFAULT_DIALOGUE = [
    ("A", "{v0}", "{m0}"),
    ("B", "{v1}", "{m1}"),
    ("A", "{v2}", "{m2}"),
]

_EXAMPLE_TEMPLATES = [
    "{word} — {meaning}.",
    "In conversation: {word}. ({meaning})",
    "Practice saying: {word} when {context}.",
]


def _word_map(pack: dict) -> dict[str, tuple]:
    return {row[0]: row for row in pack["words"]}


def _meaning(pack: dict, word: str) -> str:
    wm = _word_map(pack)
    if word in wm:
        return wm[word][1]
    return "Core phrase"


def _cultural(pack: dict, word: str) -> str:
    wm = _word_map(pack)
    if word in wm:
        row = wm[word]
        return row[4] if len(row) > 4 and row[4] else ""
    return ""


def _example_sentence(pack: dict, word: str, lesson_title: str) -> str:
    meaning = _meaning(pack, word)
    cultural = _cultural(pack, word)
    ctx = lesson_title.lower()
    if cultural:
        return f"{word} — {meaning}. {cultural}"
    tmpl = _EXAMPLE_TEMPLATES[hash(word) % len(_EXAMPLE_TEMPLATES)]
    return tmpl.format(word=word, meaning=meaning, context=ctx)


def _pick_dialogue_pattern(lesson_title: str) -> list[tuple[str, str, str]]:
    t = lesson_title.lower()
    for key, pattern in _DIALOGUE_PATTERNS:
        if any(k in t for k in key.split("|")):
            return pattern
    return _DEFAULT_DIALOGUE


def _build_dialogue(pack: dict, vocab_list: list[str], lesson_title: str) -> dict:
    pattern = _pick_dialogue_pattern(lesson_title)
    while len(vocab_list) < 3:
        vocab_list = vocab_list + vocab_list
    vals = {
        f"v{i}": vocab_list[i] for i in range(3)
    } | {
        f"m{i}": _meaning(pack, vocab_list[i]) for i in range(3)
    }
    script = []
    for speaker, text_t, trans_t in pattern:
        script.append({
            "speaker": speaker,
            "text": text_t.format(**vals),
            "translation": trans_t.format(**vals),
        })
    return {
        "script": script,
        "scene": f"Real-life {lesson_title} — {pack['display']}",
    }


def _unit_vocab_pool(lessons: list) -> list[str]:
    pool: list[str] = []
    for block in lessons:
        pool.extend(block[1])
    seen: set[str] = set()
    out: list[str] = []
    for w in pool:
        if w not in seen:
            seen.add(w)
            out.append(w)
    return out


def _mcq_options(correct: str, pool: list[str], count: int = 4) -> list[str]:
    distractors = [w for w in pool if w != correct]
    random.shuffle(distractors)
    options = [correct] + distractors[: count - 1]
    while len(options) < count and distractors:
        extra = distractors.pop()
        if extra not in options:
            options.append(extra)
    random.shuffle(options)
    return options


def _build_unit_quiz(
    lang_key: str,
    pack: dict,
    unit_title: str,
    u_idx: int,
    lessons: list,
    level: str,
) -> dict:
    pool = _unit_vocab_pool(lessons)
    if not pool:
        pool = [pack["words"][0][0]]
    items = []
    for q_idx, block in enumerate(lessons[:3], start=1):
        correct = block[1][0]
        question = f"Which phrase best fits “{block[0]}” in {pack['display']}?"
        items.append({
            "id": f"{lang_key}-{level}-u{u_idx}-q{q_idx}",
            "type": "mcq",
            "question": question,
            "options": _mcq_options(correct, pool),
            "answer": correct,
        })
    # Meaning reverse question
    if len(pool) >= 2:
        target = pool[1]
        meaning = _meaning(pack, target)
        items.append({
            "id": f"{lang_key}-{level}-u{u_idx}-q-meaning",
            "type": "mcq",
            "question": f"What does “{target}” mean?",
            "options": _mcq_options(
                meaning,
                [_meaning(pack, w) for w in pool[:6]],
            ),
            "answer": meaning,
        })
    return {"items": items}


def lesson_from_block(
    lang_key: str,
    pack: dict,
    unit_no: int,
    lesson_no: int,
    block: tuple,
    level: str,
) -> dict:
    title, vocab_list, objective, cultural = block
    vocab_objs = []
    for v in vocab_list:
        vocab_objs.append({
            "word": v,
            "meaning": _meaning(pack, v),
            "pos": "phrase",
            "example": _example_sentence(pack, v, title),
        })
    return {
        "id": f"{pack['display']}-{level}-u{unit_no}-l{lesson_no}",
        "title": title,
        "duration_min": 12 if level == "A1" else 14 if level == "A2" else 16,
        "objective": objective,
        "cultural_notes": cultural,
        "tags": {
            "difficulty": level,
            "vocab_theme": title.lower().replace(" ", "_"),
            "cultural_topic": "greetings" if "greet" in title.lower() else "daily_life",
            "pronunciation_difficulty": "tone_aware" if lang_key == "yoruba" else "standard",
            "ai_readiness": "beginner_slow" if level == "A1" else "intermediate",
        },
        "vocab": vocab_objs,
        "dialogue": _build_dialogue(pack, list(vocab_list), title),
        "polie_roleplay": {
            "persona": "Encouraging Mentor",
            "prompt": (
                f"Practice {title}: respond naturally using "
                f"{', '.join(vocab_list[:2])}. Objective: {objective}"
            ),
            "correction_level": "gentle",
        },
        "exercises": [
            {
                "type": "flashcards",
                "items": [f"{v['word']} — {v['meaning']}" for v in vocab_objs],
            },
            {"type": "listening", "items": vocab_list},
            {"type": "speaking", "items": [vocab_list[0]]},
        ],
    }


def _build_level_units(
    lang_key: str,
    pack: dict,
    units_source: list,
    level: str,
) -> list[dict]:
    units_json = []
    for u_idx, (unit_title, unit_sub, lessons) in enumerate(units_source, start=1):
        lesson_objs = []
        for l_idx, block in enumerate(lessons, start=1):
            lesson_objs.append(
                lesson_from_block(lang_key, pack, u_idx, l_idx, block, level)
            )
        units_json.append({
            "unit": u_idx,
            "title": f"Unit {u_idx} — {unit_title}",
            "subtitle": unit_sub,
            "objectives": [
                f"Use {pack['display']} phrases for {unit_title.lower()}",
                "Practice respect and real-world context",
            ],
            "cultural_notes": f"{pack['display']} cultural immersion for {unit_title}.",
            "lessons": lesson_objs,
            "unit_quiz": _build_unit_quiz(
                lang_key, pack, unit_title, u_idx, lessons, level
            ),
        })
    return units_json


def build_curriculum_for_pack(lang_key: str, pack: dict) -> dict[str, list]:
    """Returns {A1, A2, B1, B2, C1} unit arrays when present in pack."""
    levels: dict[str, list] = {"A1": _build_level_units(lang_key, pack, pack["units"], "A1")}
    if pack.get("units_a2"):
        levels["A2"] = _build_level_units(lang_key, pack, pack["units_a2"], "A2")
    if pack.get("units_b1"):
        levels["B1"] = _build_level_units(lang_key, pack, pack["units_b1"], "B1")
    if pack.get("units_b2"):
        levels["B2"] = _build_level_units(lang_key, pack, pack["units_b2"], "B2")
    if pack.get("units_c1"):
        levels["C1"] = _build_level_units(lang_key, pack, pack["units_c1"], "C1")
    return levels


def build_curriculum_a1(lang_packs: dict[str, dict]) -> dict:
    languages_out: dict[str, dict] = {}
    for lang_key, pack in lang_packs.items():
        levels = build_curriculum_for_pack(lang_key, pack)
        repo_lang = "nigerian_pidgin" if lang_key == "pidgin" else lang_key
        languages_out[repo_lang] = levels
        if lang_key == "pidgin":
            languages_out["pidgin"] = levels
    return {
        "meta": {
            "title": "LingAfriq Authentic Curriculum A1–C1",
            "version": "3.0.0",
            "languages": list(languages_out.keys()),
            "levels": ["A1", "A2", "B1", "B2", "C1"],
            "lessons_per_language_full_track": 30,
            "pedagogy": "Understand → imitate → respond → converse",
            "native_review": NATIVE_REVIEW_META,
            "lesson_stages": [
                "warm_opening",
                "context_scene",
                "vocabulary",
                "pronunciation_lab",
                "grammar_pattern",
                "guided_practice",
                "ai_conversation",
                "cultural_intelligence",
                "retention_challenge",
                "victory",
            ],
        },
        "languages": languages_out,
    }


def build_curriculum_a1_only(lang_packs: dict[str, dict]) -> dict:
    """Legacy A1-only export shape."""
    full = build_curriculum_a1(lang_packs)
    a1_only: dict[str, dict] = {}
    for lang, levels in full["languages"].items():
        a1_only[lang] = {"A1": levels.get("A1", [])}
    return {
        "meta": {**full["meta"], "title": "LingAfriq Authentic Curriculum A1", "levels": ["A1"]},
        "languages": a1_only,
    }
