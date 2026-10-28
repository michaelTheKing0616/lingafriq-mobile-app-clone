"""P13-001 later-wave language admission template and validator."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest
import yaml

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.content.later_wave_admission import (  # noqa: E402
    CARD_ID,
    LaterWaveAdmissionError,
    load_admission_file,
    load_template,
    materialize_admission_file,
    parse_admission_yaml,
    validate_admission_document,
    write_admission_file,
)

_FIXTURE_REGISTER = [
    {
        "id": "fsi",
        "source": "FSI courses",
        "licence": "Public Domain (US Government)",
    },
    {
        "id": "leipzig",
        "source": "Leipzig Corpora",
        "licence": "CC BY",
    },
]


def _filled_admission(language_id: str = "ff", display_name: str = "Fulfulde") -> dict:
    return {
        "card_id": CARD_ID,
        "language_id": language_id,
        "display_name": display_name,
        "admission": {
            "orthography_authority": {
                "title": "Fulfulde Latin orthography reference",
                "register_id": "fsi",
                "licence": "Public Domain (US Government)",
            },
            "lexicon": {
                "title": "FSI Fulfulde lexicon extract",
                "register_id": "fsi",
                "licence": "Public Domain (US Government)",
            },
            "reference_grammar": {
                "title": "FSI Fulfulde basic course grammar notes",
                "register_id": "fsi",
                "licence": "Public Domain (US Government)",
            },
            "corpus": {
                "title": "Leipzig ff corpus",
                "register_id": "leipzig",
                "licence": "CC BY 4.0",
            },
        },
    }


def test_template_materializes_without_code_change(tmp_path: Path) -> None:
    text = materialize_admission_file("tw", "Twi")
    doc = parse_admission_yaml(text)
    assert doc["language_id"] == "tw"
    assert doc["display_name"] == "Twi"
    assert "{{" not in yaml.dump(doc)
    out = tmp_path / "tw_admission.yaml"
    write_admission_file(out, "tw", "Twi")
    assert load_admission_file(out)["language_id"] == "tw"


def test_validate_accepts_complete_admission() -> None:
    validate_admission_document(_filled_admission(), register_rows=_FIXTURE_REGISTER)


def test_validate_rejects_missing_slot() -> None:
    doc = _filled_admission()
    doc["admission"]["corpus"]["title"] = ""
    with pytest.raises(LaterWaveAdmissionError) as exc:
        validate_admission_document(doc, register_rows=_FIXTURE_REGISTER)
    assert exc.value.code == "ENTRY_INCOMPLETE"
    assert "corpus" in exc.value.args[0].lower()


def test_validate_rejects_unknown_register_id() -> None:
    doc = _filled_admission()
    doc["admission"]["lexicon"]["register_id"] = "not-in-register"
    with pytest.raises(LaterWaveAdmissionError) as exc:
        validate_admission_document(doc, register_rows=_FIXTURE_REGISTER)
    assert exc.value.code == "REGISTER_ID_UNKNOWN"


def test_validate_rejects_non_cc_by_corpus() -> None:
    doc = _filled_admission()
    doc["admission"]["corpus"]["licence"] = "All Rights Reserved"
    with pytest.raises(LaterWaveAdmissionError) as exc:
        validate_admission_document(doc, register_rows=_FIXTURE_REGISTER)
    assert exc.value.code == "CORPUS_LICENCE_INVALID"


def test_load_template_matches_repo_file() -> None:
    assert "orthography_authority" in load_template()


def test_validate_rejects_placeholder_language_id() -> None:
    doc = _filled_admission(language_id="{{LANGUAGE_ID}}")
    with pytest.raises(LaterWaveAdmissionError) as exc:
        validate_admission_document(doc, register_rows=_FIXTURE_REGISTER)
    assert exc.value.code == "LANGUAGE_ID_MISSING"


def test_validate_rejects_wrong_card_id() -> None:
    doc = _filled_admission()
    doc["card_id"] = "P13-999"
    with pytest.raises(LaterWaveAdmissionError) as exc:
        validate_admission_document(doc, register_rows=_FIXTURE_REGISTER)
    assert exc.value.code == "CARD_ID_MISMATCH"


def test_materialize_rejects_invalid_language_id() -> None:
    with pytest.raises(LaterWaveAdmissionError) as exc:
        materialize_admission_file("NOT VALID", "X")
    assert exc.value.code == "LANGUAGE_ID_INVALID"


def test_cli_validate_against_repo_register(tmp_path: Path) -> None:
    path = tmp_path / "ff.yaml"
    path.write_text(
        yaml.safe_dump(_filled_admission()),
        encoding="utf-8",
    )
    from scripts.content.later_wave_admission import main

    assert main(["validate", str(path)]) == 0


def test_load_licence_register_from_repo() -> None:
    from scripts.content.later_wave_admission import load_licence_register

    rows = load_licence_register()
    assert any(r.get("id") == "fsi" for r in rows)
