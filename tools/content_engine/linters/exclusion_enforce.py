"""Fail loud when a non-commercial source is used without a written licence.

Training or checking models with non-commercial data is still commercial use.
A manifest claim cannot lift an exclusion. Only the exclusion table can, and
only when that row records a commercial licence document and counsel_status
confirmed.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Mapping, Sequence

try:
    import yaml
except ImportError:  # pragma: no cover - CI installs PyYAML
    yaml = None  # type: ignore[assignment]

_EXCLUSIONS_YAML = Path(__file__).resolve().parents[1] / "licences" / "exclusions.yaml"

# BY-NC covers BY-NC and BY-NC-SA. NC-SA covers NC-SA spellings.
# academic-only covers CLARIN ACA. non-commercial covers paper restrictions.
_NC_LICENCE_RE = re.compile(
    r"BY-NC|NC-SA|non-commercial|academic-only",
    re.IGNORECASE,
)

_USE_FLAGS = ("display", "evidence", "training")
_BLOCKED_STATUSES = frozenset({"excluded", "needs-licence"})
_MANIFEST_LAYERS = frozenset({"lexicon", "corpus", "training", "evidence"})
_COUNSEL_CONFIRMED = "confirmed"


class ExclusionEnforceError(Exception):
    """Exclusion failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def load_exclusions(path: Path | str | None = None) -> dict[str, Any]:
    """Load the exclusion table YAML.

    Returns the parsed mapping. Does not write the file. Raises
    ExclusionEnforceError with code NC_EXCLUDED when a loaded NC row violates
    enforce_row.
    """
    if yaml is None:
        raise ExclusionEnforceError(
            "NC_EXCLUDED",
            "PyYAML is required to load the exclusion table",
        )
    yaml_path = _EXCLUSIONS_YAML if path is None else Path(path)
    with yaml_path.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, Mapping):
        raise ExclusionEnforceError(
            "NC_EXCLUDED",
            "exclusion table must be a YAML mapping",
        )
    loaded = dict(data)
    for source_id, row in _index_sources(loaded).items():
        enforce_row({**row, "source_id": source_id})
    return loaded


def enforce_row(row: Mapping[str, Any]) -> None:
    """Raise NC_EXCLUDED when an NC row is usable without a commercial licence.

    An NC licence is text containing BY-NC, NC-SA, non-commercial, or
    academic-only. When commercial_licence_document is empty, status must be
    excluded and display, evidence, and training must all be false.

    Does not rewrite the row. Returns None when the row is allowed to stand.
    """
    if not isinstance(row, Mapping):
        raise TypeError("row must be a mapping")
    if not _is_nc_licence(_licence_text(row)):
        return
    if _commercial_document(row):
        return
    status = _status(row)
    uses = _use_flags(row)
    if status != "excluded" or any(uses.values()):
        source_id = _source_id_text(row) or "unknown"
        raise ExclusionEnforceError(
            "NC_EXCLUDED",
            f"source_id {source_id} has an NC licence and an empty "
            "commercial_licence_document; status must be excluded and "
            "display, evidence, and training must be false",
        )


def scan_manifest(
    items: Sequence[Mapping[str, Any]],
    table: Mapping[str, Any] | Sequence[Mapping[str, Any]],
) -> None:
    """Raise EXCLUDED_SOURCE_USED when a blocked source appears in a manifest.

    Fails for status excluded or needs-licence. Layers that fail are lexicon,
    corpus, training, and evidence. The message names the source id.

    A confirmed commercial_licence_document on the table row lifts the block.
    A manifest field does not. Does not write the table.
    """
    if isinstance(items, (str, bytes)) or not isinstance(items, Sequence):
        raise TypeError("items must be a sequence of manifest items")
    index = _index_sources(table)
    for item in items:
        if not isinstance(item, Mapping):
            raise TypeError("manifest item must be a mapping")
        source_id = _item_source_id(item)
        if source_id is None:
            raise ExclusionEnforceError(
                "EXCLUDED_SOURCE_USED",
                "manifest item is missing source_id",
            )
        if _jw300_derived_manifest_item(item, source_id):
            raise ExclusionEnforceError(
                "JW300_DERIVED_DATA",
                f"source_id {source_id} is JW300-derived data and cannot be used",
            )
        row = index.get(source_id)
        if row is None:
            continue
        if _exclusion_lifted(row):
            continue
        status = _status(row)
        if status not in _BLOCKED_STATUSES:
            continue
        layer = _item_layer(item)
        # lexicon, corpus, training, and evidence must fail. Another layer
        # is not an escape hatch.
        if layer not in _MANIFEST_LAYERS:
            layer = layer or "unspecified"
        raise ExclusionEnforceError(
            "EXCLUDED_SOURCE_USED",
            f"source_id {source_id} has status {status} and cannot be used "
            f"in layer {layer}",
        )


def lift_exclusion(
    table: Mapping[str, Any] | Sequence[Mapping[str, Any]],
    source_id: str,
    manifest_claim: Mapping[str, Any] | None,
) -> str:
    """Return excluded unless the table row itself records a confirmed licence.

    manifest_claim is ignored, including licensed true. The exclusion lifts
    only when commercial_licence_document is non-empty and counsel_status is
    confirmed. Does not write the table or the shipped exclusions file.
    """
    del manifest_claim
    if not isinstance(source_id, str) or source_id.strip() == "":
        raise TypeError("source_id must be a non-empty string")
    row = _index_sources(table).get(source_id.strip())
    if row is None:
        raise KeyError(source_id)
    if _exclusion_lifted(row):
        return "licensed"
    return "excluded"


def _is_nc_licence(licence: str) -> bool:
    return _NC_LICENCE_RE.search(licence) is not None


def _licence_text(row: Mapping[str, Any]) -> str:
    raw = row.get("licence", "")
    if raw is None:
        return ""
    if not isinstance(raw, str):
        raise TypeError("licence must be a string")
    return raw


def _commercial_document(row: Mapping[str, Any]) -> str:
    return _string_field(row, "commercial_licence_document")


def _counsel_status(row: Mapping[str, Any]) -> str:
    return _string_field(row, "counsel_status")


def _string_field(row: Mapping[str, Any], key: str) -> str:
    if key not in row or row[key] is None:
        return ""
    value = row[key]
    if not isinstance(value, str):
        raise TypeError(f"{key} must be a string")
    return value.strip()


def _status(row: Mapping[str, Any]) -> str:
    raw = row.get("status", "")
    if raw is None:
        return ""
    if not isinstance(raw, str):
        raise TypeError("status must be a string")
    return raw.strip()


def _source_id_text(row: Mapping[str, Any]) -> str:
    raw = row.get("source_id", "")
    if not isinstance(raw, str):
        return ""
    return raw.strip()


def _use_flags(row: Mapping[str, Any]) -> dict[str, bool]:
    raw_uses = row.get("uses", {})
    if raw_uses is None:
        raw_uses = {}
    if not isinstance(raw_uses, Mapping):
        raise TypeError("uses must be a mapping")
    return {name: _as_bool(raw_uses.get(name, False)) for name in _USE_FLAGS}


def _as_bool(value: Any) -> bool:
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        normalized = value.strip().lower()
        if normalized == "true":
            return True
        if normalized == "false":
            return False
    raise TypeError(f"use flag must be true or false, got {value!r}")


def _exclusion_lifted(row: Mapping[str, Any]) -> bool:
    """True only when the row stores a document and counsel_status confirmed.

    When ext05_status is present and not exactly Received, the block stays up
    even with a document and confirmed counsel.
    """
    if "ext05_status" in row and _string_field(row, "ext05_status") != "Received":
        return False
    return (
        _commercial_document(row) != ""
        and _counsel_status(row) == _COUNSEL_CONFIRMED
    )


def _index_sources(
    table: Mapping[str, Any] | Sequence[Mapping[str, Any]],
) -> dict[str, Mapping[str, Any]]:
    if isinstance(table, Mapping) and isinstance(table.get("sources"), Mapping):
        body: Any = table["sources"]
    elif isinstance(table, Mapping) and isinstance(table.get("sources"), list):
        body = table["sources"]
    else:
        body = table
    index: dict[str, Mapping[str, Any]] = {}
    if isinstance(body, Mapping):
        for key, row in body.items():
            if not isinstance(row, Mapping):
                continue
            source_id = str(row.get("source_id") or key).strip()
            if source_id:
                index[source_id] = row
        return index
    if isinstance(body, Sequence) and not isinstance(body, (str, bytes)):
        for row in body:
            if not isinstance(row, Mapping):
                continue
            source_id = str(row.get("source_id", "")).strip()
            if source_id:
                index[source_id] = row
        return index
    raise TypeError("exclusion table must be a mapping or a list of rows")


def _jw300_derived_manifest_item(item: Mapping[str, Any], source_id: str) -> bool:
    """True when the manifest item references JW300 by id, substring, or lineage."""
    if source_id == "jw300" or "jw300" in source_id:
        return True
    derived = item.get("derived_from")
    if isinstance(derived, str) and derived.strip() == "jw300":
        return True
    return False


def _item_source_id(item: Mapping[str, Any]) -> str | None:
    raw = item.get("source_id")
    if not isinstance(raw, str):
        return None
    source_id = raw.strip()
    if source_id == "":
        return None
    return source_id


def _item_layer(item: Mapping[str, Any]) -> str:
    raw = item.get("layer", "")
    if raw is None:
        return ""
    if not isinstance(raw, str):
        raise TypeError("layer must be a string")
    return raw.strip()
