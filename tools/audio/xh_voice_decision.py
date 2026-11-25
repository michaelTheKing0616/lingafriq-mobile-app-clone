"""isiXhosa voice-path decision artefact (P5-068, CP-§7-xh-03, D3 / ADR-003)."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Mapping

CARD_ID = "P5-068"
LANGUAGE_ID = "xh"
LOCALE = "xh-ZA"
PROCUREMENT_BLOCKER = "EXT-12"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_DECISION_PATH = _REPO_ROOT / "assets/data/audio/xh_voice_decision.json"


class XhVoiceDecisionError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def decision_path() -> Path:
    return _DECISION_PATH


def load_xh_voice_decision(path: Path | None = None) -> dict[str, Any]:
    p = path or _DECISION_PATH
    if not p.is_file():
        raise XhVoiceDecisionError("DECISION_MISSING", f"isiXhosa voice decision not found: {p}")
    with p.open(encoding="utf-8") as fh:
        data = json.load(fh)
    if not isinstance(data, dict):
        raise XhVoiceDecisionError("DECISION_INVALID", "decision root must be an object")
    return data


def validate_xh_voice_decision(data: Mapping[str, Any]) -> None:
    if data.get("card_id") != CARD_ID:
        raise XhVoiceDecisionError("CARD_MISMATCH", f"expected card_id {CARD_ID}")
    if data.get("language_id") != LANGUAGE_ID:
        raise XhVoiceDecisionError("LANGUAGE_MISMATCH", f"expected language_id {LANGUAGE_ID}")
    if data.get("locale") != LOCALE:
        raise XhVoiceDecisionError("LOCALE_MISMATCH", f"expected locale {LOCALE}")

    voice = data.get("voice_path")
    if not isinstance(voice, dict):
        raise XhVoiceDecisionError("VOICE_PATH_MISSING", "voice_path object required")

    opt_b = voice.get("option_b_primary")
    if not isinstance(opt_b, dict):
        raise XhVoiceDecisionError("OPTION_B", "option_b_primary required")
    if opt_b.get("id") != "custom_voice_commission":
        raise XhVoiceDecisionError("OPTION_B", "Option B must be custom_voice_commission")
    if opt_b.get("procurement_blocker") != PROCUREMENT_BLOCKER:
        raise XhVoiceDecisionError("EXT12", f"Option B must cite {PROCUREMENT_BLOCKER}")
    if opt_b.get("dynamic_tts_enabled") is not False:
        raise XhVoiceDecisionError("DYNAMIC_TTS", "dynamic TTS must stay disabled until custom voice")

    opt_a = voice.get("option_a_interim")
    if not isinstance(opt_a, dict):
        raise XhVoiceDecisionError("OPTION_A", "option_a_interim required")
    if opt_a.get("id") != "corpus_matched_audio":
        raise XhVoiceDecisionError("OPTION_A", "Option A must be corpus_matched_audio")
    if opt_a.get("downstream_card") != "P5-069":
        raise XhVoiceDecisionError("OPTION_A", "interim wiring owned by P5-069")

    if voice.get("no_commercial_dynamic_tts") is not True:
        raise XhVoiceDecisionError("NO_VENDOR_TTS", "no commercial dynamic TTS for xh")
    if voice.get("learner_claim_native_xhosa_tts_while_disabled") is not False:
        raise XhVoiceDecisionError("CLAIM", "must not claim native Xhosa TTS while disabled")

    reg = data.get("coverage_register")
    if not isinstance(reg, dict):
        raise XhVoiceDecisionError("COVERAGE_REG", "coverage_register required")
    if reg.get("dynamic_tts_enabled") is not False:
        raise XhVoiceDecisionError("COVERAGE_REG", "stage1 dynamic_tts must be disabled for xh")
    reason = reg.get("disabled_reason_contains")
    if reason != PROCUREMENT_BLOCKER:
        raise XhVoiceDecisionError("COVERAGE_REG", f"disabled_reason must reference {PROCUREMENT_BLOCKER}")

    routing = data.get("routing_for_p5_069")
    if not isinstance(routing, dict):
        raise XhVoiceDecisionError("ROUTING_MISSING", "routing_for_p5_069 required for downstream wiring")
    sources = routing.get("interim_sources")
    if not isinstance(sources, list) or "fleurs" not in sources or "waxal" not in sources:
        raise XhVoiceDecisionError("ROUTING_SOURCES", "interim must list fleurs and waxal")


def xh_dynamic_tts_enabled(data: Mapping[str, Any] | None = None) -> bool:
    doc = data if data is not None else load_xh_voice_decision()
    validate_xh_voice_decision(doc)
    return False


def xh_interim_audio_sources(data: Mapping[str, Any] | None = None) -> list[str]:
    doc = data if data is not None else load_xh_voice_decision()
    validate_xh_voice_decision(doc)
    order = doc["routing_for_p5_069"]["interim_sources"]
    if not isinstance(order, list):
        raise XhVoiceDecisionError("ROUTING_SOURCES", "interim_sources must be a list")
    return [str(x) for x in order]
