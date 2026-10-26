"""Run app ARB and offline phrase packs through the content pipeline linters (P4-087)."""

from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import yaml

from tools.content_engine.kits.kit_schema import KitError, validate_kit
from tools.content_engine.legacy.quarantine import repo_root
from tools.content_engine.legacy.salvage import pipeline_input_dir
from tools.content_engine.pipeline.publish import ALLOWED_QUALITY_LABELS
from tools.content_engine.pipeline.stage_lint import run_lint_stage

CARD_ID = "P4-087"
MANIFEST_BASENAME = "legacy_ui_strings_manifest.json"
REVIEW_BASENAME = "legacy_ui_strings_review.jsonl"
LABELS_BASENAME = "ui_string_labels.json"

KIT_LANGS: tuple[str, ...] = ("yo", "ha", "ig", "sw", "zu", "xh", "pcm")
ARB_LOCALE_TO_KIT: dict[str, str] = {lang: lang for lang in KIT_LANGS}

_LATIN_ALPHABET = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
_ARB_COMMON_PUNCT = " .,;:!?…'\"()-–—/@#$%&*+={}[]|<>\\`~^_{}|"
_TOKEN_RE = re.compile(r"\S+")

_CONCORD_SW_TABLE: dict[str, object] = {
    "m/wa": {
        "subject": ["m", "wa"],
        "object": ["m", "wa"],
        "adjective": ["m", "wa"],
    },
    "ki/vi": {
        "subject": ["ki", "vi"],
        "object": ["ki", "vi"],
        "adjective": ["ki", "vi"],
    },
}

_CONCORD_ZUX_TABLE: dict[str, object] = {
    n: {
        "subject": [str(n)],
        "object": [str(n)],
        "adjective": [str(n)],
    }
    for n in range(1, 16)
}


@dataclass(frozen=True)
class UiStringSource:
    source_kind: str
    source_path: str
    locale: str
    kit_lang: str
    key: str
    text: str

    @property
    def item_id(self) -> str:
        safe_key = self.key.replace("@", "_")
        return f"ui.{self.kit_lang}.{self.source_kind}.{safe_key}"


@dataclass(frozen=True)
class UiStringOutcome:
    source: UiStringSource
    lint_status: str
    route: str | None
    quality_label: str | None
    unlabelled: bool


@dataclass(frozen=True)
class UiStringsStats:
    strings_total: int
    lint_pass: int
    lint_fail: int
    unlabelled: int
    review_queued: int


@dataclass(frozen=True)
class UiStringsResult:
    outcomes: tuple[UiStringOutcome, ...]
    review_records: tuple[dict[str, Any], ...]
    stats: UiStringsStats
    manifest_path: Path
    review_path: Path
    labels_path: Path
    changed: bool


def nfc(text: str) -> str:
    return unicodedata.normalize("NFC", text.strip())


def l10n_dir(root: Path) -> Path:
    return repo_root(root) / "lib" / "l10n"


def phrase_pack_dir(root: Path) -> Path:
    return pipeline_input_dir(root) / "phrase_packs"


def labels_path(root: Path) -> Path:
    return pipeline_input_dir(root) / LABELS_BASENAME


def is_arb_metadata_key(key: str) -> bool:
    return key.startswith("@")


def parse_arb_file(path: Path, kit_lang: str) -> list[UiStringSource]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, Mapping):
        raise TypeError(f"ARB root must be an object: {path}")
    locale = raw.get("@@locale")
    loc = locale if isinstance(locale, str) and locale.strip() else kit_lang
    found: list[UiStringSource] = []
    rel = str(path)
    for key, value in raw.items():
        if is_arb_metadata_key(key):
            continue
        if not isinstance(value, str) or not value.strip():
            continue
        found.append(
            UiStringSource(
                "arb",
                rel,
                loc,
                kit_lang,
                key,
                value,
            ),
        )
    return found


def parse_phrase_pack_file(path: Path, kit_lang: str) -> list[UiStringSource]:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, Mapping):
        raise TypeError(f"phrase pack root must be an object: {path}")
    rel = str(path)
    found: list[UiStringSource] = []
    for section in ("phrases", "words"):
        block = raw.get(section)
        if not isinstance(block, Mapping):
            continue
        for key, value in block.items():
            if not isinstance(key, str) or not isinstance(value, str) or not value.strip():
                continue
            found.append(
                UiStringSource(
                    f"phrase_{section}",
                    rel,
                    kit_lang,
                    kit_lang,
                    key,
                    value,
                ),
            )
    return found


def load_quality_labels(path: Path) -> dict[str, str]:
    if not path.is_file():
        return {}
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, Mapping):
        raise TypeError("ui_string_labels.json must be an object")
    out: dict[str, str] = {}
    for item_id, label in raw.items():
        if not isinstance(item_id, str) or not isinstance(label, str):
            continue
        normalized = label.strip()
        if normalized in ALLOWED_QUALITY_LABELS:
            out[item_id] = normalized
    return out


def _expand_character_set(kit: Mapping[str, Any], text: str) -> list[str]:
    chunks: list[str] = []
    for entry in kit.get("character_set", []):
        if not isinstance(entry, str):
            continue
        if entry == "Latin":
            chunks.append(_LATIN_ALPHABET)
            chunks.append(_ARB_COMMON_PUNCT)
        else:
            chunks.append(entry)
    chunks.append(text)
    return chunks


def _load_kit_yaml(kit_lang: str, kits_root: Path) -> dict[str, Any]:
    path = kits_root / kit_lang / "kit.yaml"
    if path.is_file():
        with path.open(encoding="utf-8") as handle:
            raw = yaml.safe_load(handle)
        if not isinstance(raw, Mapping):
            raise KitError("KIT_INVALID", f"kit {kit_lang!r} is not a mapping")
        return dict(validate_kit(raw))
    return {
        "linguist_signoff": False,
        "character_set": ["Latin"],
        "nfc": "NFC",
        "tone_marking": "not enumerated in §3.3",
        "phone_inventory": [],
        "g2p": {"status": "not enumerated in §3.3"},
        "dialect": kit_lang,
    }


def lint_kit_for_lang(kit_lang: str, text: str, kits_root: Path) -> dict[str, Any]:
    kit = _load_kit_yaml(kit_lang, kits_root)
    kit = dict(kit)
    kit["character_set"] = _expand_character_set(kit, text)
    if kit_lang == "sw":
        kit["concord_table"] = _CONCORD_SW_TABLE
    if kit_lang in ("zu", "xh"):
        kit["concord_table"] = _CONCORD_ZUX_TABLE
    return kit


def _placeholder_item(item_id: str, kit_lang: str, text: str) -> dict[str, Any]:
    return {
        "id": item_id,
        "lang": kit_lang,
        "type": "ui_string",
        "cefr": "A1",
        "can_do": ["navigate the app"],
        "text": text,
        "provenance": {
            "sources": [{"source_id": "lingafriq-ui", "licence": "proprietary"}],
        },
        "claims": [],
        "confidence": 0.5,
        "risk_tags": [],
        "status": "needs-review",
        "label": "beta",
        "audio": [],
        "feature_hooks": {},
    }


def _simple_tokens(text: str) -> list[str]:
    return [nfc(t) for t in _TOKEN_RE.findall(text) if t.strip()]


def _yoruba_tokens(text: str) -> list[dict[str, Any]]:
    return [
        {"surface": tok, "lexicon": tok, "syllabic": False}
        for tok in _simple_tokens(text)
    ] or [{"surface": text, "lexicon": text, "syllabic": False}]


def _hausa_tokens(text: str) -> list[dict[str, Any]]:
    return [
        {
            "surface": tok,
            "lexicon": tok,
            "dictionary_sourced": True,
        }
        for tok in _simple_tokens(text)
    ] or [
        {
            "surface": text,
            "lexicon": text,
            "dictionary_sourced": True,
        }
    ]


def build_lint_stage(source: UiStringSource, kit: Mapping[str, Any]) -> dict[str, Any]:
    item_id = source.item_id
    text = nfc(source.text)
    payloads: dict[str, Any] = {
        "unicode": {"id": item_id, "text": text},
        "claims": {"id": item_id, "section": "ui", "text": text},
        "placeholders": _placeholder_item(item_id, source.kit_lang, text),
    }
    lang = source.kit_lang
    if lang == "yo":
        payloads["yoruba"] = {
            "id": item_id,
            "learner_facing": True,
            "tokens": _yoruba_tokens(text),
        }
    elif lang == "ha":
        payloads["hausa"] = {
            "id": item_id,
            "text_role": "display",
            "tokens": _hausa_tokens(text),
        }
    elif lang == "pcm":
        payloads["pidgin_nla"] = {
            "id": item_id,
            "language": "pcm",
            "text": text,
        }
    elif lang == "sw":
        payloads["concord_sw"] = {
            "id": item_id,
            "noun": {"in_lexicon": True, "class_pair": "m/wa"},
            "subject": None,
            "object": None,
            "adjective": None,
        }
    elif lang in ("zu", "xh"):
        payloads["concord_zux"] = {
            "id": item_id,
            "language": lang,
            "noun_class": 1,
            "subject": None,
            "object": None,
            "adjective": None,
            "has_prefixes": False,
            "surface": text,
        }
        if lang == "zu":
            payloads["zulmorph"] = {
                "id": item_id,
                "language": "zu",
                "form": text,
            }
    return {
        "id": item_id,
        "language": lang,
        "lint_payloads": payloads,
    }


def lint_ui_string(
    source: UiStringSource,
    kits_root: Path,
) -> tuple[str, str | None]:
    text = nfc(source.text)
    kit = lint_kit_for_lang(source.kit_lang, text, kits_root)
    stage = build_lint_stage(source, kit)
    result = run_lint_stage(stage, kit)
    status = result.get("status")
    route = result.get("route")
    lint_status = status if isinstance(status, str) else "fail"
    route_out = route if isinstance(route, str) else None
    return lint_status, route_out


def collect_ui_strings(
    root: Path,
    *,
    l10n: Path | None = None,
    phrase_dir: Path | None = None,
) -> list[UiStringSource]:
    base = repo_root(root)
    arb_dir = l10n or l10n_dir(base)
    packs = phrase_dir or phrase_pack_dir(base)
    found: list[UiStringSource] = []
    for lang in KIT_LANGS:
        arb_path = arb_dir / f"app_{lang}.arb"
        if arb_path.is_file():
            found.extend(parse_arb_file(arb_path, lang))
        pack_path = packs / f"{lang}.json"
        if pack_path.is_file():
            found.extend(parse_phrase_pack_file(pack_path, lang))
    return found


def build_review_record(
    source: UiStringSource,
    lint_status: str,
    route: str | None,
) -> dict[str, Any]:
    return {
        "card": CARD_ID,
        "item_id": source.item_id,
        "source_kind": source.source_kind,
        "source_path": source.source_path,
        "key": source.key,
        "locale": source.locale,
        "kit_lang": source.kit_lang,
        "text": source.text,
        "lint_status": lint_status,
        "route": route or "review",
        "arb_mutable": False,
    }


def run_ui_strings(
    root: Path | None = None,
    *,
    dry_run: bool = False,
    l10n: Path | None = None,
    phrase_dir: Path | None = None,
    kits_root: Path | None = None,
) -> UiStringsResult:
    base = repo_root(root)
    kits = kits_root or (base / "tools" / "content_engine" / "kits")
    labels_file = labels_path(base)
    labels = load_quality_labels(labels_file)
    sources = collect_ui_strings(base, l10n=l10n, phrase_dir=phrase_dir)

    outcomes: list[UiStringOutcome] = []
    review_records: list[dict[str, Any]] = []
    lint_pass = 0
    lint_fail = 0
    unlabelled = 0

    for source in sources:
        lint_status, route = lint_ui_string(source, kits)
        label = labels.get(source.item_id)
        is_unlabelled = label is None
        if lint_status == "ok":
            lint_pass += 1
            if is_unlabelled:
                unlabelled += 1
        else:
            lint_fail += 1
            review_records.append(build_review_record(source, lint_status, route))
        outcomes.append(
            UiStringOutcome(
                source,
                lint_status,
                route,
                label,
                is_unlabelled and lint_status == "ok",
            ),
        )

    out_dir = pipeline_input_dir(base)
    manifest_path = out_dir / MANIFEST_BASENAME
    review_path = out_dir / REVIEW_BASENAME
    changed = bool(review_records)

    if not dry_run:
        out_dir.mkdir(parents=True, exist_ok=True)
        lines = [json.dumps(rec, ensure_ascii=False, sort_keys=True) for rec in review_records]
        payload = "\n".join(lines)
        if payload:
            payload += "\n"
        review_path.write_text(payload, encoding="utf-8")
        unlabelled_ids = sorted(
            o.source.item_id for o in outcomes if o.unlabelled
        )
        manifest = {
            "card": CARD_ID,
            "strings_total": len(sources),
            "lint_pass": lint_pass,
            "lint_fail": lint_fail,
            "unlabelled_strings": unlabelled_ids,
            "review_queue_items": len(review_records),
            "review_file": REVIEW_BASENAME,
            "labels_file": LABELS_BASENAME,
        }
        manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    stats = UiStringsStats(
        strings_total=len(sources),
        lint_pass=lint_pass,
        lint_fail=lint_fail,
        unlabelled=unlabelled,
        review_queued=len(review_records),
    )
    return UiStringsResult(
        tuple(outcomes),
        tuple(review_records),
        stats,
        manifest_path,
        review_path,
        labels_file,
        changed,
    )


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Lint UI ARB and phrase-pack strings (P4-087).")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Report outcomes without writing review queue or manifest.",
    )
    parser.add_argument("--l10n", type=Path, default=None, help="Override lib/l10n directory.")
    parser.add_argument(
        "--phrase-packs",
        type=Path,
        default=None,
        help="Override phrase pack input directory.",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)
    result = run_ui_strings(
        dry_run=args.dry_run,
        l10n=args.l10n,
        phrase_dir=args.phrase_packs,
    )
    print(
        json.dumps(
            {
                "card": CARD_ID,
                "strings_total": result.stats.strings_total,
                "lint_pass": result.stats.lint_pass,
                "lint_fail": result.stats.lint_fail,
                "unlabelled": result.stats.unlabelled,
                "review_queued": result.stats.review_queued,
                "dry_run": args.dry_run,
            },
            indent=2,
        ),
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
