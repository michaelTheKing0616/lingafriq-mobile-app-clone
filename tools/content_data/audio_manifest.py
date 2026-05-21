# -*- coding: utf-8 -*-
"""Builds audio_manifest.json keyed to curriculum vocab and game words."""

from __future__ import annotations

import hashlib
import re
from typing import Any

CDN_BASE = "https://cdn.lingafriq.com/audio/v2"


def _slug(text: str, lang: str) -> str:
    base = re.sub(r"[^\w]+", "-", text.lower().strip())
    base = re.sub(r"-+", "-", base).strip("-")[:80]
    return f"{lang}-{base}" if base else f"{lang}-phrase"


def _entry_id(lang: str, text: str) -> str:
    digest = hashlib.sha256(f"{lang}:{text}".encode("utf-8")).hexdigest()[:12]
    return f"{lang}-{digest}"


def build_audio_manifest(
    game_content: dict[str, Any],
    curriculum: dict[str, Any],
) -> dict[str, Any]:
    entries: list[dict] = []
    seen: set[str] = set()

    def add(lang: str, text: str, meaning: str, source: str, cefr: str = "A1") -> None:
        key = f"{lang}|{text}"
        if key in seen or not text.strip():
            return
        seen.add(key)
        eid = _entry_id(lang, text)
        slug = _slug(text, lang)
        entries.append({
            "id": eid,
            "language": lang,
            "text": text,
            "meaning": meaning,
            "source": source,
            "cefr": cefr,
            "slow": {
                "asset_path": f"assets/audio/{lang}/slow/{slug}.mp3",
                "cdn_url": f"{CDN_BASE}/{lang}/slow/{slug}.mp3",
                "tts_rate": 0.52,
            },
            "native": {
                "asset_path": f"assets/audio/{lang}/native/{slug}.mp3",
                "cdn_url": f"{CDN_BASE}/{lang}/native/{slug}.mp3",
                "tts_rate": 0.95,
            },
        })

    for w in game_content.get("words", []):
        add(
            w["language"],
            w["word"],
            w.get("english_meaning", ""),
            "game_word",
            w.get("cefr", "A1"),
        )

    for lang_block in curriculum.get("languages", {}).values():
        if not isinstance(lang_block, dict):
            continue
        for level, units in lang_block.items():
            if not isinstance(units, list):
                continue
            for unit in units:
                for lesson in unit.get("lessons", []):
                    for v in lesson.get("vocab", []):
                        add(
                            lesson["id"].split("-")[0].lower()
                            if "-" in lesson.get("id", "")
                            else "yoruba",
                            v.get("word", ""),
                            v.get("meaning", ""),
                            "curriculum_vocab",
                            lesson.get("tags", {}).get("difficulty", level),
                        )
                    # Fix language from lesson tags — use vocab lookup below
                for lesson in unit.get("lessons", []):
                    lid = lesson.get("id", "")
                    lang_guess = lid.split("-")[0].lower() if lid else ""
                    lang_map = {
                        "yoruba": "yoruba",
                        "hausa": "hausa",
                        "igbo": "igbo",
                        "swahili": "swahili",
                        "zulu": "zulu",
                        "xhosa": "xhosa",
                        "wolof": "wolof",
                        "nigerian": "pidgin",
                        "pidgin": "pidgin",
                    }
                    lang_key = lang_map.get(lang_guess, lang_guess)
                    for v in lesson.get("vocab", []):
                        add(
                            lang_key,
                            v.get("word", ""),
                            v.get("meaning", ""),
                            "curriculum_vocab",
                            lesson.get("tags", {}).get("difficulty", level),
                        )

    # Rebuild with proper language keys from curriculum structure
    entries.clear()
    seen.clear()
    for repo_lang, levels in curriculum.get("languages", {}).items():
        lang = "pidgin" if repo_lang in ("nigerian_pidgin", "pidgin") else repo_lang
        if not isinstance(levels, dict):
            continue
        for level, units in levels.items():
            if not isinstance(units, list):
                continue
            for unit in units:
                for lesson in unit.get("lessons", []):
                    for v in lesson.get("vocab", []):
                        add(
                            lang,
                            v.get("word", ""),
                            v.get("meaning", ""),
                            "curriculum_vocab",
                            level,
                        )

    return {
        "meta": {
            "version": "1.0.0",
            "description": "Slow + native audio keys for curriculum and game vocabulary",
            "recording_spec": "Native speaker studio WAV → MP3 48kHz; slow track 0.52x or dedicated take",
            "entry_count": len(entries),
        },
        "entries": entries,
    }
