"""P5-060 Yoruba listen-check batch gate."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.yo_listen_check import (  # noqa: E402
    CARD_ID,
    ListenCheckError,
    REQUIRED_SAMPLES,
    assert_batch_approved,
    batch_approved,
    load_batch_json,
    parse_batch,
    summary_payload,
)


def _sample(index: int, passed: bool | None) -> dict:
    return {
        "sample_id": f"s{index}",
        "source_text": "\u00e0\u00e1r\u1ecd\u0300",
        "audio_ref": f"audio/yo/{index}.wav",
        "linguist_pass": passed,
    }


def test_required_sample_count() -> None:
    assert REQUIRED_SAMPLES == 100
    assert CARD_ID == "P5-060"


def test_batch_not_approved_until_100_passes() -> None:
    rows = parse_batch([_sample(i, True) for i in range(99)])
    assert not batch_approved(rows)
    rows = parse_batch([_sample(i, True) for i in range(100)])
    assert batch_approved(rows)


def test_assert_batch_approved_raises_on_failure() -> None:
    rows = parse_batch([_sample(i, i != 50) for i in range(100)])
    with pytest.raises(ListenCheckError) as exc:
        assert_batch_approved(rows)
    assert exc.value.code == "LISTEN_CHECK_FAILED"


def test_load_batch_json() -> None:
    payload = json.dumps([_sample(0, True)])
    samples = load_batch_json(payload)
    assert len(samples) == 1
    summary = summary_payload(samples)
    assert summary["card_id"] == "P5-060"
    assert summary["approved"] is False
