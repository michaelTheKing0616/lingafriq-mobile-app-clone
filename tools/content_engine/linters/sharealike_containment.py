"""Lint share-alike provenance so it cannot enter proprietary learner text."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content_engine.licences.check_register import check_verbatim
from tools.content_engine.licences.register_schema import (
    LicenceRegisterError,
    load_register_csv,
    register_index,
)

_REGISTER_CSV = Path(__file__).resolve().parents[1] / "licences" / "register.csv"

_LEAK_LAYERS = frozenset({"lexicon", "learner-text", "proprietary-lexicon"})
_LAYERS = _LEAK_LAYERS | frozenset({"evidence"})

# BY-SA/GFDL stays share-alike even when the cell is blank or false.
# wiktionary-kaikki is CC BY-SA 4.0 + GFDL with an empty share_alike cell.
_SHAREALIKE_LICENCE_RE = re.compile(r"by-sa|\bgfdl\b", re.IGNORECASE)


class ShareAlikeContainmentError(Exception):
    """Containment failure. `code` is the stable failure id."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def check_sharealike_containment(
    artefact: Mapping[str, Any],
    register_rows: Sequence[Mapping[str, str]] | None = None,
) -> None:
    """Raise when share-alike provenance is outside the attributed evidence layer.

    `lexicon`, `learner-text`, and `proprietary-lexicon` fail with
    SHAREALIKE_LEAK. `evidence` is allowed for a registered source when
    `attribution_text` is non-empty. Learner-text with no source ids fails
    with PROVENANCE_MISSING. Verbatim entries are passed to `check_verbatim`.

    Reads the shipped licence register when `register_rows` is omitted.
    """
    if not isinstance(artefact, Mapping):
        raise ShareAlikeContainmentError(
            "ARTEFACT_INVALID",
            "artefact must be a mapping",
        )
    item_id = _item_id(artefact)
    layer = _layer(artefact, item_id)
    provenance = _provenance(artefact, layer, item_id)
    rows = load_register_csv(_REGISTER_CSV) if register_rows is None else register_rows
    index = register_index(rows)
    attribution = _attribution_text(artefact)

    for entry in provenance:
        source_id = _source_id(entry, item_id)
        verbatim_error = _verbatim_failure(entry, source_id, attribution, rows)
        row = index.get(source_id)
        if row is None:
            if verbatim_error is not None:
                raise verbatim_error
            raise ShareAlikeContainmentError(
                "LICENCE_UNREGISTERED",
                f"item {item_id} cites source_id not in licence register: {source_id}",
            )
        if layer in _LEAK_LAYERS and _is_share_alike(row):
            leak = ShareAlikeContainmentError(
                "SHAREALIKE_LEAK",
                f"item {item_id} cites share-alike source {source_id}",
            )
            if verbatim_error is not None:
                raise leak from verbatim_error
            raise leak
        if verbatim_error is not None:
            raise verbatim_error

    if layer == "evidence" and attribution.strip() == "":
        raise ShareAlikeContainmentError(
            "ATTRIBUTION_MISSING",
            f"item {item_id} evidence layer requires non-empty attribution_text",
        )


def _item_id(artefact: Mapping[str, Any]) -> str:
    raw = artefact.get("item_id")
    if not isinstance(raw, str) or raw.strip() == "":
        raise ShareAlikeContainmentError(
            "ITEM_ID_MISSING",
            "artefact item_id must be a non-empty string",
        )
    return raw.strip()


def _layer(artefact: Mapping[str, Any], item_id: str) -> str:
    raw = artefact.get("layer")
    if not isinstance(raw, str):
        raise ShareAlikeContainmentError(
            "LAYER_INVALID",
            f"item {item_id} layer must be lexicon, learner-text, "
            "evidence, or proprietary-lexicon",
        )
    layer = raw.strip()
    if layer not in _LAYERS:
        raise ShareAlikeContainmentError(
            "LAYER_INVALID",
            f"item {item_id} layer {layer!r} is not a containment layer",
        )
    return layer


def _provenance(
    artefact: Mapping[str, Any],
    layer: str,
    item_id: str,
) -> list[Mapping[str, Any]]:
    if "provenance" not in artefact or artefact["provenance"] is None:
        raw: Any = []
    else:
        raw = artefact["provenance"]
    if not isinstance(raw, list):
        raise ShareAlikeContainmentError(
            "PROVENANCE_MISSING",
            f"item {item_id} provenance must be a list of source ids",
        )
    if layer == "learner-text" and len(raw) == 0:
        raise ShareAlikeContainmentError(
            "PROVENANCE_MISSING",
            f"item {item_id} learner-text provenance must be a non-empty "
            "list of source ids",
        )
    entries: list[Mapping[str, Any]] = []
    for entry in raw:
        if not isinstance(entry, Mapping):
            raise ShareAlikeContainmentError(
                "PROVENANCE_MISSING",
                f"item {item_id} provenance must be a list of source ids",
            )
        entries.append(entry)
    return entries


def _source_id(entry: Mapping[str, Any], item_id: str) -> str:
    raw = entry.get("source_id")
    if not isinstance(raw, str) or raw.strip() == "":
        raise ShareAlikeContainmentError(
            "PROVENANCE_MISSING",
            f"item {item_id} provenance entry is missing source_id",
        )
    return raw.strip()


def _attribution_text(artefact: Mapping[str, Any]) -> str:
    raw = artefact.get("attribution_text", "")
    if raw is None:
        return ""
    if not isinstance(raw, str):
        raise ShareAlikeContainmentError(
            "ATTRIBUTION_MISSING",
            "attribution_text must be a string",
        )
    return raw


def _verbatim_failure(
    entry: Mapping[str, Any],
    source_id: str,
    attribution: str,
    rows: Sequence[Mapping[str, str]],
) -> LicenceRegisterError | None:
    try:
        check_verbatim(
            {
                "source_id": source_id,
                "verbatim": entry.get("verbatim", False),
                "attribution_text": attribution,
            },
            rows,
        )
    except LicenceRegisterError as exc:
        return exc
    return None


def _is_share_alike(row: Mapping[str, Any]) -> bool:
    """share_alike true, or a BY-SA or GFDL licence, is share-alike.

    A blank or false flag does not let a BY-SA or GFDL licence into the lexicon.
    """
    raw = row.get("share_alike", "")
    if raw is True or (isinstance(raw, str) and raw.strip().lower() == "true"):
        return True
    licence = row.get("licence", "")
    if isinstance(licence, str) and _SHAREALIKE_LICENCE_RE.search(licence):
        return True
    return False
