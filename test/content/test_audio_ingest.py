"""P4-123 native recording ingest, forced alignment, and audio manifest."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.audio_ingest import (  # noqa: E402
    AudioIngestError,
    attach_audio_to_item,
    ingest_native_recording,
)
from tools.content_pipeline.audio_manifest import (  # noqa: E402
    AudioManifestError,
    coverage_gaps_for_item,
    register_tts_synthetic_interim,
    validate_human_take_coverage,
)
from tools.content_pipeline.forced_align import (  # noqa: E402
    AlignmentPayload,
    PhoneSpan,
    WordSpan,
    align_item_takes,
    align_recording,
)


def _fake_aligner(_audio: bytes, text: str, _lang: str) -> AlignmentPayload:
    return AlignmentPayload(
        words=(WordSpan(text=text.split()[0] if text else "x", start_ms=0, end_ms=120),),
        phones=(PhoneSpan(phone="a", start_ms=0, end_ms=60), PhoneSpan(phone="b", start_ms=60, end_ms=120)),
    )


def _failing_aligner(_audio: bytes, _text: str, _lang: str) -> AlignmentPayload:
    raise RuntimeError("model unavailable")


def test_ingest_stores_under_content_hash_and_metadata(tmp_path: Path) -> None:
    data = b"RIFFfake-wav-bytes"
    result = ingest_native_recording(
        data=data,
        language="yo",
        spoken_text="Ẹ káàbọ̀",
        voice_id="voice-yo-1",
        speed="natural",
        consent_id="consent-abc",
        storage_root=tmp_path,
    )
    assert result.blob_path.is_file()
    assert result.content_hash == result.audio_ref["blob_content_hash"]
    assert result.audio_ref["kind"] == "human"
    assert result.audio_ref["voice_id"] == "voice-yo-1"
    assert result.audio_ref["speed"] == "natural"
    assert result.audio_ref["consent_id"] == "consent-abc"
    assert result.audio_ref["uri"].startswith("audio/yo/")


def test_ingest_requires_consent(tmp_path: Path) -> None:
    with pytest.raises(AudioIngestError) as exc:
        ingest_native_recording(
            data=b"x",
            language="yo",
            spoken_text="a",
            voice_id="v1",
            speed="slow",
            consent_id="",
            storage_root=tmp_path,
        )
    assert exc.value.code == "CONSENT_MISSING"


def test_align_success_populates_boundaries() -> None:
    ref: dict = {"kind": "human", "aligned_words": [], "aligned_phones": []}
    align_recording(
        audio_bytes=b"wav",
        spoken_text="báwo ni",
        language="yo",
        audio_ref=ref,
        aligner=_fake_aligner,
    )
    assert ref["alignment_status"] == "ok"
    assert ref["aligned_words"][0]["start_ms"] == 0
    assert len(ref["aligned_phones"]) == 2


def test_align_failure_marks_align_failed_without_guessed_timings() -> None:
    ref: dict = {"kind": "human"}
    align_recording(
        audio_bytes=b"wav",
        spoken_text="báwo ni",
        language="yo",
        audio_ref=ref,
        aligner=_failing_aligner,
    )
    assert ref["alignment_status"] == "ALIGN_FAILED"
    assert ref["aligned_words"] == []
    assert ref["aligned_phones"] == []


def test_align_item_takes_on_ingested_item(tmp_path: Path) -> None:
    ingested = ingest_native_recording(
        data=b"take-bytes",
        language="yo",
        spoken_text="Ẹ káàbọ̀",
        voice_id="voice-yo-1",
        speed="natural",
        consent_id="consent-1",
        storage_root=tmp_path,
    )
    item: dict = {"id": "yo.item.1", "audio": []}
    attach_audio_to_item(item, ingested.audio_ref)

    def loader(entry: dict) -> bytes:
        return ingested.blob_path.read_bytes()

    align_item_takes(
        item,
        blob_loader=loader,
        aligner=_fake_aligner,
        language="yo",
        spoken_text="Ẹ káàbọ̀",
    )
    assert item["audio"][0]["alignment_status"] == "ok"


def test_tts_synthetic_interim_flagged_for_replacement() -> None:
    item: dict = {"id": "yo.item.2", "audio": []}
    entry = register_tts_synthetic_interim(
        item,
        uri="audio/yo/deadbeefdeadbeef.mp3",
        synthetic_voice_tag="interim-v1",
        exposure_rank=3,
    )
    assert entry["kind"] == "tts_synthetic"
    assert entry["interim_d1"] is True
    assert entry["native_replacement_rank"] == 3


def test_coverage_gap_names_missing_takes() -> None:
    item = {
        "id": "yo.item.3",
        "audio": [
            {"kind": "human", "speed": "natural", "voice_id": "v1"},
        ],
    }
    gaps = coverage_gaps_for_item(item)
    assert any(g.endswith(":slow") for g in gaps)
    with pytest.raises(AudioManifestError) as exc:
        validate_human_take_coverage(item)
    assert exc.value.code.startswith("COVERAGE_GAP")
