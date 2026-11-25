"""P7-947: licensed Point-and-Say fine-tune dataset gates."""

from __future__ import annotations

import copy
import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.point_say.eval_heldout import evaluate_heldout  # noqa: E402
from tools.point_say.finetune import (  # noqa: E402
    DEFAULT_TRAIN_MANIFEST,
    PointSayFinetuneError,
    run_finetune,
)

_REGISTER_JSON = _REPO_ROOT / "curriculum/sources/licence_register.json"
_OBJECT_SET = _REPO_ROOT / "assets/lens/african_object_set.json"


def _write_jsonl(path: Path, rows: list[dict]) -> None:
    path.write_text(
        "\n".join(json.dumps(r) for r in rows) + "\n",
        encoding="utf-8",
    )


def _commercial_register(tmp_path: Path) -> Path:
    rows = json.loads(_REGISTER_JSON.read_text(encoding="utf-8"))
    reg = tmp_path / "licence_register.json"
    reg.write_text(json.dumps(rows), encoding="utf-8")
    return reg


def _train_row(**overrides: object) -> dict:
    base = {
        "id": "img-train-1",
        "image_id": "img-train-1",
        "class_slug": "cup",
        "model_label": "afr.cup",
        "licence_source_id": "fsi",
        "split": "train",
    }
    base.update(overrides)
    return base


def test_default_repo_has_no_licensed_training_manifest():
    assert not DEFAULT_TRAIN_MANIFEST.is_file()


def test_missing_manifest_refuses_training(tmp_path: Path):
    with pytest.raises(PointSayFinetuneError) as exc_info:
        run_finetune(
            train_manifest=tmp_path / "missing.jsonl",
            heldout_manifest=None,
            register_json=_REGISTER_JSON,
            object_set_path=_OBJECT_SET,
            output_dir=tmp_path / "out",
        )
    assert exc_info.value.code == "LICENSED_DATASET_MISSING"


def test_non_commercial_licence_writes_no_checkpoint(tmp_path: Path):
    train = tmp_path / "train.jsonl"
    _write_jsonl(
        train,
        [
            _train_row(
                licence_source_id="masakhaner2",
                id="img-nc",
                image_id="img-nc",
            )
        ],
    )
    out = tmp_path / "checkpoints"
    with pytest.raises(PointSayFinetuneError) as exc_info:
        run_finetune(
            train_manifest=train,
            heldout_manifest=None,
            register_json=_REGISTER_JSON,
            object_set_path=_OBJECT_SET,
            output_dir=out,
        )
    assert exc_info.value.code == "TRAINING_REFUSED"
    assert not out.exists() or not any(out.iterdir())


def test_siglip_row_without_opt_in_excluded_from_train(tmp_path: Path):
    train = tmp_path / "train.jsonl"
    _write_jsonl(
        train,
        [
            _train_row(
                source_origin="siglip_match",
                learner_confirmed=False,
                learner_photo_opt_in=False,
            )
        ],
    )
    with pytest.raises(PointSayFinetuneError) as exc_info:
        run_finetune(
            train_manifest=train,
            heldout_manifest=None,
            register_json=_REGISTER_JSON,
            object_set_path=_OBJECT_SET,
            output_dir=tmp_path / "out",
        )
    assert exc_info.value.code == "LICENSED_DATASET_MISSING"


def test_fixture_finetune_with_licensed_row(tmp_path: Path):
    reg = _commercial_register(tmp_path)
    train = tmp_path / "train.jsonl"
    _write_jsonl(train, [_train_row(licence_source_id="fsi")])
    out = tmp_path / "out"
    report = run_finetune(
        train_manifest=train,
        heldout_manifest=None,
        register_json=reg,
        object_set_path=_OBJECT_SET,
        output_dir=out,
    )
    assert report.train_rows == 1
    assert (out / "finetune_metadata.json").is_file()


def test_heldout_disjoint_and_top3_accuracy(tmp_path: Path):
    train = tmp_path / "train.jsonl"
    heldout = tmp_path / "heldout.jsonl"
    _write_jsonl(
        train,
        [_train_row(id="img-a", image_id="img-a")],
    )
    _write_jsonl(
        heldout,
        [
            {
                "id": "img-h1",
                "image_id": "img-h1",
                "model_label": "afr.plantain",
                "class_slug": "plantain",
                "split": "heldout",
            }
        ],
    )
    report = evaluate_heldout(heldout, train_manifest=train)
    assert report.total == 1
    assert report.top3_accuracy == 1.0

    _write_jsonl(
        train,
        [_train_row(id="img-h1", image_id="img-h1")],
    )
    with pytest.raises(PointSayFinetuneError) as exc_info:
        evaluate_heldout(heldout, train_manifest=train)
    assert exc_info.value.code == "HELDOUT_OVERLAP"


def test_priority_class_requires_emit_label(tmp_path: Path):
    reg = _commercial_register(tmp_path)
    train = tmp_path / "train.jsonl"
    _write_jsonl(
        train,
        [
            _train_row(
                class_slug="plantain",
                model_label="plantain",
                object_set_id="afr.plantain",
                licence_source_id="fsi",
            )
        ],
    )
    object_set = tmp_path / "object_set.json"
    payload = json.loads(_OBJECT_SET.read_text(encoding="utf-8"))
    payload["entries"] = copy.deepcopy(payload["entries"])
    payload["entries"].append(
        {
            "object_set_id": "afr.plantain",
            "ml_kit_labels": ["Plantain"],
            "living_dictionary_lexeme_id": "yo.lex.pending",
        }
    )
    object_set.write_text(json.dumps(payload), encoding="utf-8")

    report = run_finetune(
        train_manifest=train,
        heldout_manifest=None,
        register_json=reg,
        object_set_path=object_set,
        output_dir=tmp_path / "out",
    )
    assert "plantain" in report.priority_classes_covered
