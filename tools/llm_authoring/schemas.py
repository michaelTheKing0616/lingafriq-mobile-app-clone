"""Strict schemas for the LingAfriq LLM authoring pipeline.

We intentionally use ``dataclasses`` instead of pydantic to keep this
package dependency-light. The validators in ``review_checks.py`` apply
deeper semantic rules; this module only enforces structure.
"""

from __future__ import annotations

import dataclasses
import json
from dataclasses import dataclass, field
from typing import Any, Iterable

SUPPORTED_LANGUAGES: tuple[str, ...] = (
    "yoruba",
    "hausa",
    "igbo",
    "swahili",
    "zulu",
    "xhosa",
    "wolof",
    "pidgin",
    "amharic",
    "twi",
    "somali",
    "lingala",
    "shona",
    "arabic",
)

SUPPORTED_LEVELS: tuple[str, ...] = ("A1", "A2", "B1", "B2", "C1", "C2")


@dataclass
class VocabEntry:
    word: str
    meaning: str
    pos: str = "phrase"
    example: str = ""
    pronunciation: str = ""

    def to_dict(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


@dataclass
class DialogueTurn:
    speaker: str
    text: str
    translation: str

    def to_dict(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


@dataclass
class DialogueScene:
    label: str
    script: list[DialogueTurn] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "label": self.label,
            "script": [t.to_dict() for t in self.script],
        }


@dataclass
class LessonDraft:
    """A single curriculum lesson draft, level A1–C2.

    Mirrors the shape consumed by the Flutter ``CurriculumLesson`` model.
    Persisted as JSON in ``content_drafts/<lang>/<level>/<id>.json``.
    """

    lang: str
    level: str
    unit: int
    lesson: int
    title: str
    objective: str
    cultural_notes: str
    vocab: list[VocabEntry]
    grammar: list[str]
    dialogue_scenes: list[DialogueScene]
    polie_roleplay_prompt: str
    polie_roleplay_persona: str
    cefr_tags: dict[str, str]
    duration_min: int = 14
    drafted_by: str = "claude-sonnet-4.5"
    verified_by: str = "gpt-5"
    review_status: str = "pending"
    review_notes: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.lesson_id(),
            "lang": self.lang,
            "level": self.level,
            "unit": self.unit,
            "lesson": self.lesson,
            "title": self.title,
            "objective": self.objective,
            "cultural_notes": self.cultural_notes,
            "duration_min": self.duration_min,
            "vocab": [v.to_dict() for v in self.vocab],
            "grammar": list(self.grammar),
            "dialogue": {
                "scenes": [s.to_dict() for s in self.dialogue_scenes],
                "script": [
                    t.to_dict()
                    for s in self.dialogue_scenes
                    for t in s.script
                ],
                "scene": self.dialogue_scenes[0].label if self.dialogue_scenes else "",
                "turn_count": sum(len(s.script) for s in self.dialogue_scenes),
            },
            "polie_roleplay": {
                "prompt": self.polie_roleplay_prompt,
                "persona": self.polie_roleplay_persona,
                "correction_level": "gentle",
            },
            "tags": dict(self.cefr_tags),
            "drafted_by": self.drafted_by,
            "verified_by": self.verified_by,
            "review_status": self.review_status,
            "review_notes": list(self.review_notes),
        }

    def lesson_id(self) -> str:
        return f"{self.lang}-{self.level}-u{self.unit}-l{self.lesson}"

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "LessonDraft":
        vocab = [VocabEntry(**v) for v in data.get("vocab", [])]
        scenes: list[DialogueScene] = []
        for scene in (data.get("dialogue", {}) or {}).get("scenes", []):
            turns = [DialogueTurn(**t) for t in scene.get("script", [])]
            scenes.append(DialogueScene(label=scene.get("label", ""), script=turns))
        roleplay = data.get("polie_roleplay", {}) or {}
        return cls(
            lang=data["lang"],
            level=data["level"],
            unit=int(data.get("unit", 1)),
            lesson=int(data.get("lesson", 1)),
            title=data.get("title", ""),
            objective=data.get("objective", ""),
            cultural_notes=data.get("cultural_notes", ""),
            vocab=vocab,
            grammar=list(data.get("grammar", []) or []),
            dialogue_scenes=scenes,
            polie_roleplay_prompt=roleplay.get("prompt", ""),
            polie_roleplay_persona=roleplay.get("persona", "Encouraging Mentor"),
            cefr_tags=dict(data.get("tags", {}) or {}),
            duration_min=int(data.get("duration_min", 14)),
            drafted_by=data.get("drafted_by", "claude-sonnet-4.5"),
            verified_by=data.get("verified_by", "gpt-5"),
            review_status=data.get("review_status", "pending"),
            review_notes=list(data.get("review_notes", []) or []),
        )


@dataclass
class GameVocabCard:
    word: str
    meaning: str
    category: str
    difficulty: str
    example: str = ""
    pronunciation: str = ""

    def to_dict(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


@dataclass
class GameProverbCard:
    original: str
    translation: str
    meaning: str
    region: str = ""

    def to_dict(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


@dataclass
class GameContentDraft:
    lang: str
    level: str
    vocab_cards: list[GameVocabCard]
    proverbs: list[GameProverbCard]
    drafted_by: str = "claude-sonnet-4.5"
    review_status: str = "pending"
    review_notes: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return {
            "lang": self.lang,
            "level": self.level,
            "vocab_cards": [c.to_dict() for c in self.vocab_cards],
            "proverbs": [p.to_dict() for p in self.proverbs],
            "drafted_by": self.drafted_by,
            "review_status": self.review_status,
            "review_notes": list(self.review_notes),
        }


@dataclass
class ReviewIssue:
    severity: str  # error | warning | info
    code: str
    message: str
    where: str = ""

    def to_dict(self) -> dict[str, Any]:
        return dataclasses.asdict(self)


@dataclass
class ReviewReport:
    target_id: str
    issues: list[ReviewIssue] = field(default_factory=list)

    @property
    def is_passing(self) -> bool:
        return not any(i.severity == "error" for i in self.issues)

    @property
    def error_count(self) -> int:
        return sum(1 for i in self.issues if i.severity == "error")

    @property
    def warning_count(self) -> int:
        return sum(1 for i in self.issues if i.severity == "warning")

    def add(self, severity: str, code: str, message: str, where: str = "") -> None:
        self.issues.append(ReviewIssue(severity, code, message, where))

    def merge(self, other: "ReviewReport") -> None:
        self.issues.extend(other.issues)

    def to_dict(self) -> dict[str, Any]:
        return {
            "target_id": self.target_id,
            "is_passing": self.is_passing,
            "error_count": self.error_count,
            "warning_count": self.warning_count,
            "issues": [i.to_dict() for i in self.issues],
        }


def json_dump(obj: Any) -> str:
    return json.dumps(obj, indent=2, ensure_ascii=False, sort_keys=True)


def validate_supported(lang: str, level: str) -> None:
    if lang not in SUPPORTED_LANGUAGES:
        raise ValueError(
            f"Unsupported language '{lang}'. "
            f"Expected one of: {', '.join(SUPPORTED_LANGUAGES)}"
        )
    if level not in SUPPORTED_LEVELS:
        raise ValueError(
            f"Unsupported level '{level}'. "
            f"Expected one of: {', '.join(SUPPORTED_LEVELS)}"
        )


def iter_supported_targets(
    languages: Iterable[str] | None = None,
    levels: Iterable[str] | None = None,
) -> list[tuple[str, str]]:
    langs = list(languages) if languages else list(SUPPORTED_LANGUAGES)
    lvls = list(levels) if levels else list(SUPPORTED_LEVELS)
    for lang in langs:
        if lang not in SUPPORTED_LANGUAGES:
            raise ValueError(f"Unsupported language '{lang}'")
    for lvl in lvls:
        if lvl not in SUPPORTED_LEVELS:
            raise ValueError(f"Unsupported level '{lvl}'")
    return [(lang, lvl) for lang in langs for lvl in lvls]
