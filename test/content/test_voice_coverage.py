"""P4-133 voice-count gates and QA listen-through."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.listen_qa import (  # noqa: E402
    ListenQAError,
    append_listen_log,
    assert_item_audio_shippable,
    log_listen_through,
    recording_id_for_audio,
    route_ugc_voice_contribution,
)
from tools.content_pipeline.voice_coverage import (  # noqa: E402
    VoiceCoverageError,
    check_voice_coverage,
    distinct_recorded_voice_ids,
    enforce_voice_coverage,
    sync_inventory_recorded_voice_ids,
)


def _human_take(voice_id: str, blob: str = "abc123") -> dict:
    return {
        "kind": "human",
        "voice_id": voice_id,
        "uri": f"audio/yo/x.wav",
        "blob_content_hash": blob,
        "speed": "natural",
    }


def _registry_l2() -> dict[str, dict]:
    return {
        "v1": {"gender": "f", "age_band": "adult", "region_tag": "yo-lagos"},
        "v2": {"gender": "m", "age_band": "adult", "region_tag": "yo-ibadan"},
        "v3": {"gender": "f", "age_band": "young_adult", "region_tag": "yo-lagos"},
        "v4": {"gender": "m", "age_band": "young_adult", "region_tag": "yo-abeokuta"},
    }


def test_distinct_voices_from_items() -> None:
    items = [
        {"id": "a", "audio": [_human_take("v1"), _human_take("v2", "b2")]},
        {"id": "b", "audio": [_human_take("v1", "b3")]},
    ]
    assert distinct_recorded_voice_ids(items) == {"v1", "v2"}


def test_l0_gate_requires_two_voices() -> None:
    items = [{"id": "a", "audio": [_human_take("only-one")]}]
    result = check_voice_coverage(target_level="L0", items=items, voice_registry={})
    assert result.passed is False
    assert result.code == "VOICE_COUNT_LOW"


def test_l1_passes_with_two_voices() -> None:
    items = [{"id": "a", "audio": [_human_take("v1"), _human_take("v2", "x")]}]
    result = check_voice_coverage(target_level="L1", items=items, voice_registry={})
    assert result.passed is True
    assert result.distinct_voice_count == 2


def test_l2_requires_four_voices_with_spread() -> None:
    items = [
        {
            "id": "a",
            "audio": [
                _human_take("v1", "1"),
                _human_take("v2", "2"),
                _human_take("v3", "3"),
                _human_take("v4", "4"),
            ],
        }
    ]
    result = check_voice_coverage(target_level="L2", items=items, voice_registry=_registry_l2())
    assert result.passed is True

    thin = check_voice_coverage(
        target_level="L2",
        items=[{"id": "a", "audio": [_human_take("v1"), _human_take("v2", "2")]}],
        voice_registry=_registry_l2(),
    )
    assert thin.passed is False
    assert thin.code == "VOICE_COUNT_LOW"


def test_enforce_raises_voice_count_low() -> None:
    with pytest.raises(VoiceCoverageError) as exc:
        enforce_voice_coverage(target_level="L0", items=[], voice_registry={})
    assert exc.value.code == "VOICE_COUNT_LOW"


def test_sync_inventory_voice_ids() -> None:
    manifest: dict = {}
    items = [{"id": "a", "audio": [_human_take("v1"), _human_take("v2", "b")]}]
    ids = sync_inventory_recorded_voice_ids(manifest, items)
    assert ids == ["v1", "v2"]
    assert manifest["inventory"]["recorded_voice_ids"] == ["v1", "v2"]


def test_listen_log_and_ship_gate() -> None:
    entry = _human_take("v1")
    assert recording_id_for_audio(entry) == "abc123"
    row = log_listen_through(recording_id="abc123", reviewer_id="qa-1", result="pass")
    append_listen_log(entry, row)
    assert_item_audio_shippable({"audio": [entry]})


def test_unlogged_human_audio_blocks_ship() -> None:
    entry = _human_take("v1")
    with pytest.raises(ListenQAError) as exc:
        assert_item_audio_shippable({"audio": [entry]})
    assert exc.value.code == "LISTEN_QA_MISSING"


def test_ugc_voice_never_auto_publishes() -> None:
    out = route_ugc_voice_contribution(
        {
            "source": "ugc_voice",
            "voice_id": "ugc-v-1",
            "consent_signed": True,
            "licence_terms_signed": True,
        }
    )
    assert out["auto_publish"] is False
    assert out["status"] == "review_required"

    with pytest.raises(ListenQAError) as exc:
        route_ugc_voice_contribution(
            {"source": "ugc_voice", "voice_id": "x", "consent_signed": False, "licence_terms_signed": True}
        )
    assert exc.value.code == "CONSENT_MISSING"
