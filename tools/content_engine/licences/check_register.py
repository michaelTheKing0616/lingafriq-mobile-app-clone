"""CLI: validate licence register CSV and optional content item references."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from tools.content_engine.licences.register_schema import (
    LicenceRegisterError,
    check_items,
    load_register_csv,
    validate_rows,
)

_DEFAULT_CSV = Path(__file__).resolve().parent / "register.csv"


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
