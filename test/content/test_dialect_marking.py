"""Regional dialect / variant marking on v2 content (P4-116)."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any, Mapping

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.dialect_policy_decision import load_dialect_policy_decision  # noqa: E402

_TAG_RE = re.compile(r"^(standard|[a-z0-9_-]{2,64})$")


class DialectMarkingError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _policy_tags_for_language(language_id: str) -> frozenset[str]:
    data = load_dialect_policy_decision()
    for row in data.get("stage_1", []):
        if row.get("language_id") == language_id:
            return frozenset(
                v["dialect_tag"]
                for v in row.get("regional_variants", [])
                if isinstance(v, Mapping) and v.get("dialect_tag")
            )
    return frozenset()


def _require_marked_regional(
    obj: Mapping[str, Any],
    *,
    kind_field: str,
    path: str,
) -> None:
    kind = obj.get(kind_field, "standard")
    if kind != "regional":
        tag = obj.get("dialect_tag")
        if isinstance(tag, str) and tag.strip() and tag.strip().lower() != "standard":
            raise DialectMarkingError(
                "VARIANT_UNMARKED",
                f"{path} sets dialect_tag but take_kind/form_kind is not regional",
            )
        return

    dialect = obj.get("dialect_tag")
    region = obj.get("region")
    if not isinstance(dialect, str) or not dialect.strip():
        raise DialectMarkingError("VARIANT_UNMARKED", f"{path} regional variant missing dialect_tag")
    if not _TAG_RE.match(dialect.strip()):
        raise DialectMarkingError("VARIANT_UNMARKED", f"{path} dialect_tag invalid")
    if not isinstance(region, str) or not region.strip():
        raise DialectMarkingError("VARIANT_UNMARKED", f"{path} regional variant missing region")


def validate_lexeme_dialect_marking(obj: Mapping[str, Any], *, language_id: str) -> None:
    _require_marked_regional(obj, kind_field="form_kind", path="lexeme")
    known = _policy_tags_for_language(language_id)
    for index, audio in enumerate(obj.get("audio") or []):
        if not isinstance(audio, Mapping):
            continue
        _require_marked_regional(audio, kind_field="take_kind", path=f"audio[{index}]")
        tag = audio.get("dialect_tag")
        if (
            isinstance(tag, str)
            and tag.strip().lower() != "standard"
            and known
            and tag.strip() in known
            and audio.get("take_kind") != "regional"
        ):
            raise DialectMarkingError(
                "VARIANT_UNMARKED",
                f"audio[{index}] uses policy dialect_tag without take_kind regional",
            )


def test_regional_lexeme_requires_dialect_and_region() -> None:
    base = {
        "form_kind": "regional",
        "dialect_tag": "yo-lagos",
        "audio": [],
    }
    with pytest.raises(DialectMarkingError) as exc:
        validate_lexeme_dialect_marking(base, language_id="yo")
    assert exc.value.code == "VARIANT_UNMARKED"

    base["region"] = "Lagos State"
    validate_lexeme_dialect_marking(base, language_id="yo")


def test_regional_audio_take_requires_fields() -> None:
    lexeme = {
        "form_kind": "standard",
        "audio": [
            {
                "take_kind": "regional",
                "dialect_tag": "yo-lagos",
                "kind": "human",
            }
        ],
    }
    with pytest.raises(DialectMarkingError) as exc:
        validate_lexeme_dialect_marking(lexeme, language_id="yo")
    assert exc.value.code == "VARIANT_UNMARKED"

    lexeme["audio"][0]["region"] = "Lagos State"
    validate_lexeme_dialect_marking(lexeme, language_id="yo")


def test_dialect_tag_without_regional_kind_fails() -> None:
    lexeme = {
        "form_kind": "standard",
        "dialect_tag": "yo-ibadan",
        "audio": [],
    }
    with pytest.raises(DialectMarkingError) as exc:
        validate_lexeme_dialect_marking(lexeme, language_id="yo")
    assert exc.value.code == "VARIANT_UNMARKED"


def test_policy_fixture_json_loads() -> None:
    path = _REPO_ROOT / "assets/content/dialect_policy_decision.json"
    data = json.loads(path.read_text(encoding="utf-8"))
    assert data["card_id"] == "P4-115"
