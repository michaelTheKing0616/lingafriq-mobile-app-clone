"""Declared dialect standards and per-item dialect tags (P5-039, CURRICULUM §6)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Mapping, Sequence

import yaml

from tools.content.placeholder_linter import repo_root
from tools.content_pipeline.dialect_policy_decision import (
    load_dialect_policy_decision,
    stage_1_by_language,
)

CARD_ID = "P5-039"
CODE_DIALECT_UNSOURCED = "DialectUnsourced"
CODE_DIALECT_TAG_MISSING = "DialectTagMissing"
CODE_KIT_STANDARD_MISSING = "KitStandardMissing"

_DIALECT_TAG_LANGUAGES = frozenset({"yo", "ig"})
_TAG_RE = re.compile(r"^(standard|[a-z0-9_-]{2,64})$")
_KIT_SOURCES_REL = "tools/content_engine/kits/{language_id}/sources.yaml"


class DialectCheckError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def language_id_from_item_id(item_id: str) -> str | None:
    if not isinstance(item_id, str) or "." not in item_id:
        return None
    return item_id.split(".", 1)[0].strip().lower() or None


def read_kit_orthography_standard(language_id: str, root: Path | None = None) -> str:
    """Return the orthography.standard string from the language kit sources.yaml."""
    base = repo_root(root)
    rel = _KIT_SOURCES_REL.format(language_id=language_id)
    path = base / rel
    if not path.is_file():
        raise DialectCheckError("KIT_SOURCES_MISSING", f"kit sources missing: {rel}")
    with path.open(encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, Mapping):
        raise DialectCheckError(CODE_KIT_STANDARD_MISSING, f"{language_id} sources.yaml invalid")
    orthography = data.get("orthography")
    if not isinstance(orthography, Mapping):
        raise DialectCheckError(CODE_KIT_STANDARD_MISSING, f"{language_id} orthography section missing")
    standard = orthography.get("standard")
    if not isinstance(standard, str) or not standard.strip():
        raise DialectCheckError(CODE_KIT_STANDARD_MISSING, f"{language_id} orthography.standard missing")
    return standard.strip()


def assert_language_kit_declares_standard(language_id: str, root: Path | None = None) -> str:
    """AC1: kit sources and dialect policy both declare the taught standard."""
    lang = language_id.strip().lower()
    if lang not in _DIALECT_TAG_LANGUAGES:
        raise DialectCheckError("LANGUAGE_UNSUPPORTED", f"standard declaration check is for yo/ig; got {lang}")
    kit_standard = read_kit_orthography_standard(lang, root=root)
    policy = stage_1_by_language(load_dialect_policy_decision())
    row = policy.get(lang)
    if not row:
        raise DialectCheckError("POLICY_MISSING", f"no stage_1 dialect policy for {lang}")
    taught = row.get("standard_taught")
    if not isinstance(taught, str) or not taught.strip():
        raise DialectCheckError(CODE_KIT_STANDARD_MISSING, f"{lang} standard_taught missing in policy")
    return kit_standard


def _allowed_regional_tags(language_id: str) -> frozenset[str]:
    policy = stage_1_by_language(load_dialect_policy_decision())
    row = policy.get(language_id, {})
    variants = row.get("regional_variants") or []
    tags: set[str] = set()
    for var in variants:
        if isinstance(var, Mapping):
            tag = var.get("dialect_tag")
            if isinstance(tag, str) and tag.strip():
                tags.add(tag.strip())
    return frozenset(tags)


def _provenance_source_ids(item: Mapping[str, Any]) -> frozenset[str]:
    keys: set[str] = set()
    provenance = item.get("provenance")
    if isinstance(provenance, Mapping):
        for source in provenance.get("sources") or []:
            if not isinstance(source, Mapping):
                continue
            name = source.get("name")
            if isinstance(name, str) and name.strip():
                keys.add(name.strip())
            uri = source.get("uri_or_citation")
            if isinstance(uri, str) and uri.strip():
                keys.add(uri.strip())
    for claim in item.get("claims") or []:
        if isinstance(claim, Mapping):
            sid = claim.get("source_id")
            if isinstance(sid, str) and sid.strip():
                keys.add(sid.strip())
    return frozenset(keys)


def _variant_rows(item: Mapping[str, Any]) -> list[Mapping[str, Any]]:
    rows = item.get("dialect_variants")
    if rows is None:
        return []
    if not isinstance(rows, list):
        raise DialectCheckError(CODE_DIALECT_UNSOURCED, "dialect_variants must be a list")
    out: list[Mapping[str, Any]] = []
    for index, row in enumerate(rows):
        if not isinstance(row, Mapping):
            raise DialectCheckError(CODE_DIALECT_UNSOURCED, f"dialect_variants[{index}] must be an object")
        out.append(row)
    return out


def validate_item_dialect(item: Mapping[str, Any], *, publish: bool = False) -> None:
    """AC2–AC3: dialect_tag on yo/ig items; regional variants must be sourced to publish."""
    if not isinstance(item, Mapping):
        raise DialectCheckError(CODE_DIALECT_TAG_MISSING, "item must be a mapping")
    lang = language_id_from_item_id(str(item.get("id", "")))
    if lang not in _DIALECT_TAG_LANGUAGES:
        return

    tag = item.get("dialect_tag")
    if not isinstance(tag, str) or not tag.strip():
        raise DialectCheckError(CODE_DIALECT_TAG_MISSING, f"{lang} item requires dialect_tag")
    tag = tag.strip()
    if not _TAG_RE.match(tag):
        raise DialectCheckError(CODE_DIALECT_TAG_MISSING, "dialect_tag format invalid")

    regional_allowed = _allowed_regional_tags(lang)
    known_sources = _provenance_source_ids(item)
    variants_by_text: dict[str, Mapping[str, Any]] = {}
    for row in _variant_rows(item):
        text = row.get("text")
        vtag = row.get("dialect_tag")
        source_id = row.get("source_id")
        if not isinstance(text, str) or not text.strip():
            raise DialectCheckError(CODE_DIALECT_UNSOURCED, "dialect variant text required")
        if not isinstance(vtag, str) or not _TAG_RE.match(vtag.strip()):
            raise DialectCheckError(CODE_DIALECT_UNSOURCED, "dialect variant dialect_tag invalid")
        vtag = vtag.strip()
        if vtag == "standard":
            raise DialectCheckError(CODE_DIALECT_UNSOURCED, "dialect variant must not use standard tag")
        if publish:
            if not isinstance(source_id, str) or not source_id.strip():
                raise DialectCheckError(CODE_DIALECT_UNSOURCED, f"unsourced dialect variant {text!r}")
            if source_id.strip() not in known_sources and vtag not in regional_allowed:
                raise DialectCheckError(
                    CODE_DIALECT_UNSOURCED,
                    f"variant {text!r} source_id not in provenance and tag not in policy",
                )
        variants_by_text[text.strip()] = row

    if tag != "standard" and tag not in regional_allowed:
        if not publish:
            return
        matched = any(
            isinstance(row.get("dialect_tag"), str) and row.get("dialect_tag", "").strip() == tag
            for row in variants_by_text.values()
        )
        if not matched:
            raise DialectCheckError(
                CODE_DIALECT_UNSOURCED,
                f"item dialect_tag {tag} not in policy and no matching dialect_variants row",
            )

    answer = item.get("answer_spec")
    if isinstance(answer, Mapping):
        for variant_text in answer.get("accepted_variants") or []:
            if not isinstance(variant_text, str) or not variant_text.strip():
                continue
            key = variant_text.strip()
            if key == answer.get("correct"):
                continue
            row = variants_by_text.get(key)
            if row is None and publish and tag != "standard":
                raise DialectCheckError(
                    CODE_DIALECT_UNSOURCED,
                    f"accepted_variant {key!r} requires dialect_variants entry to publish",
                )


def assert_yo_ig_kit_standards(root: Path | None = None) -> dict[str, str]:
    return {
        "yo": assert_language_kit_declares_standard("yo", root=root),
        "ig": assert_language_kit_declares_standard("ig", root=root),
    }


def _main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="P5-039 dialect standard and item tag checks")
    parser.add_argument("--check-kits", action="store_true", help="Assert yo/ig kit standards (AC1)")
    parser.add_argument("--item", type=Path, help="JSON item file to validate")
    parser.add_argument("--publish", action="store_true", help="Apply publish-time variant sourcing (AC3)")
    args = parser.parse_args(argv)
    try:
        if args.check_kits:
            out = assert_yo_ig_kit_standards()
            print(json.dumps({"card_id": CARD_ID, "kit_standards": out}, ensure_ascii=False))
        if args.item:
            data = json.loads(args.item.read_text(encoding="utf-8"))
            validate_item_dialect(data, publish=args.publish)
            print(json.dumps({"card_id": CARD_ID, "ok": True, "id": data.get("id")}))
        if not args.check_kits and not args.item:
            parser.error("pass --check-kits and/or --item")
    except DialectCheckError as exc:
        print(json.dumps({"card_id": CARD_ID, "code": exc.code, "error": str(exc)}), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(_main())
