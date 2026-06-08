# -*- coding: utf-8 -*-
"""Builds authentic curriculum lessons with real dialogues and MCQ distractors."""

from __future__ import annotations

import random
from typing import Any

from .native_review import NATIVE_REVIEW_META

# --- Multi-scene dialogue templates --------------------------------------------
# Each pattern lists 2-3 scenes. Every scene has:
#   - label: short English description of the setting/beat
#   - script: list of (speaker, target_template, english_template)
# Templates index vocab as {v0}..{vN} and meanings as {m0}..{mN}; cycling is
# applied if the vocab list is shorter than the highest index referenced.
# We deliberately keep templates "vocab-pure" (each utterance is one or two
# vocab tokens) so they remain safe across all 14 languages without producing
# ungrammatical sentences. The downstream LLM authoring pipeline replaces these
# with fully natural multi-turn dialogues per language as content matures.
_DIALOGUE_PATTERNS: list[tuple[str, list[dict]]] = [
    (
        "greet|hello|welcome|introduction",
        [
            {
                "label": "First meeting on the street",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v0}, {v1}", "{m0}. {m1}"),
                    ("A", "{v2}", "{m2}"),
                    ("B", "{v1}", "{m1}"),
                ],
            },
            {
                "label": "Continuing the introduction",
                "script": [
                    ("A", "{v0} — {v2}", "{m0} — {m2}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
        ],
    ),
    (
        "thank|courtesy|polite|please",
        [
            {
                "label": "Saying thanks after help",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                    ("B", "{v0}", "{m0}"),
                ],
            },
            {
                "label": "Closing the exchange warmly",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v2}", "{m2}"),
                    ("A", "{v0}", "{m0}"),
                ],
            },
        ],
    ),
    (
        "market|price|food|buy|bargain|shop",
        [
            {
                "label": "Approaching the stall",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Negotiating the price",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v0}, {v2}", "{m0}. {m2}"),
                    ("A", "{v2}", "{m2}"),
                    ("B", "{v0}", "{m0}"),
                ],
            },
        ],
    ),
    (
        "transport|motor|direction|place|taxi|travel",
        [
            {
                "label": "Hailing a ride",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Arriving and paying",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v2}", "{m2}"),
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v2}", "{m2}"),
                ],
            },
        ],
    ),
    (
        "family|kin|elder|home|community",
        [
            {
                "label": "Welcoming a visitor",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Family table conversation",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v0}", "{m0}"),
                    ("A", "{v2}", "{m2}"),
                    ("B", "{v0}, {v1}", "{m0}. {m1}"),
                ],
            },
        ],
    ),
    (
        "past|story|yesterday|memory",
        [
            {
                "label": "Sharing what happened",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Reflecting on the story",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v2}", "{m2}"),
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v2}", "{m2}"),
                ],
            },
        ],
    ),
    (
        "work|office|plan|future|career|job",
        [
            {
                "label": "Morning check-in",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Planning the week",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v2}", "{m2}"),
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}, {v2}", "{m1}. {m2}"),
                ],
            },
        ],
    ),
    (
        "opinion|debate|news|health|community|values",
        [
            {
                "label": "Opening a conversation",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Sharing a view",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v2}", "{m2}"),
                    ("A", "{v0}", "{m0}"),
                ],
            },
            {
                "label": "Finding common ground",
                "script": [
                    ("A", "{v2}", "{m2}"),
                    ("B", "{v0}", "{m0}"),
                ],
            },
        ],
    ),
    (
        "professional|meeting|media|formal",
        [
            {
                "label": "Opening the meeting",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Discussion",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v2}", "{m2}"),
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Closing remarks",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                ],
            },
        ],
    ),
    (
        "idiom|proverb|rhetoric|monologue|certification|rebuttal|abstract|mastery",
        [
            {
                "label": "Setting up the argument",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}", "{m1}"),
                    ("A", "{v2}", "{m2}"),
                ],
            },
            {
                "label": "Counter and refinement",
                "script": [
                    ("A", "{v1}", "{m1}"),
                    ("B", "{v2}", "{m2}"),
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v1}, {v2}", "{m1}. {m2}"),
                ],
            },
            {
                "label": "Closing with conviction",
                "script": [
                    ("A", "{v0}", "{m0}"),
                    ("B", "{v2}", "{m2}"),
                ],
            },
        ],
    ),
]

_DEFAULT_DIALOGUE: list[dict] = [
    {
        "label": "Daily exchange",
        "script": [
            ("A", "{v0}", "{m0}"),
            ("B", "{v1}", "{m1}"),
            ("A", "{v2}", "{m2}"),
        ],
    },
    {
        "label": "Following up",
        "script": [
            ("A", "{v1}", "{m1}"),
            ("B", "{v2}", "{m2}"),
            ("A", "{v0}", "{m0}"),
        ],
    },
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


def _pick_dialogue_pattern(lesson_title: str) -> list[dict]:
    t = lesson_title.lower()
    for key, pattern in _DIALOGUE_PATTERNS:
        if any(k in t for k in key.split("|")):
            return pattern
    return _DEFAULT_DIALOGUE


def _build_dialogue(pack: dict, vocab_list: list[str], lesson_title: str) -> dict:
    """Build a multi-scene dialogue (6-10 turns) for a lesson.

    The dialogue payload is intentionally backward compatible:
    - `script` is a flat array of turns across all scenes (old consumers).
    - `scene` is a single human-readable label (old consumers).
    - `scenes` is the new structured array of {label, script} (new consumers).
    """
    scenes_template = _pick_dialogue_pattern(lesson_title)

    # Ensure we have at least 3 vocab tokens by cycling.
    vocab = list(vocab_list)
    while len(vocab) < 3:
        vocab = vocab + vocab

    # Build value map for v0..v9 by cycling through vocab.
    max_refs = 10
    vals: dict[str, str] = {}
    for i in range(max_refs):
        token = vocab[i % len(vocab)]
        vals[f"v{i}"] = token
        vals[f"m{i}"] = _meaning(pack, token)

    structured_scenes: list[dict] = []
    flat_script: list[dict] = []

    for scene in scenes_template:
        scene_script: list[dict] = []
        for speaker, text_t, trans_t in scene["script"]:
            turn = {
                "speaker": speaker,
                "text": text_t.format(**vals),
                "translation": trans_t.format(**vals),
            }
            scene_script.append(turn)
            flat_script.append(turn)
        structured_scenes.append({
            "label": scene["label"],
            "script": scene_script,
        })

    primary_label = structured_scenes[0]["label"] if structured_scenes else lesson_title
    return {
        "script": flat_script,
        "scene": f"{primary_label} — {pack['display']} ({lesson_title})",
        "scenes": structured_scenes,
        "turn_count": len(flat_script),
    }


# --- Grammar notes -------------------------------------------------------------
# Lightweight, language-agnostic grammar/pattern notes selected per lesson.
# Real per-language grammar will come from the LLM authoring pipeline; until
# then these give learners structural anchors instead of dumping pure vocab.
_GRAMMAR_NOTES: list[tuple[str, list[str]]] = [
    (
        "greet|hello|welcome|introduction",
        [
            "Pattern: greeting → reply → follow-up question.",
            "Always greet before asking anything else.",
            "Use the polite/elder form when in doubt.",
        ],
    ),
    (
        "thank|courtesy|polite|please",
        [
            "Pattern: request softener + verb (please-style construction).",
            "Reply to thanks with a short acknowledgement, not silence.",
        ],
    ),
    (
        "market|price|food|buy|bargain|shop",
        [
            "Pattern: greet → ask price → compliment goods → counter-offer.",
            "Numbers often follow the noun in African languages; learn the noun first.",
            "Bargaining is dialogue, not a single offer.",
        ],
    ),
    (
        "transport|motor|direction|place|taxi|travel",
        [
            "Pattern: destination first, then ask the price/route.",
            "Use 'where is …?' frames instead of long descriptions.",
        ],
    ),
    (
        "family|kin|elder|home|community",
        [
            "Pattern: respect title + name (e.g. mama, baba, anty).",
            "Elders use the plural/honorific form even when addressed alone.",
        ],
    ),
    (
        "past|story|yesterday|memory",
        [
            "Pattern: time marker first, then verb in past form.",
            "Stories often open with a fixed phrase ('once upon a time…').",
        ],
    ),
    (
        "work|office|plan|future|career|job",
        [
            "Pattern: subject + future marker + verb.",
            "Polite agreements close with a confirmation phrase.",
        ],
    ),
    (
        "opinion|debate|news|health|community|values",
        [
            "Pattern: 'I think that…' frame to introduce an opinion.",
            "Agree first, then nuance, then disagree if needed.",
        ],
    ),
    (
        "professional|meeting|media|formal",
        [
            "Use formal register: full sentences, no slang.",
            "Pattern: state purpose → discuss → summarise → close.",
        ],
    ),
    (
        "idiom|proverb|rhetoric|monologue|certification|rebuttal|abstract|mastery",
        [
            "Idioms are non-literal — learn the meaning whole, not word-by-word.",
            "Pattern: claim → evidence → proverb-style summary.",
        ],
    ),
]


def _grammar_notes_for(title: str, level: str) -> list[str]:
    t = title.lower()
    notes: list[str] = []
    for key, items in _GRAMMAR_NOTES:
        if any(k in t for k in key.split("|")):
            notes.extend(items)
            break
    if not notes:
        notes = [
            "Pattern: subject → verb → object (default sentence order).",
            "Listen for the verb stem; affixes carry tense and person.",
        ]
    if level in {"B2", "C1", "C2"}:
        notes.append(
            "Aim for natural rhythm: vary sentence length and use connectors."
        )
    if level in {"C1", "C2"}:
        notes.append(
            "Register: switch between formal and informal as the audience shifts."
        )
    return notes[:4]


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
        "grammar": _grammar_notes_for(title, level),
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
    """Returns {A1, A2, B1, B2, C1, C2} unit arrays when present in pack."""
    levels: dict[str, list] = {"A1": _build_level_units(lang_key, pack, pack["units"], "A1")}
    if pack.get("units_a2"):
        levels["A2"] = _build_level_units(lang_key, pack, pack["units_a2"], "A2")
    if pack.get("units_b1"):
        levels["B1"] = _build_level_units(lang_key, pack, pack["units_b1"], "B1")
    if pack.get("units_b2"):
        levels["B2"] = _build_level_units(lang_key, pack, pack["units_b2"], "B2")
    if pack.get("units_c1"):
        levels["C1"] = _build_level_units(lang_key, pack, pack["units_c1"], "C1")
    if pack.get("units_c2"):
        levels["C2"] = _build_level_units(lang_key, pack, pack["units_c2"], "C2")
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
            "title": "LingAfriq Authentic Curriculum A1–C2",
            "version": "4.0.0",
            "languages": list(languages_out.keys()),
            "levels": ["A1", "A2", "B1", "B2", "C1", "C2"],
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
