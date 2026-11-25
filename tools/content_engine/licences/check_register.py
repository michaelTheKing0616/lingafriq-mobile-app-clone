"""CLI: validate licence register CSV and optional content item references."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content_engine.licences.register_schema import (
    LicenceRegisterError,
    check_items,
    load_compat_checklist,
    load_register_csv,
    register_index,
    validate_rows,
)

_LICENCES_DIR = Path(__file__).resolve().parent
_DEFAULT_CSV = _LICENCES_DIR / "register.csv"
_CHECKLIST_YAML = _LICENCES_DIR / "compat_checklist.yaml"

_VERBATIM_INCOMPATIBLE_LICENCE_RE = re.compile(
    r"by-sa|by-nc|by-nd|non-commercial", re.IGNORECASE
)

_REPO_ROOT = _LICENCES_DIR.parents[2]
_DEFAULT_POINT_SAY_JSON = _REPO_ROOT / "curriculum/sources/licence_register.json"

_POINT_SAY_MODEL_SPECS: dict[str, dict[str, str]] = {
    "mobilenetv4_conv_small": {
        "revision": "331fb803779522b685cf942e15f914fb6741c1eb",
        "licence": "Apache-2.0",
        "weight_file": "model.safetensors",
    },
    "siglip_base_patch16_224": {
        "revision": "7fd15f0689c79d79e38b1c2e2e2370a7bf2761ed",
        "licence": "Apache-2.0",
        "weight_file": "model.safetensors",
    },
}

_POINT_SAY_EXCLUDED_MODEL_IDS: frozenset[str] = frozenset({"ultralytics_yolo"})

_BUNDLE_FORBIDDEN_LICENCE_RE = re.compile(
    r"agpl|by-sa|by-nc|by-nd|non-commercial|gpl-3", re.IGNORECASE
)

_HF_REVISION_RE = re.compile(r"/blob/([a-f0-9]{40})/")


def _item_verbatim_true(item: Mapping[str, str]) -> bool:
    raw = item.get("verbatim")
    if raw is None:
        return False
    if isinstance(raw, bool):
        return raw
    if isinstance(raw, str):
        return raw.strip().lower() == "true"
    return False


def _licence_allows_verbatim(licence: str) -> bool:
    if _VERBATIM_INCOMPATIBLE_LICENCE_RE.search(licence) is not None:
        return False
    if licence in ("public-domain", "CC0"):
        return True
    if not licence.startswith("CC BY"):
        return False
    return True


def _checklist_tier_is_yes(entry: Mapping[str, Any], tier: str) -> bool:
    raw = entry.get(tier)
    if isinstance(raw, str):
        return raw.strip() == "yes"
    if isinstance(raw, Mapping):
        answer = str(raw.get("answer", raw.get("value", ""))).strip()
        return answer == "yes"
    return False


def _compat_checklist_allows_verbatim(
    checklist: Mapping[str, Any],
    source_id: str,
) -> bool:
    sources = checklist.get("sources")
    if not isinstance(sources, Mapping):
        return False
    entry = sources.get(source_id)
    if not isinstance(entry, Mapping):
        return False
    return _checklist_tier_is_yes(entry, "T1") or _checklist_tier_is_yes(entry, "T2")


def _raise_verbatim_incompatible(message: str) -> None:
    raise LicenceRegisterError("VERBATIM_INCOMPATIBLE", message)


def check_verbatim(
    item: Mapping[str, str],
    register_rows: Sequence[Mapping[str, str]],
    *,
    checklist: Mapping[str, Any] | None = None,
) -> None:
    """Validate verbatim-copy items against register attribution and licence rules."""
    if not _item_verbatim_true(item):
        return
    source_id = item.get("source_id", "")
    if source_id is None or (isinstance(source_id, str) and source_id.strip() == ""):
        raise LicenceRegisterError(
            "ATTRIBUTION_MISSING",
            "Verbatim copy requires source_id and attribution_text",
        )
    attribution = item.get("attribution_text", "")
    if attribution is None or (
        isinstance(attribution, str) and attribution.strip() == ""
    ):
        raise LicenceRegisterError(
            "ATTRIBUTION_MISSING",
            "Verbatim copy requires source_id and attribution_text",
        )
    source_id = source_id.strip()
    row = register_index(register_rows).get(source_id)
    if row is None:
        raise LicenceRegisterError(
            "LICENCE_UNREGISTERED",
            f"source_id not in licence register: {source_id}",
        )
    if row.get("pd_status", "").strip() == "unconfirmed":
        _raise_verbatim_incompatible(
            f"Source {source_id!r} has unconfirmed public-domain status",
        )
    if row.get("discovery_only", "").strip() == "true":
        _raise_verbatim_incompatible(
            f"Source {source_id!r} is discovery-only",
        )
    compat = checklist if checklist is not None else load_compat_checklist(_CHECKLIST_YAML)
    if not _compat_checklist_allows_verbatim(compat, source_id):
        _raise_verbatim_incompatible(
            f"Compatibility checklist T1/T2 does not permit verbatim copy "
            f"for source {source_id!r}",
        )
    licence = row.get("licence", "")
    if not _licence_allows_verbatim(licence):
        _raise_verbatim_incompatible(
            "Source licence does not permit verbatim copy: "
            f"{licence!r}",
        )


def load_point_say_json_register(path: Path | str | None = None) -> list[dict[str, Any]]:
    """Load curriculum licence_register.json rows (Point and Say model register)."""
    register_path = Path(path) if path is not None else _DEFAULT_POINT_SAY_JSON
    with register_path.open(encoding="utf-8") as handle:
        loaded = json.load(handle)
    if not isinstance(loaded, list):
        raise LicenceRegisterError(
            "MODEL_REGISTER_INVALID",
            "licence_register.json must be a JSON array",
        )
    return loaded


def _json_register_index(
    rows: Sequence[Mapping[str, Any]],
) -> dict[str, Mapping[str, Any]]:
    index: dict[str, Mapping[str, Any]] = {}
    for row in rows:
        raw_id = row.get("id")
        if raw_id is None:
            continue
        index[str(raw_id).strip()] = row
    return index


def _revision_from_register_row(row: Mapping[str, Any]) -> str:
    url = str(row.get("url", ""))
    match = _HF_REVISION_RE.search(url)
    if match:
        return match.group(1)
    attribution = str(row.get("attribution", ""))
    match = re.search(r"Revision ([a-f0-9]{40})", attribution)
    if match:
        return match.group(1)
    notes = str(row.get("notes", ""))
    match = re.search(r"revision ([a-f0-9]{40})", notes, re.IGNORECASE)
    if match:
        return match.group(1)
    return ""


def _licence_blocks_point_say_bundle(licence: Any) -> bool:
    if licence is None:
        return True
    text = str(licence).strip()
    if text == "":
        return True
    if _BUNDLE_FORBIDDEN_LICENCE_RE.search(text) is not None:
        return True
    return False


def _use_excluded(row: Mapping[str, Any]) -> bool:
    use = str(row.get("use", "")).strip().casefold()
    return use == "excluded" or use.startswith("excluded ")


def _licence_allows_point_say_training(licence: Any) -> bool:
    if licence is None:
        return False
    text = str(licence).strip()
    if text == "":
        return False
    if _BUNDLE_FORBIDDEN_LICENCE_RE.search(text) is not None:
        return False
    lowered = text.casefold()
    if lowered.startswith("original"):
        return True
    if "cc0" in lowered or "public domain" in lowered or "public-domain" in lowered:
        return True
    if lowered in ("apache-2.0",):
        return True
    if "apache-2.0" in lowered:
        return True
    if lowered.startswith("cc by") and _VERBATIM_INCOMPATIBLE_LICENCE_RE.search(text) is None:
        return True
    return False


def validate_point_say_register(rows: Sequence[Mapping[str, Any]]) -> None:
    """Ensure bundled Point and Say checkpoints are registered with required revisions."""
    index = _json_register_index(rows)
    for model_id, spec in _POINT_SAY_MODEL_SPECS.items():
        row = index.get(model_id)
        if row is None:
            raise LicenceRegisterError(
                "MODEL_REGISTER_INCOMPLETE",
                f"Point and Say register missing row {model_id!r}",
            )
        licence = str(row.get("licence", "")).strip()
        if licence != spec["licence"]:
            raise LicenceRegisterError(
                "MODEL_REGISTER_INCOMPLETE",
                f"{model_id!r} licence must be {spec['licence']!r}, got {licence!r}",
            )
        revision = _revision_from_register_row(row)
        if revision != spec["revision"]:
            raise LicenceRegisterError(
                "MODEL_REGISTER_INCOMPLETE",
                f"{model_id!r} revision must be {spec['revision']!r}, got {revision!r}",
            )
        url = str(row.get("url", ""))
        source = str(row.get("source", ""))
        weight = spec["weight_file"]
        if weight not in url and weight not in source:
            raise LicenceRegisterError(
                "MODEL_REGISTER_INCOMPLETE",
                f"{model_id!r} must name {weight!r} in url or source",
            )
        if url.strip() == "":
            raise LicenceRegisterError(
                "MODEL_REGISTER_INCOMPLETE",
                f"{model_id!r} requires a source URL",
            )


def check_point_say_model_bundle(
    model_id: str,
    rows: Sequence[Mapping[str, Any]],
) -> None:
    """Refuse bundling weights whose licence row is missing, excluded, or non-commercial."""
    model_id = model_id.strip()
    if model_id in _POINT_SAY_EXCLUDED_MODEL_IDS:
        raise LicenceRegisterError(
            "MODEL_BUNDLE_FORBIDDEN",
            f"Ultralytics YOLO weights must not be bundled ({model_id!r})",
        )
    row = _json_register_index(rows).get(model_id)
    if row is None:
        raise LicenceRegisterError(
            "MODEL_BUNDLE_FORBIDDEN",
            f"model is not in the licence register: {model_id!r}",
        )
    if _use_excluded(row):
        raise LicenceRegisterError(
            "MODEL_BUNDLE_FORBIDDEN",
            f"model {model_id!r} is marked excluded in the register",
        )
    licence = row.get("licence")
    if _licence_blocks_point_say_bundle(licence):
        raise LicenceRegisterError(
            "MODEL_BUNDLE_FORBIDDEN",
            f"model {model_id!r} licence {licence!r} is not bundleable",
        )


def check_point_say_training_sources(
    source_ids: Sequence[str],
    rows: Sequence[Mapping[str, Any]],
) -> None:
    """Refuse fine-tuning when any image source lacks a commercial or original licence row."""
    index = _json_register_index(rows)
    for raw_id in source_ids:
        source_id = raw_id.strip()
        if source_id == "":
            raise LicenceRegisterError(
                "TRAINING_REFUSED",
                "training image requires a register source id",
            )
        row = index.get(source_id)
        if row is None:
            raise LicenceRegisterError(
                "TRAINING_REFUSED",
                f"training image source not in licence register: {source_id!r}",
            )
        if _use_excluded(row):
            raise LicenceRegisterError(
                "TRAINING_REFUSED",
                f"training source {source_id!r} is excluded",
            )
        if not _licence_allows_point_say_training(row.get("licence")):
            raise LicenceRegisterError(
                "TRAINING_REFUSED",
                f"training source {source_id!r} has no commercial or original licence",
            )


def g4_counsel_gate(register_rows: Sequence[Mapping[str, str]]) -> dict[str, str]:
    """G4 gate: block while counsel has not confirmed every register source."""
    for row in register_rows:
        if row.get("counsel_status", "").strip() != "confirmed":
            return {"status": "Blocked-External", "blocker": "EXT-03"}
    return {"status": "Pass"}


def run_check(
    csv_path: Path,
    items: list[dict[str, str]] | None = None,
) -> None:
    rows = load_register_csv(csv_path)
    validate_rows(rows)
    if items:
        check_items(rows, items)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate licence register")
    parser.add_argument(
        "--register",
        type=Path,
        default=_DEFAULT_CSV,
        help="Path to register.csv",
    )
    parser.add_argument(
        "--items",
        type=Path,
        default=None,
        help="JSON file: list of {source_id, kind} objects to verify",
    )
    parser.add_argument(
        "--point-say-json",
        type=Path,
        default=None,
        help="Validate Point and Say rows in curriculum licence_register.json",
    )
    parser.add_argument(
        "--bundle-model",
        action="append",
        default=[],
        metavar="MODEL_ID",
        help="Check a model id may be bundled (repeatable)",
    )
    parser.add_argument(
        "--training-source",
        action="append",
        default=[],
        metavar="SOURCE_ID",
        help="Check a fine-tune image source id (repeatable)",
    )
    args = parser.parse_args(argv)

    items_payload: list[dict[str, str]] | None = None
    if args.items is not None:
        with args.items.open(encoding="utf-8") as handle:
            loaded = json.load(handle)
        if not isinstance(loaded, list):
            print("items file must contain a JSON array", file=sys.stderr)
            return 2
        items_payload = loaded

    point_say_rows: list[dict[str, Any]] | None = None
    if args.point_say_json is not None or args.bundle_model or args.training_source:
        point_say_rows = load_point_say_json_register(args.point_say_json)

    try:
        run_check(args.register, items_payload)
        if point_say_rows is not None:
            validate_point_say_register(point_say_rows)
            for model_id in args.bundle_model:
                check_point_say_model_bundle(model_id, point_say_rows)
            if args.training_source:
                check_point_say_training_sources(args.training_source, point_say_rows)
    except LicenceRegisterError as exc:
        print(f"{exc.code}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
