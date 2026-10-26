"""Lexeme schema with tone, audio and review fields (P4-101)."""

from __future__ import annotations

import json
import re
import sys
import unicodedata
from pathlib import Path
from typing import Any, Mapping

import pytest
from jsonschema import Draft202012Validator

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.schema_loader import (  # noqa: E402
    SYNTHETIC_VOICE_TAG,
    CommonSchemaError,
    validate_content_envelope,
)

_SCHEMA_PATH = _REPO_ROOT / "schemas" / "v2" / "content" / "lexeme.schema.json"
_FIXTURE_PATH = Path(__file__).resolve().parent / "fixtures" / "lexeme_yo_oko.json"

_LEXEME_ID_RE = re.compile(r"^(?P<lang>[a-z]{2,3})\.lex\.(?P<slug>.+)\.(?P<sense>[^.]+)$")
_TONAL_LANGS = frozenset({"yo", "ig", "ha"})
_AUDIO_URI_RE = re.compile(r"^audio/[a-z]{2,3}/[0-9a-f]{8,64}\.[a-z0-9]+$")
_SPEEDS = frozenset({"natural", "slow"})
_CULTURAL_REVIEW = frozenset({"approved", "pending", "rejected"})
_REGISTERS = frozenset({"neutral", "formal", "informal", "slang", "literary", "religious"})


class LexemeSchemaError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_lexeme_schema() -> dict[str, Any]:
    return json.loads(_SCHEMA_PATH.read_text(encoding="utf-8"))


def _lexeme_validator() -> Draft202012Validator:
    from referencing import Registry, Resource

    common = json.loads(
        (_REPO_ROOT / "schemas" / "v2" / "content" / "common.schema.json").read_text(encoding="utf-8")
    )
    lexeme = load_lexeme_schema()
    registry = Registry().with_resources(
        [
            (lexeme["$id"], Resource.from_contents(lexeme)),
            (common["$id"], Resource.from_contents(common)),
            ("common.schema.json", Resource.from_contents(common)),
        ]
    )
    return Draft202012Validator(lexeme, registry=registry)


def _lang_from_id(lexeme_id: str) -> str:
    match = _LEXEME_ID_RE.match(lexeme_id)
    if not match:
        raise LexemeSchemaError("LEXEME_ID_INVALID", "id must match <lang>.lex.<slug>.<sense>")
    return match.group("lang")


def _check_id(lexeme_id: object) -> str:
    if not isinstance(lexeme_id, str) or not lexeme_id.strip():
        raise LexemeSchemaError("LEXEME_ID_INVALID", "id is required")
    match = _LEXEME_ID_RE.match(lexeme_id.strip())
    if not match:
        raise LexemeSchemaError("LEXEME_ID_INVALID", "id must match <lang>.lex.<slug>.<sense>")
    return lexeme_id.strip()


def _check_lemma(lemma: object) -> None:
    if not isinstance(lemma, str) or not lemma:
        raise LexemeSchemaError("LEMMA_NOT_NFC", "lemma is required")
    if lemma != unicodedata.normalize("NFC", lemma):
        raise LexemeSchemaError("LEMMA_NOT_NFC", "lemma must be NFC-normalised")


def _check_orthography(orthography: object) -> None:
    if not isinstance(orthography, Mapping):
        raise LexemeSchemaError("ORTHOGRAPHY_INVALID", "orthography must be a mapping")
    for field in ("standard", "ascii_fallback", "script"):
        val = orthography.get(field)
        if not isinstance(val, str) or not val.strip():
            raise LexemeSchemaError("ORTHOGRAPHY_INVALID", f"orthography.{field} is required")
    script = orthography.get("script")
    if script not in ("Latn", "Arab", "Ethi"):
        raise LexemeSchemaError("ORTHOGRAPHY_INVALID", "orthography.script is invalid")


def _check_tonal_fields(obj: Mapping[str, Any], lang: str) -> None:
    if lang not in _TONAL_LANGS:
        return
    ipa = obj.get("ipa")
    if not isinstance(ipa, str) or not ipa.strip():
        raise LexemeSchemaError("IPA_MISSING", "ipa is required for tonal languages")
    tone = obj.get("tone_pattern")
    if not isinstance(tone, list) or len(tone) < 1:
        raise LexemeSchemaError("TONE_PATTERN_MISSING", "tone_pattern is required for tonal languages")
    syllables = obj.get("syllables")
    if not isinstance(syllables, list) or len(syllables) < 1:
        raise LexemeSchemaError("SYLLABLES_MISSING", "syllables is required for tonal languages")


def _check_senses(senses: object) -> None:
    if not isinstance(senses, list) or len(senses) < 1:
        raise LexemeSchemaError("SENSE_INVALID", "senses must be a non-empty list")
    for index, sense in enumerate(senses):
        if not isinstance(sense, Mapping):
            raise LexemeSchemaError("SENSE_INVALID", f"senses[{index}] must be a mapping")
        for field in ("gloss_en", "gloss_fr", "domain"):
            val = sense.get(field)
            if not isinstance(val, str) or not val.strip():
                raise LexemeSchemaError("SENSE_INVALID", f"senses[{index}].{field} is required")
        register = sense.get("register")
        if register not in _REGISTERS:
            raise LexemeSchemaError("SENSE_INVALID", f"senses[{index}].register is invalid")


def _check_minimal_pairs(pairs: object, known_ids: frozenset[str]) -> None:
    if pairs is None:
        return
    if not isinstance(pairs, list):
        raise LexemeSchemaError("MINIMAL_PAIR_DANGLING", "minimal_pairs must be a list")
    for pair_id in pairs:
        if not isinstance(pair_id, str) or pair_id not in known_ids:
            raise LexemeSchemaError("MINIMAL_PAIR_DANGLING", f"minimal pair {pair_id!r} is not in the lexeme registry")


def _check_lexeme_audio(audio: object) -> None:
    if not isinstance(audio, list):
        raise LexemeSchemaError("LEXEME_AUDIO_INVALID", "audio must be a list")
    for index, entry in enumerate(audio):
        if not isinstance(entry, Mapping):
            raise LexemeSchemaError("LEXEME_AUDIO_INVALID", f"audio[{index}] must be a mapping")
        kind = entry.get("kind")
        if kind not in ("human", "tts_synthetic"):
            raise LexemeSchemaError("LEXEME_AUDIO_INVALID", f"audio[{index}].kind is invalid")
        if kind == "tts_synthetic" and entry.get("synthetic_voice_tag") != SYNTHETIC_VOICE_TAG:
            raise LexemeSchemaError("LEXEME_AUDIO_INVALID", f"audio[{index}] tts_synthetic requires synthetic_voice_tag")
        voice_id = entry.get("voice_id")
        if not isinstance(voice_id, str) or not voice_id.strip():
            raise LexemeSchemaError("LEXEME_AUDIO_INVALID", f"audio[{index}].voice_id is required")
        speed = entry.get("speed")
        if speed not in _SPEEDS:
            raise LexemeSchemaError("LEXEME_AUDIO_INVALID", f"audio[{index}].speed must be natural or slow")
        uri = entry.get("uri")
        if not isinstance(uri, str) or not _AUDIO_URI_RE.match(uri):
            raise LexemeSchemaError("LEXEME_AUDIO_INVALID", f"audio[{index}].uri must be a content-hash path")
        phones = entry.get("aligned_phones")
        if not isinstance(phones, list):
            raise LexemeSchemaError("LEXEME_AUDIO_INVALID", f"audio[{index}].aligned_phones must be a list")


def _check_image(image: object, label: str) -> None:
    if image is None:
        return
    if not isinstance(image, Mapping):
        raise LexemeSchemaError("IMAGE_INVALID", "image must be a mapping")
    for field in ("uri", "alt_text"):
        val = image.get(field)
        if not isinstance(val, str) or not val.strip():
            raise LexemeSchemaError("IMAGE_INVALID", f"image.{field} is required")
    review = image.get("cultural_review")
    if review not in _CULTURAL_REVIEW:
        raise LexemeSchemaError("IMAGE_INVALID", "image.cultural_review must be approved, pending, or rejected")
    if label == "native_verified" and review == "pending":
        raise LexemeSchemaError(
            "CULTURAL_REVIEW_BLOCKS_NATIVE_VERIFIED",
            "image.cultural_review pending blocks native_verified label",
        )


def validate_lexeme(
    obj: Mapping[str, Any],
    *,
    known_lexeme_ids: frozenset[str] | None = None,
    validator: Draft202012Validator | None = None,
) -> None:
    if not isinstance(obj, Mapping):
        raise LexemeSchemaError("LEXEME_ID_INVALID", "lexeme must be a mapping")

    lexeme_id = _check_id(obj.get("id"))
    lang = _lang_from_id(lexeme_id)
    _check_lemma(obj.get("lemma"))
    _check_orthography(obj.get("orthography"))
    _check_tonal_fields(obj, lang)
    _check_senses(obj.get("senses"))

    registry = (known_lexeme_ids or frozenset()) | frozenset({lexeme_id})
    _check_minimal_pairs(obj.get("minimal_pairs"), registry)

    try:
        validate_content_envelope(obj)
    except CommonSchemaError as exc:
        raise LexemeSchemaError(exc.code, str(exc)) from exc

    label = obj.get("label")
    if not isinstance(label, str):
        raise LexemeSchemaError("LABEL_MISSING", "label is required")
    _check_lexeme_audio(obj.get("audio"))
    _check_image(obj.get("image"), label)

    v = validator or _lexeme_validator()
    errors = sorted(v.iter_errors(obj), key=lambda e: list(e.path))
    if errors:
        raise LexemeSchemaError("LEXEME_ID_INVALID", errors[0].message)


def assert_lexeme_ids_unique_per_language(lexemes: list[Mapping[str, Any]]) -> None:
    seen: dict[str, set[str]] = {}
    for row in lexemes:
        lex_id = _check_id(row.get("id"))
        lang = _lang_from_id(lex_id)
        bucket = seen.setdefault(lang, set())
        if lex_id in bucket:
            raise LexemeSchemaError("LEXEME_ID_INVALID", f"duplicate id {lex_id} within {lang}")
        bucket.add(lex_id)


def test_schema_document_is_valid() -> None:
    Draft202012Validator.check_schema(load_lexeme_schema())


def test_yo_oko_fixture_passes() -> None:
    raw = json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))
    known = frozenset(
        {
            raw["id"],
            "yo.lex.ọkọ.husband",
            "yo.lex.ọkọ.hoe",
        }
    )
    validate_lexeme(raw, known_lexeme_ids=known)
    assert raw["cefr"] == "A1"
    assert raw["frequency_rank"] == 812


def test_lexeme_id_invalid() -> None:
    raw = json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))
    raw["id"] = "bad-id"
    with pytest.raises(LexemeSchemaError) as exc:
        validate_lexeme(raw, known_lexeme_ids=frozenset())
    assert exc.value.code == "LEXEME_ID_INVALID"


def test_lemma_not_nfc() -> None:
    raw = json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))
    raw["lemma"] = "o\u0300ko\u0300"
    with pytest.raises(LexemeSchemaError) as exc:
        validate_lexeme(raw, known_lexeme_ids=frozenset({raw["id"]}))
    assert exc.value.code == "LEMMA_NOT_NFC"


def test_minimal_pair_dangling() -> None:
    raw = json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))
    with pytest.raises(LexemeSchemaError) as exc:
        validate_lexeme(raw, known_lexeme_ids=frozenset({raw["id"]}))
    assert exc.value.code == "MINIMAL_PAIR_DANGLING"


def test_cultural_review_pending_blocks_native_verified() -> None:
    raw = json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))
    raw["label"] = "native_verified"
    raw["image"]["cultural_review"] = "pending"
    raw["review"]["reviewers"] = [
        {"role": "native", "reviewer_id": "n1", "approved": True},
        {"role": "native", "reviewer_id": "n2", "approved": True},
        {"role": "linguist", "reviewer_id": "l1", "approved": True},
    ]
    known = frozenset({raw["id"], *raw["minimal_pairs"]})
    with pytest.raises(LexemeSchemaError) as exc:
        validate_lexeme(raw, known_lexeme_ids=known)
    assert exc.value.code == "CULTURAL_REVIEW_BLOCKS_NATIVE_VERIFIED"


def test_duplicate_id_within_language() -> None:
    raw = json.loads(_FIXTURE_PATH.read_text(encoding="utf-8"))
    with pytest.raises(LexemeSchemaError):
        assert_lexeme_ids_unique_per_language([raw, raw])
