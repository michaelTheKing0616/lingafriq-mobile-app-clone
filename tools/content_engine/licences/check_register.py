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
    args = parser.parse_args(argv)

    items_payload: list[dict[str, str]] | None = None
    if args.items is not None:
        with args.items.open(encoding="utf-8") as handle:
            loaded = json.load(handle)
        if not isinstance(loaded, list):
            print("items file must contain a JSON array", file=sys.stderr)
            return 2
        items_payload = loaded

    try:
        run_check(args.register, items_payload)
    except LicenceRegisterError as exc:
        print(f"{exc.code}: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
