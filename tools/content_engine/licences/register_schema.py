"""Licence register row schema and validation (CURRICULUM §2.1)."""

from __future__ import annotations

import csv
import re
from pathlib import Path
from typing import Iterable, Mapping, MutableMapping, Sequence

REGISTER_CSV_COLUMNS: tuple[str, ...] = (
    "source_id",
    "url",
    "licence",
    "version_or_date",
    "display",
    "evidence",
    "training",
    "attribution_text",
    "owner_signoff",
)

_REQUIRED_FIELDS: tuple[str, ...] = (
    "url",
    "licence",
    "version_or_date",
    "display",
    "evidence",
    "training",
    "attribution_text",
    "owner_signoff",
)

_USE_FIELDS: tuple[str, ...] = ("display", "evidence", "training")

_ITEM_KINDS: frozenset[str] = frozenset({"lexicon", "corpus", "audio"})

_NONCOMMERCIAL_LICENCE_RE = re.compile(
    r"by-nc|by-sa|non-commercial", re.IGNORECASE
)


class LicenceRegisterError(Exception):
    """Validation failure for the licence register."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _field_absent(row: Mapping[str, str], field: str) -> bool:
    if field not in row:
        return True
    if field in _USE_FIELDS or field == "owner_signoff":
        return False
    value = row[field]
    if value is None:
        return True
    if isinstance(value, str) and value.strip() == "":
        return True
    return False


def _parse_use_flag(field: str, raw: str) -> bool:
    if raw not in ("true", "false"):
        raise LicenceRegisterError(
            "LICENCE_USE_INVALID",
            f"Use flag {field} must be 'true' or 'false', got {raw!r}",
        )
    return raw == "true"


def _licence_restricts_display_training(licence: str) -> bool:
    return _NONCOMMERCIAL_LICENCE_RE.search(licence) is not None


def validate_row(row: Mapping[str, str]) -> None:
    """Validate a single register row; raise LicenceRegisterError on failure."""
    for field in _REQUIRED_FIELDS:
        if _field_absent(row, field):
            raise LicenceRegisterError(
                "LICENCE_FIELD_MISSING",
                f"Required field missing or empty: {field}",
            )

    uses: dict[str, bool] = {}
    for field in _USE_FIELDS:
        raw = row[field]
        if raw is None or (isinstance(raw, str) and raw.strip() == ""):
            raise LicenceRegisterError(
                "LICENCE_USE_INVALID",
                f"Use flag {field} must be 'true' or 'false', got {raw!r}",
            )
        uses[field] = _parse_use_flag(field, raw)

    signoff = row["owner_signoff"]
    if signoff.strip() == "" and (uses["display"] or uses["training"]):
        raise LicenceRegisterError(
            "LICENCE_UNSIGNED",
            "owner_signoff is empty while display or training is true",
        )

    licence = row["licence"]
    if (uses["display"] or uses["training"]) and _licence_restricts_display_training(
        licence
    ):
        raise LicenceRegisterError(
            "LICENCE_NONCOMMERCIAL",
            "Licence does not permit display or training: "
            f"{licence!r} (BY-NC, BY-SA, or non-commercial)",
        )


def validate_rows(rows: Iterable[Mapping[str, str]]) -> None:
    for row in rows:
        validate_row(row)


def register_index(
    register_rows: Sequence[Mapping[str, str]] | Mapping[str, Mapping[str, str]],
) -> dict[str, Mapping[str, str]]:
    if isinstance(register_rows, Mapping):
        if register_rows and not isinstance(next(iter(register_rows.values())), Mapping):
            raise TypeError("register_rows mapping values must be row mappings")
        return dict(register_rows)
    index: dict[str, Mapping[str, str]] = {}
    for row in register_rows:
        source_id = row.get("source_id", "")
        if source_id:
            index[source_id] = row
    return index


def check_items(
    register_rows: Sequence[Mapping[str, str]] | Mapping[str, Mapping[str, str]],
    items: Sequence[Mapping[str, str]],
) -> None:
    """Ensure each content item cites a registered, valid source."""
    index = register_index(register_rows)
    for item in items:
        source_id = item["source_id"]
        kind = item["kind"]
        if kind not in _ITEM_KINDS:
            raise LicenceRegisterError(
                "LICENCE_ITEM_KIND_INVALID",
                f"Item kind must be lexicon, corpus, or audio, got {kind!r}",
            )
        if source_id not in index:
            raise LicenceRegisterError(
                "LICENCE_UNREGISTERED",
                f"source_id not in licence register: {source_id}",
            )
        validate_row(index[source_id])


def load_register_csv(path: Path | str) -> list[dict[str, str]]:
    path = Path(path)
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise LicenceRegisterError(
                "LICENCE_FIELD_MISSING",
                "Register CSV has no header row",
            )
        header = list(reader.fieldnames)
        for column in REGISTER_CSV_COLUMNS:
            if column not in header:
                raise LicenceRegisterError(
                    "LICENCE_FIELD_MISSING",
                    f"Required column missing from register CSV: {column}",
                )
        rows: list[dict[str, str]] = []
        for raw in reader:
            row: dict[str, str] = {}
            for column in REGISTER_CSV_COLUMNS:
                if column in raw and raw[column] is not None:
                    row[column] = raw[column]
            rows.append(row)
        return rows


def ensure_row_columns(row: MutableMapping[str, str]) -> None:
    """Ensure a row dict includes every column key (values may be empty)."""
    for column in REGISTER_CSV_COLUMNS:
        row.setdefault(column, "")
