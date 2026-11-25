"""P5-073 recording script export."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.audio.export_scripts import (  # noqa: E402
    CARD_ID,
    EXPORT_CAP_PER_LANGUAGE,
    ExportScriptsError,
    ValidatorContract,
    classify_content_bucket,
    export_recording_scripts,
)


def _item(
    item_id: str,
    *,
    bucket: str | None = None,
    text: str = "Ẹ kú àárọ̀",
) -> dict:
    body = {
        "id": item_id,
        "type": "listen_and_choose",
        "stimulus": {"refs": ["fixture"], "text": text},
        "answer_spec": {"correct": text, "accepted_variants": [text], "diacritic_matching": "strict"},
        "skill_tags": ["listening"],
    }
    if bucket:
        body["recording_bucket"] = bucket
    return body


def _validator(lang: str) -> ValidatorContract:
    return ValidatorContract(
        language=lang,
        consent_template_id="ext-13-consent-v1",
        ip_template_id="ext-13-ip-assignment-v1",
        validator_id=f"{lang}-validator-1",
    )


def test_export_prioritises_a1_lexicon_and_dialogues_then_exposure() -> None:
    items = [
        _item("yo.item.other", bucket="other", text="other high"),
        _item("yo.item.lex", bucket="a1_lexicon", text="lex low"),
        _item("yo.item.dlg", bucket="dialogue", text="dialogue mid"),
    ]
    logs = [
        {"item_id": "yo.item.other", "exposure_count": 500},
        {"item_id": "yo.item.dlg", "exposure_count": 50},
        {"item_id": "yo.item.lex", "exposure_count": 5},
    ]
    scripts = export_recording_scripts(items, logs, [_validator("yo")])
    order = [line.item_id for line in scripts["yo"]]
    assert order == ["yo.item.lex", "yo.item.dlg", "yo.item.other"]
    assert scripts["yo"][0].consent_template_id == "ext-13-consent-v1"
    assert scripts["yo"][0].ip_template_id == "ext-13-ip-assignment-v1"


def test_export_caps_at_two_thousand_per_language() -> None:
    items = [
        _item(f"yo.item.n{i:04d}", bucket="other", text=f"t{i}")
        for i in range(EXPORT_CAP_PER_LANGUAGE + 5)
    ]
    logs = [{"item_id": item["id"], "exposure_count": i} for i, item in enumerate(items)]
    scripts = export_recording_scripts(items, logs, [_validator("yo")])
    assert len(scripts["yo"]) == EXPORT_CAP_PER_LANGUAGE


def test_missing_validator_for_language_raises() -> None:
    items = [_item("ig.item.one", bucket="a1_lexicon")]
    logs = [{"item_id": "ig.item.one", "exposure_count": 1}]
    with pytest.raises(ExportScriptsError) as exc:
        export_recording_scripts(items, logs, [_validator("yo")])
    assert exc.value.code == "VALIDATOR_CONTRACT_MISSING"


def test_classify_dialogue_from_item_type() -> None:
    item = {"id": "yo.item.d1", "type": "short_conversation", "skill_tags": []}
    assert classify_content_bucket(item) == "dialogue"


def test_card_id_constant() -> None:
    assert CARD_ID == "P5-073"
