"""Point and Say model weight licence gates (P4-168)."""

from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.check_register import (  # noqa: E402
    LicenceRegisterError,
    check_point_say_model_bundle,
    check_point_say_training_sources,
    load_point_say_json_register,
    validate_point_say_register,
)

_REGISTER_JSON = _REPO_ROOT / "curriculum/sources/licence_register.json"


@pytest.fixture(scope="module")
def register_rows() -> list[dict]:
    return load_point_say_json_register(_REGISTER_JSON)


def test_curriculum_register_passes_point_say_validation(
    register_rows: list[dict],
) -> None:
    validate_point_say_register(register_rows)
    check_point_say_model_bundle("mobilenetv4_conv_small", register_rows)
    check_point_say_model_bundle("siglip_base_patch16_224", register_rows)


def test_apache_mobilenet_and_siglip_rows_match_required_revisions(
    register_rows: list[dict],
) -> None:
    by_id = {row["id"]: row for row in register_rows}
    mobilenet = by_id["mobilenetv4_conv_small"]
    assert mobilenet["licence"] == "Apache-2.0"
    assert "331fb803779522b685cf942e15f914fb6741c1eb" in mobilenet["url"]
    assert "model.safetensors" in mobilenet["url"]

    siglip = by_id["siglip_base_patch16_224"]
    assert siglip["licence"] == "Apache-2.0"
    assert "7fd15f0689c79d79e38b1c2e2e2370a7bf2761ed" in siglip["url"]
    assert "model.safetensors" in siglip["url"]


def test_ultralytics_yolo_bundle_forbidden(register_rows: list[dict]) -> None:
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_point_say_model_bundle("ultralytics_yolo", register_rows)
    assert exc_info.value.code == "MODEL_BUNDLE_FORBIDDEN"


def test_non_commercial_model_row_fails_bundle(tmp_path: Path) -> None:
    rows = json.loads(_REGISTER_JSON.read_text(encoding="utf-8"))
    patched = copy.deepcopy(rows)
    for row in patched:
        if row.get("id") == "mobilenetv4_conv_small":
            row["licence"] = "CC BY-NC 4.0"
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_point_say_model_bundle("mobilenetv4_conv_small", patched)
    assert exc_info.value.code == "MODEL_BUNDLE_FORBIDDEN"


def test_missing_licence_fails_bundle(tmp_path: Path) -> None:
    rows = [
        {
            "id": "custom_model",
            "source": "example weights",
            "url": "https://example.com/weights",
            "licence": "",
            "use": "ship",
        }
    ]
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_point_say_model_bundle("custom_model", rows)
    assert exc_info.value.code == "MODEL_BUNDLE_FORBIDDEN"


def test_training_refused_when_image_source_missing(register_rows: list[dict]) -> None:
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_point_say_training_sources(["not-a-register-id"], register_rows)
    assert exc_info.value.code == "TRAINING_REFUSED"


def test_training_refused_for_non_commercial_source(register_rows: list[dict]) -> None:
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_point_say_training_sources(["masakhaner2"], register_rows)
    assert exc_info.value.code == "TRAINING_REFUSED"


def test_training_allowed_for_cc0_sentence_source(register_rows: list[dict]) -> None:
    check_point_say_training_sources(["cv_sentences"], register_rows)


def test_training_allowed_for_original_collected_source(
    register_rows: list[dict],
) -> None:
    check_point_say_training_sources(["synth-v2"], register_rows)
