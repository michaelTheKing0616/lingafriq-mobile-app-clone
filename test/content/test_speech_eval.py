"""P4-124 speech enablement evaluation gates."""

from __future__ import annotations

import json
import sys
from datetime import date
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.speech_eval import (  # noqa: E402
    CARD_ID,
    DEFAULT_THRESHOLDS,
    EXPECTED_UTTERANCE_COUNT,
    EvalThresholds,
    SpeechEvalError,
    check_tts_voice_gate,
    intron_asr_available,
    load_eval_bundle,
    request_speech_enablement,
    run_asr_evaluation,
    tone_scoring_calibration_report,
    validate_asr_eval_set,
    word_error_rate,
)


def test_word_error_rate_exact_and_substitution() -> None:
    assert word_error_rate("a b c", "a b c") == 0.0
    assert word_error_rate("a b c", "a x c") == pytest.approx(1 / 3)


def test_asr_eval_records_wer_and_rejects_short_set() -> None:
    refs = ["hello world"] * EXPECTED_UTTERANCE_COUNT
    hyps = ["hello word"] * EXPECTED_UTTERANCE_COUNT
    record = run_asr_evaluation(
        language_id="yo",
        backend="omnilingual",
        set_id="yo-asr-v1",
        eval_date=date(2026, 10, 26),
        references=refs,
        hypotheses=hyps,
    )
    assert record["card_id"] == CARD_ID
    assert record["wer"] == pytest.approx(0.5)
    assert record["set_id"] == "yo-asr-v1"
    with pytest.raises(SpeechEvalError) as exc:
        validate_asr_eval_set(["one"])
    assert exc.value.code == "EVAL_SET_MISSING"


def test_intron_gated_off_by_default() -> None:
    assert intron_asr_available({}) is False
    with pytest.raises(SpeechEvalError) as exc:
        run_asr_evaluation(
            language_id="ha",
            backend="intron",
            set_id="ha-asr-v1",
            eval_date=date(2026, 10, 26),
            references=["x"] * EXPECTED_UTTERANCE_COUNT,
            hypotheses=["x"] * EXPECTED_UTTERANCE_COUNT,
        )
    assert exc.value.code == "INTRON_DISABLED"
    env = {"AI_INTRON_ENABLED": "true", "INTRON_API_KEY": "test-key"}
    assert intron_asr_available(env) is True
    record = run_asr_evaluation(
        language_id="ha",
        backend="intron",
        set_id="ha-asr-v1",
        eval_date=date(2026, 10, 26),
        references=["a"] * EXPECTED_UTTERANCE_COUNT,
        hypotheses=["a"] * EXPECTED_UTTERANCE_COUNT,
        env=env,
    )
    assert record["backend"] == "intron"


def test_tts_gate_pass_and_fail() -> None:
    ok = check_tts_voice_gate({"native_mos": 4.0, "tone_error_rate": 0.02})
    assert ok.enabled is True
    bad = check_tts_voice_gate({"native_mos": 3.0, "tone_error_rate": 0.02})
    assert bad.reason_code == "TTS_GATE_FAIL"
    missing = check_tts_voice_gate({"native_mos": 4.0})
    assert missing.reason_code == "EVAL_INCOMPLETE"


def test_tone_calibration_agreement() -> None:
    report = tone_scoring_calibration_report(
        {"j1": [4.0, 4.0, 4.0, 4.0], "j2": [4.0, 4.0, 4.0, 4.0], "j3": [4.0, 4.0, 4.0, 4.0]},
        pass_at=3.0,
    )
    assert report["calibration_passed"] is True
    assert report["agreement_rate"] == 1.0
    split = tone_scoring_calibration_report(
        {"j1": [4.0, 2.0, 4.0], "j2": [4.0, 4.0, 4.0], "j3": [4.0, 2.0, 4.0]},
        pass_at=3.0,
    )
    assert split["agreement_rate"] == pytest.approx(2 / 3)
    assert split["calibration_passed"] is False


def test_enablement_no_placeholder_and_tonal_tts() -> None:
    bundle = {
        "asr": {
            "backend": "omnilingual",
            "utterance_count": EXPECTED_UTTERANCE_COUNT,
            "wer": 0.12,
        },
        "tts": {"native_mos": 4.2, "tone_error_rate": 0.01, "tone_accuracy_gate_passed": False},
    }
    asr = request_speech_enablement(language_id="sw", feature="asr", bundle=bundle)
    assert asr.enabled is True
    yo_tts = request_speech_enablement(language_id="yo", feature="tts", bundle=bundle)
    assert yo_tts.reason_code == "TTS_GATE_FAIL"
    bundle["tts"]["tone_accuracy_gate_passed"] = True
    yo_tts_ok = request_speech_enablement(language_id="yo", feature="tts", bundle=bundle)
    assert yo_tts_ok.enabled is True
    empty = request_speech_enablement(language_id="yo", feature="asr", bundle={})
    assert empty.reason_code == "EVAL_SET_MISSING"


def test_load_eval_bundle(tmp_path: Path) -> None:
    path = tmp_path / "yo.json"
    path.write_text(json.dumps({"asr": {"wer": 0.1}}), encoding="utf-8")
    assert load_eval_bundle(path)["asr"]["wer"] == 0.1
    with pytest.raises(SpeechEvalError):
        load_eval_bundle(tmp_path / "missing.json")


def test_asr_wer_limit_from_config() -> None:
    tight = EvalThresholds(
        min_native_mos=3.5,
        max_tone_error_rate=0.08,
        min_judge_agreement=0.75,
        max_asr_wer=0.1,
    )
    bundle = {
        "asr": {
            "backend": "omnilingual",
            "utterance_count": EXPECTED_UTTERANCE_COUNT,
            "wer": 0.15,
        }
    }
    decision = request_speech_enablement(
        language_id="pcm", feature="asr", bundle=bundle, thresholds=tight
    )
    assert decision.reason_code == "ASR_GATE_FAIL"
    bundle["asr"]["wer"] = 0.05
    assert request_speech_enablement(
        language_id="pcm", feature="asr", bundle=bundle, thresholds=tight
    ).enabled
