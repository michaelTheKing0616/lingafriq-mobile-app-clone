"""Export exposure-ranked recording scripts for contracted native validators (P5-073)."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Literal, Mapping, Sequence

from tools.audio.exposure_rank import ExposureRankError, rank_items_by_exposure

CARD_ID = "P5-073"
EXPORT_CAP_PER_LANGUAGE = 2000

ContentBucket = Literal["a1_lexicon", "dialogue", "other"]
_BUCKET_ORDER: dict[ContentBucket, int] = {"a1_lexicon": 0, "dialogue": 1, "other": 2}


class ExportScriptsError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class ValidatorContract:
    language: str
    consent_template_id: str
    ip_template_id: str
    validator_id: str = ""

    def to_dict(self) -> dict[str, str]:
        out: dict[str, str] = {
            "language": self.language,
            "consent_template_id": self.consent_template_id,
            "ip_template_id": self.ip_template_id,
        }
        if self.validator_id:
            out["validator_id"] = self.validator_id
        return out


@dataclass(frozen=True)
class RecordingScriptLine:
    item_id: str
    language: str
    content_bucket: ContentBucket
    recording_text: str
    exposure_count: int
    script_rank: int
    consent_template_id: str
    ip_template_id: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "item_id": self.item_id,
            "language": self.language,
            "content_bucket": self.content_bucket,
            "recording_text": self.recording_text,
            "exposure_count": self.exposure_count,
            "script_rank": self.script_rank,
            "consent_template_id": self.consent_template_id,
            "ip_template_id": self.ip_template_id,
        }


def language_from_item_id(item_id: str) -> str:
    if not item_id or "." not in item_id:
        raise ExportScriptsError("ITEM_ID_INVALID", "item id must include a language prefix")
    return item_id.split(".", 1)[0].strip().lower()


def classify_content_bucket(item: Mapping[str, Any]) -> ContentBucket:
    explicit = item.get("recording_bucket")
    if explicit in _BUCKET_ORDER:
        return explicit  # type: ignore[return-value]

    item_type = item.get("type")
    if item_type == "short_conversation":
        return "dialogue"

    tags = item.get("skill_tags")
    tag_set = {str(t).lower() for t in tags} if isinstance(tags, Sequence) and not isinstance(tags, str) else set()
    if "dialogue" in tag_set:
        return "dialogue"

    item_id = item.get("id")
    if isinstance(item_id, str):
        lowered = item_id.lower()
        if ".a1." in lowered or ".lex." in lowered or "lexicon" in tag_set:
            return "a1_lexicon"

    return "other"


def recording_text_from_item(item: Mapping[str, Any]) -> str:
    stimulus = item.get("stimulus")
    if isinstance(stimulus, Mapping):
        text = stimulus.get("text")
        if isinstance(text, str) and text.strip():
            return text.strip()
    answer = item.get("answer_spec")
    if isinstance(answer, Mapping):
        correct = answer.get("correct")
        if isinstance(correct, str) and correct.strip():
            return correct.strip()
    raise ExportScriptsError("RECORDING_TEXT_MISSING", "stimulus.text or answer_spec.correct required")


def _exposure_map(usage_logs: Sequence[Mapping[str, Any]] | None) -> dict[str, int]:
    try:
        ranked = rank_items_by_exposure(usage_logs)
    except ExposureRankError as exc:
        if exc.code == "ExposureDataMissing":
            raise ExportScriptsError(exc.code, str(exc)) from exc
        raise ExportScriptsError(exc.code, str(exc)) from exc
    return {row.item_id: row.exposure_count for row in ranked}


def _sort_key(
    item_id: str,
    bucket: ContentBucket,
    exposure_counts: Mapping[str, int],
) -> tuple[int, int, str]:
    exposure = exposure_counts.get(item_id, 0)
    return (_BUCKET_ORDER[bucket], -exposure, item_id)


def export_recording_scripts(
    items: Sequence[Mapping[str, Any]],
    usage_logs: Sequence[Mapping[str, Any]] | None,
    validators: Sequence[ValidatorContract],
    *,
    cap_per_language: int = EXPORT_CAP_PER_LANGUAGE,
) -> dict[str, list[RecordingScriptLine]]:
    """Build per-language recording handover scripts (top *cap* by bucket then exposure)."""
    if cap_per_language < 0:
        raise ExportScriptsError("CAP_INVALID", "cap_per_language must be non-negative")
    if not validators:
        raise ExportScriptsError("VALIDATOR_CONTRACT_MISSING", "at least one validator contract is required")

    contracts: dict[str, ValidatorContract] = {}
    for contract in validators:
        lang = contract.language.strip().lower()
        if not lang:
            raise ExportScriptsError("VALIDATOR_CONTRACT_INVALID", "validator language required")
        if not contract.consent_template_id.strip() or not contract.ip_template_id.strip():
            raise ExportScriptsError(
                "VALIDATOR_CONTRACT_INVALID",
                "consent_template_id and ip_template_id are required",
            )
        contracts[lang] = contract

    exposure_counts = _exposure_map(usage_logs)

    by_language: dict[str, list[tuple[str, ContentBucket, str]]] = {}
    for index, item in enumerate(items):
        if not isinstance(item, Mapping):
            raise ExportScriptsError("ITEM_CATALOG_INVALID", f"items[{index}] must be an object")
        item_id = item.get("id")
        if not isinstance(item_id, str) or not item_id.strip():
            raise ExportScriptsError("ITEM_CATALOG_INVALID", f"items[{index}].id required")
        item_id = item_id.strip()
        language = language_from_item_id(item_id)
        bucket = classify_content_bucket(item)
        text = recording_text_from_item(item)
        by_language.setdefault(language, []).append((item_id, bucket, text))

    scripts: dict[str, list[RecordingScriptLine]] = {}
    for language, rows in by_language.items():
        contract = contracts.get(language)
        if contract is None:
            raise ExportScriptsError(
                "VALIDATOR_CONTRACT_MISSING",
                f"no validator contract for language {language}",
            )
        rows.sort(key=lambda row: _sort_key(row[0], row[1], exposure_counts))
        selected = rows[:cap_per_language]
        lines: list[RecordingScriptLine] = []
        for rank, (item_id, bucket, text) in enumerate(selected, start=1):
            lines.append(
                RecordingScriptLine(
                    item_id=item_id,
                    language=language,
                    content_bucket=bucket,
                    recording_text=text,
                    exposure_count=exposure_counts.get(item_id, 0),
                    script_rank=rank,
                    consent_template_id=contract.consent_template_id,
                    ip_template_id=contract.ip_template_id,
                )
            )
        scripts[language] = lines
    return scripts
