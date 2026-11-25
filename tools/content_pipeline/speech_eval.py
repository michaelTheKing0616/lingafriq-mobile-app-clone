"""Speech enablement evaluation gates (P4-124, ELEVATION §6.4.1)."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import date
from pathlib import Path
from typing import Any, Mapping, MutableMapping, Sequence

CARD_ID = "P4-124"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_EVAL_README = _REPO_ROOT / "assets/content/eval/README.md"

EXPECTED_UTTERANCE_COUNT = 300
TONAL_TTS_LANGS = frozenset({"yo", "ig", "ha"})
ASR_BACKENDS = frozenset({"intron", "omnilingual"})


class SpeechEvalError(Exception):
    """Speech eval validation failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class EvalThresholds:
    """Thresholds for enablement; P6 scorer cards may tighten these in eval config files."""

    min_native_mos: float
    max_tone_error_rate: float
    min_judge_agreement: float
    max_asr_wer: float | None = None


DEFAULT_THRESHOLDS = EvalThresholds(
    min_native_mos=3.5,
    max_tone_error_rate=0.08,
    min_judge_agreement=0.75,
    max_asr_wer=None,
)


@dataclass(frozen=True)
class EnablementDecision:
    enabled: bool
    reason_code: str | None
    detail: str


def intron_asr_available(env: Mapping[str, str] | None = None) -> bool:
    """Intron stays off until server flag and key are set (never client-side keys)."""
    source = env if env is not None else os.environ
    flag = source.get("AI_INTRON_ENABLED", "").strip().lower()
    key = source.get("INTRON_API_KEY", "").strip()
    return flag in {"1", "true", "yes", "on"} and bool(key)


def word_error_rate(reference: str, hypothesis: str) -> float:
    """Word error rate via Levenshtein on token sequences."""
    ref = reference.split()
    hyp = hypothesis.split()
    if not ref:
        return 0.0 if not hyp else 1.0
    rows = len(ref) + 1
    cols = len(hyp) + 1
    dist = [[0] * cols for _ in range(rows)]
    for i in range(rows):
        dist[i][0] = i
    for j in range(cols):
        dist[0][j] = j
    for i in range(1, rows):
        for j in range(1, cols):
            cost = 0 if ref[i - 1] == hyp[j - 1] else 1
            dist[i][j] = min(
                dist[i - 1][j] + 1,
                dist[i][j - 1] + 1,
                dist[i - 1][j - 1] + cost,
            )
    return dist[rows - 1][cols - 1] / len(ref)


def _require_sequence(value: object, code: str, label: str) -> Sequence[Any]:
    if not isinstance(value, Sequence) or isinstance(value, (str, bytes)):
        raise SpeechEvalError(code, f"{label} must be a sequence")
    return value


def validate_asr_eval_set(utterances: Sequence[Any]) -> None:
    if len(utterances) != EXPECTED_UTTERANCE_COUNT:
        raise SpeechEvalError(
            "EVAL_SET_MISSING",
            f"ASR eval set must contain exactly {EXPECTED_UTTERANCE_COUNT} utterances, got {len(utterances)}",
        )


def run_asr_evaluation(
    *,
    language_id: str,
    backend: str,
    set_id: str,
    eval_date: date,
    references: Sequence[str],
    hypotheses: Sequence[str],
    env: Mapping[str, str] | None = None,
) -> dict[str, Any]:
    """Score a 300-utterance ASR eval and persist a result record (AC1)."""
    if not language_id.strip():
        raise SpeechEvalError("LANGUAGE_INVALID", "language_id must be non-empty")
    if backend not in ASR_BACKENDS:
        raise SpeechEvalError("ASR_BACKEND_INVALID", f"backend must be one of {sorted(ASR_BACKENDS)}")
    if backend == "intron" and not intron_asr_available(env):
        raise SpeechEvalError("INTRON_DISABLED", "Intron ASR eval requires AI_INTRON_ENABLED and INTRON_API_KEY")
    validate_asr_eval_set(references)
    if len(hypotheses) != len(references):
        raise SpeechEvalError("HYPOTHESIS_COUNT", "hypotheses length must match references")

    errors = [word_error_rate(r, h) for r, h in zip(references, hypotheses, strict=True)]
    wer = sum(errors) / len(errors)
    return {
        "card_id": CARD_ID,
        "kind": "asr",
        "language_id": language_id,
        "backend": backend,
        "set_id": set_id,
        "eval_date": eval_date.isoformat(),
        "utterance_count": EXPECTED_UTTERANCE_COUNT,
        "wer": wer,
    }


def _finite_rate(value: Any, code: str, label: str) -> float:
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise SpeechEvalError(code, f"{label} must be a number")
    number = float(value)
    if number != number or number in (float("inf"), float("-inf")):
        raise SpeechEvalError(code, f"{label} must be finite")
    return number


def check_tts_voice_gate(
    voice_eval: Mapping[str, Any],
    thresholds: EvalThresholds | None = None,
) -> EnablementDecision:
    """Gate vendor/custom TTS on native MOS and tone-error rate (AC2)."""
    limits = thresholds or DEFAULT_THRESHOLDS
    mos = voice_eval.get("native_mos")
    tone_err = voice_eval.get("tone_error_rate")
    if mos is None or tone_err is None:
        return EnablementDecision(
            enabled=False,
            reason_code="EVAL_INCOMPLETE",
            detail="native_mos and tone_error_rate are required; no placeholder score",
        )
    mos_f = _finite_rate(mos, "MOS_INVALID", "native_mos")
    tone_f = _finite_rate(tone_err, "TONE_RATE_INVALID", "tone_error_rate")
    if mos_f < limits.min_native_mos or tone_f > limits.max_tone_error_rate:
        return EnablementDecision(
            enabled=False,
            reason_code="TTS_GATE_FAIL",
            detail=(
                f"MOS {mos_f:.3f} or tone error {tone_f:.3f} outside "
                f"limits (>={limits.min_native_mos} MOS, <={limits.max_tone_error_rate} tone error)"
            ),
        )
    return EnablementDecision(enabled=True, reason_code=None, detail="voice passed MOS and tone-error gates")


def _judge_pass(rating: float, pass_at: float) -> bool:
    return rating >= pass_at


def tone_scoring_calibration_report(
    judge_ratings: Mapping[str, Sequence[float]],
    *,
    pass_at: float = 3.0,
    thresholds: EvalThresholds | None = None,
) -> dict[str, Any]:
    """Store per-judge ratings and report agreement before tone scoring enablement (AC3)."""
    limits = thresholds or DEFAULT_THRESHOLDS
    if not judge_ratings:
        raise SpeechEvalError("JUDGES_MISSING", "at least one judge rating set is required")
    judges: dict[str, list[float]] = {}
    for judge_id, ratings in judge_ratings.items():
        if not isinstance(judge_id, str) or not judge_id.strip():
            raise SpeechEvalError("JUDGE_ID_INVALID", "judge ids must be non-empty strings")
        seq = _require_sequence(ratings, "RATINGS_INVALID", f"ratings[{judge_id}]")
        parsed: list[float] = []
        for index, raw in enumerate(seq):
            parsed.append(_finite_rate(raw, "RATING_INVALID", f"ratings[{judge_id}][{index}]"))
        judges[judge_id.strip()] = parsed

    lengths = {len(v) for v in judges.values()}
    if len(lengths) != 1:
        raise SpeechEvalError("RATING_LENGTH", "all judges must rate the same number of items")
    item_count = lengths.pop()
    if item_count == 0:
        raise SpeechEvalError("RATING_EMPTY", "judge ratings must not be empty")

    passes = {
        jid: [_judge_pass(r, pass_at) for r in ratings] for jid, ratings in judges.items()
    }
    judge_ids = sorted(passes.keys())
    agree_count = 0
    for item_index in range(item_count):
        votes = {passes[jid][item_index] for jid in judge_ids}
        if len(votes) == 1:
            agree_count += 1
    agreement = agree_count / item_count
    passed = agreement >= limits.min_judge_agreement
    return {
        "card_id": CARD_ID,
        "kind": "tone_scoring_calibration",
        "judge_ids": judge_ids,
        "item_count": item_count,
        "pass_at": pass_at,
        "agreement_rate": agreement,
        "min_judge_agreement": limits.min_judge_agreement,
        "calibration_passed": passed,
        "per_judge_means": {jid: sum(ratings) / len(ratings) for jid, ratings in judges.items()},
    }


def load_eval_bundle(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise SpeechEvalError("EVAL_SET_MISSING", f"eval bundle not found: {path}")
    with path.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise SpeechEvalError("EVAL_BUNDLE_INVALID", "eval bundle root must be an object")
    return data


def request_speech_enablement(
    *,
    language_id: str,
    feature: str,
    bundle: Mapping[str, Any],
    thresholds: EvalThresholds | None = None,
    env: Mapping[str, str] | None = None,
) -> EnablementDecision:
    """Return enablement for asr, tts, or tone_scoring; never fabricates scores (AC4–AC5)."""
    limits = thresholds or DEFAULT_THRESHOLDS
    lang = language_id.strip()
    if not lang:
        raise SpeechEvalError("LANGUAGE_INVALID", "language_id must be non-empty")
    feat = feature.strip().lower()
    if feat not in {"asr", "tts", "tone_scoring"}:
        raise SpeechEvalError("FEATURE_INVALID", "feature must be asr, tts, or tone_scoring")

    if feat == "asr":
        asr = bundle.get("asr")
        if not isinstance(asr, Mapping):
            return EnablementDecision(
                enabled=False,
                reason_code="EVAL_SET_MISSING",
                detail="ASR eval record missing from bundle",
            )
        backend = str(asr.get("backend", ""))
        if backend == "intron" and not intron_asr_available(env):
            return EnablementDecision(
                enabled=False,
                reason_code="INTRON_DISABLED",
                detail="Intron ASR stays off until AI_INTRON_ENABLED and INTRON_API_KEY",
            )
        count = asr.get("utterance_count")
        if count != EXPECTED_UTTERANCE_COUNT:
            return EnablementDecision(
                enabled=False,
                reason_code="EVAL_SET_MISSING",
                detail=f"ASR eval set must have {EXPECTED_UTTERANCE_COUNT} utterances",
            )
        wer = asr.get("wer")
        if wer is None:
            return EnablementDecision(
                enabled=False,
                reason_code="EVAL_INCOMPLETE",
                detail="WER must be recorded; no placeholder score",
            )
        wer_f = _finite_rate(wer, "WER_INVALID", "wer")
        if limits.max_asr_wer is not None and wer_f > limits.max_asr_wer:
            return EnablementDecision(
                enabled=False,
                reason_code="ASR_GATE_FAIL",
                detail=f"WER {wer_f:.3f} exceeds limit {limits.max_asr_wer}",
            )
        return EnablementDecision(enabled=True, reason_code=None, detail="ASR eval passed")

    if feat == "tts":
        tts = bundle.get("tts")
        if not isinstance(tts, Mapping):
            return EnablementDecision(
                enabled=False,
                reason_code="EVAL_SET_MISSING",
                detail="TTS eval record missing from bundle",
            )
        voice_decision = check_tts_voice_gate(tts, limits)
        if not voice_decision.enabled:
            return voice_decision
        if lang in TONAL_TTS_LANGS:
            tone_gate = tts.get("tone_accuracy_gate_passed")
            if tone_gate is not True:
                return EnablementDecision(
                    enabled=False,
                    reason_code="TTS_GATE_FAIL",
                    detail=f"{lang} TTS requires tone-accuracy gate before enablement",
                )
        return EnablementDecision(enabled=True, reason_code=None, detail="TTS eval passed")

    calibration = bundle.get("tone_scoring_calibration")
    if not isinstance(calibration, Mapping):
        return EnablementDecision(
            enabled=False,
            reason_code="EVAL_SET_MISSING",
            detail="tone scoring calibration missing from bundle",
        )
    if calibration.get("calibration_passed") is not True:
        return EnablementDecision(
            enabled=False,
            reason_code="CALIBRATION_FAIL",
            detail="native judge agreement below threshold",
        )
    return EnablementDecision(enabled=True, reason_code=None, detail="tone scoring calibration passed")


def eval_readme_path() -> Path:
    return _EVAL_README
