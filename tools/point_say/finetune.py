"""Licensed Point-and-Say classifier fine-tune pipeline (P7-947)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.check_register import (  # noqa: E402
    LicenceRegisterError,
    check_point_say_model_bundle,
    check_point_say_training_sources,
    load_point_say_json_register,
)

DEFAULT_TRAIN_MANIFEST = _REPO_ROOT / "assets/data/point_say/training_manifest.jsonl"
DEFAULT_HELDOUT_MANIFEST = _REPO_ROOT / "assets/data/point_say/heldout_manifest.jsonl"
DEFAULT_REGISTER_JSON = _REPO_ROOT / "curriculum/sources/licence_register.json"
DEFAULT_OBJECT_SET = _REPO_ROOT / "assets/lens/african_object_set.json"

PRIORITY_CLASS_SLUGS: frozenset[str] = frozenset(
    {
        "plantain",
        "garri",
        "agbada",
        "mortar_and_pestle",
        "danfo",
        "akara",
        "kente",
    }
)


class PointSayFinetuneError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(f"{code}:{message}")


@dataclass(frozen=True)
class FinetuneReport:
    train_rows: int
    checkpoint_dir: Path
    priority_classes_covered: list[str]


def _load_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.is_file():
        raise PointSayFinetuneError(
            "LICENSED_DATASET_MISSING",
            f"training manifest not found: {path}",
        )
    rows: list[dict[str, Any]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if line:
            rows.append(json.loads(line))
    if not rows:
        raise PointSayFinetuneError(
            "LICENSED_DATASET_MISSING",
            f"training manifest is empty: {path}",
        )
    return rows


def _row_id(row: Mapping[str, Any]) -> str:
    return str(row.get("image_id") or row.get("id") or "").strip()


def _eligible_for_training(row: Mapping[str, Any]) -> bool:
    split = str(row.get("split", "train")).strip().casefold()
    if split in {"heldout", "held-out", "eval", "test"}:
        return False
    origin = str(row.get("source_origin", "")).strip().casefold()
    if origin == "siglip_match":
        confirmed = row.get("learner_confirmed")
        opt_in = row.get("learner_photo_opt_in")
        if confirmed is not True or opt_in is not True:
            return False
    return True


def _collect_training_rows(rows: Sequence[Mapping[str, Any]]) -> list[dict[str, Any]]:
    return [dict(r) for r in rows if _eligible_for_training(r)]


def _assert_heldout_disjoint(
    train_rows: Sequence[Mapping[str, Any]],
    heldout_rows: Sequence[Mapping[str, Any]],
) -> None:
    train_ids = {_row_id(r) for r in train_rows if _row_id(r)}
    overlap = [
        _row_id(r)
        for r in heldout_rows
        if _row_id(r) and _row_id(r) in train_ids
    ]
    if overlap:
        raise PointSayFinetuneError(
            "HELDOUT_OVERLAP",
            f"held-out images must not appear in training: {overlap[:5]}",
        )


def _priority_slugs_in_rows(rows: Sequence[Mapping[str, Any]]) -> set[str]:
    found: set[str] = set()
    for row in rows:
        slug = str(row.get("class_slug", "")).strip().casefold()
        if slug:
            found.add(slug.replace(" ", "_"))
        label = str(row.get("model_label", "")).strip().casefold()
        if label:
            found.add(label.replace(" ", "_"))
    return found


def _assert_priority_class_labels(
    train_rows: Sequence[Mapping[str, Any]],
    object_set_path: Path,
) -> list[str]:
    present = _priority_slugs_in_rows(train_rows) & PRIORITY_CLASS_SLUGS
    if not present:
        return []
    if not object_set_path.is_file():
        raise PointSayFinetuneError(
            "OBJECT_SET_MISSING",
            f"cannot map priority classes without {object_set_path}",
        )
    payload = json.loads(object_set_path.read_text(encoding="utf-8"))
    entries = payload.get("entries") or []
    known_ids = {
        str(e.get("object_set_id", "")).strip()
        for e in entries
        if isinstance(e, dict)
    }
    covered: list[str] = []
    for slug in sorted(present):
        object_set_id = f"afr.{slug}"
        alt = f"afr.{slug.replace('_', '')}"
        if object_set_id not in known_ids and alt not in known_ids:
            for row in train_rows:
                if str(row.get("class_slug", "")).replace(" ", "_").casefold() == slug:
                    if str(row.get("object_set_id", "")).strip():
                        break
            else:
                raise PointSayFinetuneError(
                    "PRIORITY_CLASS_UNMAPPED",
                    f"priority class {slug!r} has no object_set_id the on-device model can emit",
                )
        covered.append(slug)
    return covered


def assert_training_licensed(
    train_rows: Sequence[Mapping[str, Any]],
    register_json: Path,
) -> None:
    register = load_point_say_json_register(register_json)
    check_point_say_model_bundle("mobilenetv4_conv_small", register)
    source_ids = sorted(
        {
            str(r.get("licence_source_id", "")).strip()
            for r in train_rows
            if str(r.get("licence_source_id", "")).strip()
        }
    )
    if not source_ids:
        raise PointSayFinetuneError(
            "TRAINING_REFUSED",
            "every training row requires licence_source_id",
        )
    try:
        check_point_say_training_sources(source_ids, register)
    except LicenceRegisterError as exc:
        raise PointSayFinetuneError(exc.code, str(exc)) from exc


def run_finetune(
    *,
    train_manifest: Path,
    heldout_manifest: Path | None,
    register_json: Path,
    object_set_path: Path,
    output_dir: Path,
    mode: str = "fixture",
) -> FinetuneReport:
    all_rows = _load_jsonl(train_manifest)
    train_rows = _collect_training_rows(all_rows)
    if not train_rows:
        raise PointSayFinetuneError(
            "LICENSED_DATASET_MISSING",
            "no eligible training rows after split and SigLIP opt-in filters",
        )

    heldout_rows: list[dict[str, Any]] = []
    if heldout_manifest is not None and heldout_manifest.is_file():
        heldout_rows = _load_jsonl(heldout_manifest)
        _assert_heldout_disjoint(train_rows, heldout_rows)

    assert_training_licensed(train_rows, register_json)
    priority_covered = _assert_priority_class_labels(train_rows, object_set_path)

    output_dir.mkdir(parents=True, exist_ok=True)
    if mode != "fixture":
        raise PointSayFinetuneError(
            "TRAINING_MODE_UNSUPPORTED",
            "only fixture mode is wired until a licensed image corpus is checked in",
        )

    meta = {
        "card": "P7-947",
        "base_model": "mobilenetv4_conv_small",
        "train_rows": len(train_rows),
        "heldout_manifest": str(heldout_manifest) if heldout_manifest else None,
        "priority_classes_covered": priority_covered,
        "mode": mode,
    }
    (output_dir / "finetune_metadata.json").write_text(
        json.dumps(meta, indent=2) + "\n",
        encoding="utf-8",
    )
    return FinetuneReport(
        train_rows=len(train_rows),
        checkpoint_dir=output_dir,
        priority_classes_covered=priority_covered,
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Point-and-Say licensed fine-tune")
    parser.add_argument("--train-manifest", type=Path, default=DEFAULT_TRAIN_MANIFEST)
    parser.add_argument("--heldout-manifest", type=Path, default=DEFAULT_HELDOUT_MANIFEST)
    parser.add_argument("--register-json", type=Path, default=DEFAULT_REGISTER_JSON)
    parser.add_argument("--object-set", type=Path, default=DEFAULT_OBJECT_SET)
    parser.add_argument("--output", type=Path, default=_REPO_ROOT / "build/point_say/checkpoints")
    parser.add_argument("--mode", choices=("fixture",), default="fixture")
    args = parser.parse_args(argv)

    heldout = args.heldout_manifest if args.heldout_manifest.is_file() else None
    try:
        report = run_finetune(
            train_manifest=args.train_manifest,
            heldout_manifest=heldout,
            register_json=args.register_json,
            object_set_path=args.object_set,
            output_dir=args.output,
            mode=args.mode,
        )
    except PointSayFinetuneError as exc:
        print(exc, file=sys.stderr)
        return 1

    print(
        json.dumps(
            {
                "train_rows": report.train_rows,
                "checkpoint_dir": str(report.checkpoint_dir),
                "priority_classes_covered": report.priority_classes_covered,
            }
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
