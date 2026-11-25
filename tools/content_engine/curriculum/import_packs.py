"""Import course items only from canonical ../curriculum/packs (P4-169, D28)."""

from __future__ import annotations

import json
import sys
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

from tools.content_engine.linters.exclusion_enforce import (
    ExclusionEnforceError,
    load_exclusions,
    scan_manifest,
)
from tools.content_engine.linters.hausa import lint_hausa
from tools.content_engine.linters.sharealike_containment import (
    ShareAlikeContainmentError,
    check_sharealike_containment,
)
from tools.content_engine.linters.yoruba import lint_yoruba

CARD_ID = "P4-169"

# D28 / AC5 — import must not read legacy trees or in-repo curriculum copies.
_FORBIDDEN_PATH_MARKERS: tuple[str, ...] = (
    "lingafriq_full_curriculum_bundle",
    "lingafriq_FINAL_curriculum",
    "LingAfriq Content Writing/generated",
    "node-backend/data/content-packs",
)

_SHIP_OK_SOURCES = frozenset(
    {
        "african_voices",
        "cv27_pcm",
        "cv27_xh",
        "synth-v2",
        "cv_sentences",
        "leipzig",
        "asp",
        "sadilar_morph",
        "sadilar_xhmono",
        "fsi",
    }
)

_ROLE_TO_LAYER: dict[str, str] = {
    "shipped_text": "learner-text",
    "anchor": "lexicon",
    "cross_check": "evidence",
}

_REGISTER_ALIASES: dict[str, str] = {
    "leipzig": "leipzig-corpora",
    "kaikki": "wiktionary-kaikki",
}

_FSI_REGISTER_BY_LANG: dict[str, str] = {
    "yo": "fsi-yoruba",
    "ig": "fsi-igbo",
    "ha": "fsi-hausa",
    "sw": "fsi-swahili",
}

# Orthography allow-lists aligned with curriculum/validators/validate.py (§3.3).
_LANG_CHAR_BASE: dict[str, str] = {
    "yo": "abdefghijklmnoprstuwy'",
    "ig": "abcdefghijklmnoprstuvwyz'",
    "ha": "abcdefghijklmnorstuwyzɓɗƙƴ'",
    "sw": "abcdefghijklmnoprstuvwyz'",
    "zu": "abcdefghijklmnopqrstuvwxyz'",
    "xh": "abcdefghijklmnopqrstuvwxyz'",
    "pcm": "abcdefghijklmnopqrstuvwxyz'",
}
_LANG_COMBINING: dict[str, str] = {
    "yo": "\u0323\u0300\u0301\u0304",
    "ig": "\u0323\u0307\u0300\u0301\u0304",
    "ha": "",
    "sw": "",
    "zu": "",
    "xh": "",
    "pcm": "\u0323",
}


class ImportRejectedError(Exception):
    """Import failed closed. `code` is stable for tests and logs."""

    def __init__(self, code: str, message: str, *, item_id: str = "-") -> None:
        self.code = code
        self.item_id = item_id
        super().__init__(message)


@dataclass(frozen=True)
class ImportedItem:
    item: dict[str, Any]
    pack_path: Path
    synth: bool
    publishable: bool


@dataclass(frozen=True)
class ImportPackResult:
    imported: tuple[ImportedItem, ...]
    rejected: tuple[tuple[str, str, str], ...]  # item_id, code, message


def repo_root(explicit: Path | None = None) -> Path:
    if explicit is not None:
        return explicit.resolve()
    return Path(__file__).resolve().parents[3]


def canonical_curriculum_root(root: Path | None = None) -> Path:
    return repo_root(root).parent / "curriculum"


def canonical_packs_dir(root: Path | None = None) -> Path:
    return canonical_curriculum_root(root) / "packs"


def item_schema_path(root: Path | None = None) -> Path:
    return canonical_curriculum_root(root) / "schema" / "item.schema.json"


def licence_register_path(root: Path | None = None) -> Path:
    return canonical_curriculum_root(root) / "sources" / "licence_register.json"


def load_item_validator(root: Path | None = None) -> Draft202012Validator:
    schema = json.loads(item_schema_path(root).read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema)


def load_curriculum_register(root: Path | None = None) -> dict[str, Mapping[str, Any]]:
    rows = json.loads(licence_register_path(root).read_text(encoding="utf-8"))
    return {row["id"]: row for row in rows if isinstance(row, Mapping) and "id" in row}


def assert_import_path_allowed(requested: Path, root: Path | None = None) -> Path:
    """Raise LEGACY_PATH_FORBIDDEN when the path is not the sibling curriculum packs tree."""
    base = repo_root(root)
    resolved = requested.resolve()
    text = str(resolved)
    for marker in _FORBIDDEN_PATH_MARKERS:
        if marker in text:
            raise ImportRejectedError(
                "LEGACY_PATH_FORBIDDEN",
                f"import path is forbidden: {marker}",
            )
    mobile_curriculum = (base / "curriculum").resolve()
    try:
        resolved.relative_to(mobile_curriculum)
        raise ImportRejectedError(
            "LEGACY_PATH_FORBIDDEN",
            "in-repo mobile curriculum/ tree is not the canonical source",
        )
    except ValueError:
        pass
    packs_root = canonical_packs_dir(base)
    try:
        resolved.relative_to(packs_root.resolve())
    except ValueError:
        raise ImportRejectedError(
            "LEGACY_PATH_FORBIDDEN",
            f"import path must be under canonical packs dir {packs_root}",
        ) from None
    return resolved


def _register_source_id(curriculum_source_id: str, lang: str | None = None) -> str:
    if curriculum_source_id == "fsi" and lang:
        mapped = _FSI_REGISTER_BY_LANG.get(lang)
        if mapped:
            return mapped
    return _REGISTER_ALIASES.get(curriculum_source_id, curriculum_source_id)


def _iter_text_surfaces(item: Mapping[str, Any]) -> list[str]:
    surfaces = [str(item["text"])]
    turns = item.get("turns")
    if isinstance(turns, list):
        for turn in turns:
            if isinstance(turn, Mapping) and isinstance(turn.get("text"), str):
                surfaces.append(turn["text"])
    return surfaces


def _validate_schema(item: Mapping[str, Any], validator: Draft202012Validator) -> None:
    errors = sorted(validator.iter_errors(item), key=lambda e: e.path)
    if errors:
        first = errors[0]
        raise ImportRejectedError(
            "SCHEMA_INVALID",
            first.message,
            item_id=str(item.get("id", "-")),
        )


def _validate_pack_policy(
    item: Mapping[str, Any],
    curriculum_register: Mapping[str, Mapping[str, Any]],
) -> None:
    item_id = str(item["id"])
    for source in item["provenance"]["sources"]:
        if not isinstance(source, Mapping):
            raise ImportRejectedError(
                "PACK_POLICY_INVALID",
                "provenance source must be a mapping",
                item_id=item_id,
            )
        source_id = source.get("source_id")
        if not isinstance(source_id, str) or not source_id:
            raise ImportRejectedError(
                "PACK_POLICY_INVALID",
                "provenance source_id is required",
                item_id=item_id,
            )
        if source_id not in curriculum_register:
            raise ImportRejectedError(
                "UNREGISTERED_SOURCE",
                f"source_id not in curriculum licence register: {source_id}",
                item_id=item_id,
            )
        role = source.get("role")
        if role == "shipped_text" and source_id not in _SHIP_OK_SOURCES:
            raise ImportRejectedError(
                "LICENCE_NOT_SHIPPABLE",
                f"shipped_text source {source_id} is not in the shippable allowlist",
                item_id=item_id,
            )


def _validate_licensing_layer(item: Mapping[str, Any]) -> None:
    item_id = str(item["id"])
    exclusions = load_exclusions()
    manifest_rows: list[dict[str, Any]] = []
    for source in item["provenance"]["sources"]:
        if not isinstance(source, Mapping):
            continue
        source_id = str(source["source_id"])
        role = source.get("role") or "shipped_text"
        layer = _ROLE_TO_LAYER.get(str(role), "learner-text")
        reg_id = _register_source_id(source_id, str(item.get("lang", "")))
        manifest_rows.append(
            {
                "source_id": reg_id,
                "layer": layer,
            }
        )
        artefact: dict[str, Any] = {
            "item_id": item_id,
            "layer": layer,
            "provenance": [{"source_id": reg_id, "verbatim": False}],
        }
        if layer == "evidence":
            artefact["attribution_text"] = (
                f"Curriculum cross-check source {source_id} (evidence only)."
            )
        try:
            check_sharealike_containment(artefact)
        except ShareAlikeContainmentError as exc:
            raise ImportRejectedError(exc.code, str(exc), item_id=item_id) from exc
    try:
        scan_manifest(manifest_rows, exclusions)
    except ExclusionEnforceError as exc:
        raise ImportRejectedError(exc.code, str(exc), item_id=item_id) from exc


def _allowed_nfd_chars(lang: str) -> set[str]:
    allowed = set(_LANG_CHAR_BASE.get(lang, "abcdefghijklmnopqrstuvwxyz"))
    allowed |= set(_LANG_COMBINING.get(lang, ""))
    allowed |= {"-", "\u2019"}
    return allowed


def _lint_unicode_for_lang(lang: str, item_id: str, text: str) -> None:
    nfc = unicodedata.normalize("NFC", text)
    if nfc != text:
        raise ImportRejectedError(
            "UNICODE_NOT_NFC",
            "text must be NFC",
            item_id=item_id,
        )
    allowed = _allowed_nfd_chars(lang)
    bad = set(unicodedata.normalize("NFD", text.lower())) - allowed
    if bad:
        raise ImportRejectedError(
            "CODEPOINT_NOT_ALLOWED",
            f"character outside {lang} orthography: {sorted(bad)!r}",
            item_id=item_id,
        )


def _lint_yoruba_item(item: Mapping[str, Any]) -> None:
    item_id = str(item["id"])
    lexicon = str(item["text"])
    orthography = item.get("orthography")
    if isinstance(orthography, Mapping):
        standard = orthography.get("standard")
        if isinstance(standard, str) and standard.strip():
            lexicon = standard
    lint_item = {
        "id": item_id,
        "learner_facing": True,
        "tokens": [
            {
                "surface": item["text"],
                "lexicon": lexicon,
                "syllabic": False,
            }
        ],
    }
    result = lint_yoruba(lint_item, {"lang": "yo"})
    if result.status != "pass":
        raise ImportRejectedError(
            result.rule_id,
            "Yoruba tone linter rejected item",
            item_id=item_id,
        )


def _lint_hausa_item(item: Mapping[str, Any]) -> None:
    item_id = str(item["id"])
    orthography = item.get("orthography")
    tone_marked = (
        isinstance(orthography, Mapping) and orthography.get("tone_marked") is True
    )
    text_role = "teaching" if tone_marked else "display"
    lexicon = str(item["text"])
    if isinstance(orthography, Mapping):
        standard = orthography.get("standard")
        if isinstance(standard, str) and standard.strip():
            lexicon = standard
    lint_item = {
        "id": item_id,
        "text_role": text_role,
        "tokens": [
            {
                "surface": item["text"],
                "lexicon": lexicon,
                "dictionary_sourced": True,
            }
        ],
    }
    result = lint_hausa(lint_item, {"lang": "ha"})
    if result.status != "pass":
        raise ImportRejectedError(
            result.rule_id,
            "Hausa linter rejected item",
            item_id=item_id,
        )


def _apply_synth_draft_gate(item: dict[str, Any], synth_pack: bool) -> dict[str, Any]:
    if not synth_pack:
        return item
    gated = dict(item)
    gated["status"] = "needs-review"
    gated["label"] = "beta"
    gated.setdefault("feature_hooks", {})
    hooks = dict(gated["feature_hooks"]) if isinstance(gated["feature_hooks"], Mapping) else {}
    hooks["import_publishable"] = False
    gated["feature_hooks"] = hooks
    return gated


def import_curriculum_item(
    item: Mapping[str, Any],
    *,
    pack_path: Path,
    root: Path | None = None,
    validator: Draft202012Validator | None = None,
    curriculum_register: Mapping[str, Mapping[str, Any]] | None = None,
    synth_pack: bool = False,
) -> ImportedItem:
    """Validate and import one curriculum item. Fails closed on any gate."""
    assert_import_path_allowed(pack_path, root)
    if not isinstance(item, Mapping):
        raise ImportRejectedError("ITEM_INVALID", "item must be a mapping")

    base = repo_root(root)
    v = validator or load_item_validator(base)
    reg = curriculum_register or load_curriculum_register(base)

    _validate_schema(item, v)
    _validate_pack_policy(item, reg)
    _validate_licensing_layer(item)

    item_id = str(item["id"])
    lang = str(item["lang"])
    for surface in _iter_text_surfaces(item):
        if surface != unicodedata.normalize("NFC", surface):
            raise ImportRejectedError(
                "UNICODE_NOT_NFC",
                "text must be NFC",
                item_id=item_id,
            )
        _lint_unicode_for_lang(lang, item_id, surface)

    if lang == "yo":
        _lint_yoruba_item(item)
    elif lang == "ha":
        _lint_hausa_item(item)

    out_item = _apply_synth_draft_gate(dict(item), synth_pack)
    publishable = not synth_pack and out_item.get("status") != "needs-review"
    return ImportedItem(
        item=out_item,
        pack_path=pack_path,
        synth=synth_pack,
        publishable=publishable,
    )


def import_pack_file(
    pack_path: Path,
    *,
    root: Path | None = None,
    validator: Draft202012Validator | None = None,
    curriculum_register: Mapping[str, Mapping[str, Any]] | None = None,
) -> ImportPackResult:
    """Import every item in a canonical pack JSON file."""
    resolved = assert_import_path_allowed(pack_path, root)
    if not resolved.is_file():
        raise ImportRejectedError("PACK_NOT_FOUND", f"pack file not found: {resolved}")
    synth = resolved.name.endswith(".synth.json")
    payload = json.loads(resolved.read_text(encoding="utf-8"))
    items = payload.get("items")
    if not isinstance(items, list):
        raise ImportRejectedError("PACK_INVALID", "pack must contain items array")

    imported: list[ImportedItem] = []
    rejected: list[tuple[str, str, str]] = []
    for raw in items:
        item_id = str(raw.get("id", "-")) if isinstance(raw, Mapping) else "-"
        try:
            imported.append(
                import_curriculum_item(
                    raw,
                    pack_path=resolved,
                    root=root,
                    validator=validator,
                    curriculum_register=curriculum_register,
                    synth_pack=synth,
                )
            )
        except ImportRejectedError as exc:
            rejected.append((item_id, exc.code, str(exc)))
    return ImportPackResult(
        imported=tuple(imported),
        rejected=tuple(rejected),
    )


def main(argv: Sequence[str] | None = None) -> int:
    import argparse

    parser = argparse.ArgumentParser(description="Import canonical curriculum pack items.")
    parser.add_argument("pack", type=Path, help="Path under ../curriculum/packs/")
    args = parser.parse_args(argv)
    try:
        result = import_pack_file(args.pack)
    except ImportRejectedError as exc:
        print(json.dumps({"error": exc.code, "message": str(exc)}), file=sys.stderr)
        return 1
    summary = {
        "imported": len(result.imported),
        "rejected": len(result.rejected),
        "synth": args.pack.name.endswith(".synth.json"),
    }
    print(json.dumps(summary))
    return 0 if not result.rejected else 1


if __name__ == "__main__":
    import sys

    raise SystemExit(main())
