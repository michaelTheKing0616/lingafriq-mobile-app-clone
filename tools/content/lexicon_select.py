"""Select frequency-ranked A1 lexicon per Stage-1 language (P5-016, CURRICULUM §4)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content_engine.curriculum.import_packs import (
    canonical_packs_dir,
    load_curriculum_register,
    repo_root,
)
from tools.content_pipeline.validate_content import has_tone_mark

CARD_ID = "P5-016"
OUTPUT_REL = "assets/data/lexicon/a1"
STAGE1_LANGS: tuple[str, ...] = ("yo", "ig", "ha", "pcm", "sw", "zu", "xh")
TONAL_LANGS = frozenset({"yo", "ig", "ha"})
MIN_LEXEMES = 600
MAX_LEXEMES = 800
DEFAULT_TARGET = 700

# CURRICULUM §4 — learner-needs domains (English gloss / claim text only; no invented lemmas).
_LEARNER_DOMAIN_MARKERS: tuple[str, ...] = (
    "family",
    "food",
    "market",
    "church",
    "mosque",
    "transport",
    "phone",
    "money",
    "taxi",
    "bus",
    "greet",
    "hello",
)
_LEARNER_BOOST = 40


class LexiconSelectError(Exception):
    """Lexicon selection failed. `code` is stable for gates and tests."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class LicenceUnregistered(LexiconSelectError):
    """Frequency or anchor source is not in the licence register."""


class LexiconCountGateError(LexiconSelectError):
    """Language lexeme count is outside 600–800."""


@dataclass(frozen=True)
class RankedLexeme:
    id: str
    lemma: str
    frequency_rank: int
    adjusted_rank: int
    frequency_source_id: str
    licence_id: str
    lexicon_anchor: str | None
    linguist_review: bool
    beta_eligible: bool
    learner_boosted: bool

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "lemma": self.lemma,
            "frequency_rank": self.frequency_rank,
            "adjusted_rank": self.adjusted_rank,
            "frequency_source_id": self.frequency_source_id,
            "licence_id": self.licence_id,
            "lexicon_anchor": self.lexicon_anchor,
            "linguist_review": self.linguist_review,
            "beta_eligible": self.beta_eligible,
            "learner_boosted": self.learner_boosted,
        }


def _register_allows_ship(row: Mapping[str, Any]) -> bool:
    use = str(row.get("use", "")).strip().lower()
    return use.startswith("ship")


def assert_registered_source(source_id: str, register: Mapping[str, Mapping[str, Any]]) -> str:
    """Return licence register id when source is registered for shipped use."""
    sid = source_id.strip()
    if not sid:
        raise LicenceUnregistered("LicenceUnregistered", "empty source_id")
    row = register.get(sid)
    if row is None:
        raise LicenceUnregistered(
            "LicenceUnregistered",
            f"source_id not in licence register: {sid}",
        )
    if not _register_allows_ship(row):
        raise LicenceUnregistered(
            "LicenceUnregistered",
            f"source_id {sid!r} is not cleared for shipped frequency use",
        )
    return sid


def _lemma_from_item(item: Mapping[str, Any]) -> str:
    text = item.get("text")
    if isinstance(text, str) and text.strip():
        return text.strip()
    orth = item.get("orthography")
    if isinstance(orth, Mapping):
        standard = orth.get("standard")
        if isinstance(standard, str) and standard.strip():
            return standard.strip()
    lemma = item.get("lemma")
    if isinstance(lemma, str) and lemma.strip():
        return lemma.strip()
    raise LexiconSelectError("LEMMA_MISSING", "lexeme item has no lemma/text")


def _frequency_source_id(item: Mapping[str, Any]) -> str:
    provenance = item.get("provenance")
    if not isinstance(provenance, Mapping):
        raise LexiconSelectError("PROVENANCE_MISSING", "provenance required for frequency source")
    sources = provenance.get("sources")
    if not isinstance(sources, list):
        raise LexiconSelectError("PROVENANCE_MISSING", "provenance.sources required")
    shipped: list[str] = []
    for entry in sources:
        if not isinstance(entry, Mapping):
            continue
        role = str(entry.get("role", "")).strip().lower()
        sid = entry.get("source_id")
        if role in {"shipped_text", "anchor"} and isinstance(sid, str) and sid.strip():
            shipped.append(sid.strip())
    if not shipped:
        raise LexiconSelectError("FREQUENCY_SOURCE_MISSING", "no shipped_text source on lexeme")
    return shipped[0]


def _lexicon_anchor(item: Mapping[str, Any], lemma: str, lang: str) -> str | None:
    orth = item.get("orthography")
    if isinstance(orth, Mapping) and orth.get("tone_marked") is True:
        return lemma
    if lang in TONAL_LANGS and has_tone_mark(lemma):
        return lemma
    provenance = item.get("provenance")
    if isinstance(provenance, Mapping):
        sources = provenance.get("sources")
        if isinstance(sources, list):
            for entry in sources:
                if not isinstance(entry, Mapping):
                    continue
                if str(entry.get("role", "")).strip().lower() == "anchor":
                    locator = entry.get("locator")
                    if isinstance(locator, str) and locator.strip():
                        return locator.strip()
                    if isinstance(lemma, str) and lemma.strip():
                        return lemma.strip()
    if lang not in TONAL_LANGS:
        return lemma
    return None


def _learner_text_blob(item: Mapping[str, Any]) -> str:
    parts: list[str] = []
    senses = item.get("senses")
    if isinstance(senses, list):
        for sense in senses:
            if isinstance(sense, Mapping):
                gloss = sense.get("gloss_en")
                if isinstance(gloss, str):
                    parts.append(gloss)
    claims = item.get("claims")
    if isinstance(claims, list):
        for claim in claims:
            if isinstance(claim, Mapping):
                text = claim.get("text")
                if isinstance(text, str):
                    parts.append(text)
    return " ".join(parts).lower()


def learner_needs_boost(item: Mapping[str, Any]) -> bool:
    blob = _learner_text_blob(item)
    if not blob:
        return False
    return any(marker in blob for marker in _LEARNER_DOMAIN_MARKERS)


def adjusted_rank(frequency_rank: int, boosted: bool) -> int:
    """Lower adjusted_rank sorts earlier; learner-needs items move up without inventing frequencies."""
    rank = max(1, int(frequency_rank))
    if boosted:
        return max(1, rank - _LEARNER_BOOST)
    return rank


def rank_lexemes(
    items: Sequence[Mapping[str, Any]],
    *,
    lang: str,
    register: Mapping[str, Mapping[str, Any]],
) -> list[RankedLexeme]:
    ranked: list[RankedLexeme] = []
    for item in items:
        item_id = item.get("id")
        if not isinstance(item_id, str) or not item_id.strip():
            raise LexiconSelectError("ITEM_ID_MISSING", "lexeme id required")
        lemma = _lemma_from_item(item)
        raw_rank = item.get("frequency_rank")
        if not isinstance(raw_rank, int) or raw_rank < 1:
            raise LexiconSelectError("FREQUENCY_RANK_INVALID", f"invalid frequency_rank on {item_id}")
        freq_source = _frequency_source_id(item)
        licence_id = assert_registered_source(freq_source, register)
        anchor = _lexicon_anchor(item, lemma, lang)
        linguist = lang in TONAL_LANGS and anchor is None
        beta = not linguist
        boosted = learner_needs_boost(item)
        ranked.append(
            RankedLexeme(
                id=item_id.strip(),
                lemma=lemma,
                frequency_rank=raw_rank,
                adjusted_rank=adjusted_rank(raw_rank, boosted),
                frequency_source_id=freq_source,
                licence_id=licence_id,
                lexicon_anchor=anchor,
                linguist_review=linguist,
                beta_eligible=beta,
                learner_boosted=boosted,
            )
        )
    ranked.sort(key=lambda row: (row.adjusted_rank, row.frequency_rank, row.id))
    return ranked


def assert_count_gate(count: int, lang: str) -> None:
    if count < MIN_LEXEMES or count > MAX_LEXEMES:
        raise LexiconCountGateError(
            "LEXICON_COUNT_OUT_OF_RANGE",
            f"{lang}: {count} lexemes (required {MIN_LEXEMES}–{MAX_LEXEMES})",
        )


def select_a1_lexemes(
    pack: Mapping[str, Any],
    *,
    lang: str,
    register: Mapping[str, Mapping[str, Any]],
    target: int = DEFAULT_TARGET,
) -> list[RankedLexeme]:
    if pack.get("lang") != lang:
        raise LexiconSelectError("PACK_LANG_MISMATCH", f"pack lang does not match {lang}")
    raw_items = pack.get("items")
    if not isinstance(raw_items, list):
        raise LexiconSelectError("PACK_ITEMS_MISSING", "pack items array required")
    lexemes = [row for row in raw_items if isinstance(row, Mapping) and row.get("type") == "lexeme"]
    ranked = rank_lexemes(lexemes, lang=lang, register=register)
    if not ranked:
        raise LexiconSelectError("NO_LEXEMES", f"no lexemes in pack for {lang}")
    clamped_target = max(MIN_LEXEMES, min(MAX_LEXEMES, target, len(ranked)))
    selected = ranked[:clamped_target]
    assert_count_gate(len(selected), lang)
    return selected


def load_a1_pack(lang: str, root: Path | None = None) -> dict[str, Any]:
    path = canonical_packs_dir(root) / lang / "A1.json"
    if not path.is_file():
        raise FileNotFoundError(f"A1 pack not found: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def build_language_manifest(
    lang: str,
    root: Path | None = None,
    *,
    target: int = DEFAULT_TARGET,
) -> dict[str, Any]:
    base = repo_root(root)
    register = load_curriculum_register(base)
    pack = load_a1_pack(lang, base)
    selected = select_a1_lexemes(pack, lang=lang, register=register, target=target)
    return {
        "card": CARD_ID,
        "lang": lang,
        "level": "A1",
        "built": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "count": len(selected),
        "target": target,
        "lexemes": [row.to_dict() for row in selected],
    }


def write_a1_manifests(
    root: Path | None = None,
    *,
    langs: Sequence[str] = STAGE1_LANGS,
    target: int = DEFAULT_TARGET,
) -> list[Path]:
    base = repo_root(root)
    out_dir = base / OUTPUT_REL
    out_dir.mkdir(parents=True, exist_ok=True)
    written: list[Path] = []
    for lang in langs:
        doc = build_language_manifest(lang, base, target=target)
        path = out_dir / f"{lang}.json"
        path.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        written.append(path)
    return written


def _main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Build A1 frequency-ranked lexicon manifests (P5-016).")
    parser.add_argument(
        "--lang",
        action="append",
        dest="langs",
        help=f"Stage-1 language code (default: all {', '.join(STAGE1_LANGS)})",
    )
    parser.add_argument(
        "--target",
        type=int,
        default=DEFAULT_TARGET,
        help=f"Lexeme target per language ({MIN_LEXEMES}–{MAX_LEXEMES}, default {DEFAULT_TARGET})",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)
    langs = tuple(args.langs) if args.langs else STAGE1_LANGS
    if args.target < MIN_LEXEMES or args.target > MAX_LEXEMES:
        print(
            f"target must be between {MIN_LEXEMES} and {MAX_LEXEMES}",
            file=sys.stderr,
        )
        return 2
    paths = write_a1_manifests(langs=langs, target=args.target)
    for path in paths:
        print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
