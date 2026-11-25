"""Pidgin corpus anchoring and rule-based anglicisation checks (P5-040, CURRICULUM §6)."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from functools import lru_cache
from pathlib import Path
from typing import Any, Mapping, Sequence

import yaml

from tools.content.placeholder_linter import repo_root
from tools.content_engine.linters.pidgin_nla import lint_pidgin_nla

CARD_ID = "P5-040"
LANGUAGE = "pcm"
REGISTER_UD_NAIJA = "register:ud-naija-nsc"
CORPUS_NSC_ID = "nsc-speech"

CODE_CORPUS_UNANCHORED = "CorpusUnanchored"
CODE_NSC_UNVERIFIED = "NscCorpusUnverified"
CODE_ANGLICISED = "AnglicisedPidgin"
CODE_NATIVE_QUEUE_BLOCKED = "NativeValidatorsUnavailable"

RULE_PA001 = "PA-001"
RULE_PA002 = "PA-002"
RULE_PA003 = "PA-003"

_PCM_PRIORITY_RANK = 0
_OTHER_LANG_PRIORITY_RANK = 50

_ANGLICISED_EN_RE = re.compile(
    r"\b(will|shall|would|should|going\s+to|gonna|have\s+been|has\s+been|had\s+been)\b",
    re.IGNORECASE,
)

_ANCHOR_ASSET_PATHS: tuple[str, ...] = (
    "assets/data/patterns/pcm.json",
    "assets/data/units/register/pcm.json",
)

_KIT_PATH = "tools/content_engine/kits/pcm/kit.yaml"


class PidginCheckError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class PidginFinding:
    code: str
    rule_id: str
    item_id: str
    detail: str


def language_id_from_item_id(item_id: str) -> str | None:
    if not isinstance(item_id, str) or "." not in item_id:
        return None
    return item_id.split(".", 1)[0].strip().lower() or None


def _normalize_phrase(text: str) -> str:
    return " ".join(text.strip().lower().split())


def _provenance_register_ids(item: Mapping[str, Any]) -> frozenset[str]:
    keys: set[str] = set()
    provenance = item.get("provenance")
    if not isinstance(provenance, Mapping):
        return frozenset(keys)
    for source in provenance.get("sources") or []:
        if not isinstance(source, Mapping):
            continue
        citation = source.get("uri_or_citation")
        if isinstance(citation, str):
            for part in citation.split(";"):
                part = part.strip()
                if part.startswith("register:"):
                    keys.add(part)
        name = source.get("name")
        if isinstance(name, str) and name.strip():
            keys.add(name.strip())
    return frozenset(keys)


def _claims_source_refs(item: Mapping[str, Any]) -> frozenset[str]:
    refs: set[str] = set()
    for claim in item.get("claims") or []:
        if not isinstance(claim, Mapping):
            continue
        ref = claim.get("source_ref")
        if isinstance(ref, str) and ref.strip():
            refs.add(ref.strip())
    return frozenset(refs)


def _collect_strings(node: Any, out: set[str]) -> None:
    if isinstance(node, str) and node.strip():
        out.add(node.strip())
        return
    if isinstance(node, Mapping):
        for value in node.values():
            _collect_strings(value, out)
        return
    if isinstance(node, list):
        for value in node:
            _collect_strings(value, out)


@lru_cache(maxsize=1)
def load_ud_naija_anchor_phrases(root: str) -> frozenset[str]:
    """Phrases from UD-Naija–registered curriculum assets (evidence only, CC BY-SA)."""
    base = Path(root)
    phrases: set[str] = set()
    for rel in _ANCHOR_ASSET_PATHS:
        path = base / rel
        if not path.is_file():
            continue
        with path.open(encoding="utf-8") as fh:
            data = json.load(fh)
        if rel.endswith("patterns/pcm.json"):
            for row in data.get("patterns") or []:
                if not isinstance(row, Mapping):
                    continue
                for example in row.get("examples") or []:
                    if isinstance(example, str) and example.strip():
                        phrases.add(example.strip())
        else:
            for unit in data.get("units") or []:
                if not isinstance(unit, Mapping):
                    continue
                for practice in unit.get("practice_items") or []:
                    if not isinstance(practice, Mapping):
                        continue
                    for option in practice.get("options") or []:
                        if isinstance(option, Mapping):
                            text = option.get("text")
                            if isinstance(text, str) and text.strip():
                                phrases.add(text.strip())
    return frozenset(_normalize_phrase(p) for p in phrases)


def load_pcm_kit(root: Path | None = None) -> Mapping[str, Any]:
    path = repo_root(root) / _KIT_PATH
    with path.open(encoding="utf-8") as fh:
        data = yaml.safe_load(fh)
    if not isinstance(data, Mapping):
        raise PidginCheckError("KIT_INVALID", f"{_KIT_PATH} must be a mapping")
    return data


def _nsc_evidence_allowed(kit: Mapping[str, Any]) -> bool:
    corpora = kit.get("corpora")
    if not isinstance(corpora, list):
        return False
    for row in corpora:
        if not isinstance(row, Mapping):
            continue
        if row.get("id") != CORPUS_NSC_ID:
            continue
        return row.get("licence_status") == "verified" and row.get("evidence") is True
    return False


def corpus_anchor_ok(
    item: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> tuple[bool, str]:
    """AC1: UD-Naija register citation or phrase overlap with registered anchor set."""
    item_id = item.get("id")
    if not isinstance(item_id, str) or not item_id.strip():
        raise PidginCheckError("ITEM_INVALID", "id is required")
    lang = language_id_from_item_id(item_id)
    if lang != LANGUAGE:
        raise PidginCheckError("LANGUAGE_INVALID", f"expected {LANGUAGE}, got {lang!r}")

    refs = _provenance_register_ids(item) | _claims_source_refs(item)
    if REGISTER_UD_NAIJA in refs:
        return True, REGISTER_UD_NAIJA
    if any("ud-naija" in r.lower() for r in refs):
        return True, "provenance:ud-naija"

    kit = load_pcm_kit(root)
    if CORPUS_NSC_ID in refs or any(CORPUS_NSC_ID in r for r in refs):
        if not _nsc_evidence_allowed(kit):
            raise PidginCheckError(
                CODE_NSC_UNVERIFIED,
                f"{CORPUS_NSC_ID} is not verified for evidence in {_KIT_PATH}",
            )
        return True, CORPUS_NSC_ID

    text = extract_display_text(item)
    norm = _normalize_phrase(text)
    anchors = load_ud_naija_anchor_phrases(str(repo_root(root)))
    if norm in anchors:
        return True, "anchor:exact"
    for phrase in anchors:
        if phrase and (phrase in norm or norm in phrase):
            return True, "anchor:substring"
    return False, CODE_CORPUS_UNANCHORED


def extract_display_text(item: Mapping[str, Any]) -> str:
    if isinstance(item.get("text"), str) and item["text"].strip():
        return item["text"].strip()
    stimulus = item.get("stimulus")
    if isinstance(stimulus, Mapping):
        text = stimulus.get("text")
        if isinstance(text, str) and text.strip():
            return text.strip()
    answer = item.get("answer_spec")
    if isinstance(answer, Mapping):
        correct = answer.get("correct")
        if isinstance(correct, str) and correct.strip():
            return correct.strip()
    raise PidginCheckError("ITEM_INVALID", "no display text on item")


def detect_anglicisation(
    item: Mapping[str, Any],
    *,
    root: Path | None = None,
) -> list[PidginFinding]:
    """AC2: NLA english spellings (when table shipped) and English-modal anglicisation."""
    item_id = item.get("id")
    if not isinstance(item_id, str) or not item_id.strip():
        raise PidginCheckError("ITEM_INVALID", "id is required")
    text = extract_display_text(item)
    findings: list[PidginFinding] = []

    kit = load_pcm_kit(root)
    nla = lint_pidgin_nla(
        {"id": item_id, "language": LANGUAGE, "text": text},
        kit,
    )
    if nla.status == "fail" and nla.rule_id == "PCM_ENGLISH_SPELLING":
        findings.append(
            PidginFinding(
                CODE_ANGLICISED,
                RULE_PA002,
                item_id,
                f"english spelling {text[nla.span.start : nla.span.end]!r}; use NLA form {nla.nla_form!r}",
            )
        )

    if _ANGLICISED_EN_RE.search(text):
        findings.append(
            PidginFinding(
                CODE_ANGLICISED,
                RULE_PA002,
                item_id,
                "english modal or periphrastic future detected",
            )
        )
    return findings


def native_validation_priority(language_id: str) -> int:
    """AC3: Pidgin sorts ahead of other Stage-1 languages in native review queues."""
    return _PCM_PRIORITY_RANK if language_id.strip().lower() == LANGUAGE else _OTHER_LANG_PRIORITY_RANK


def schedule_native_validation(
    item: Mapping[str, Any],
    *,
    validators_ready: bool,
) -> dict[str, Any]:
    """Attach early native-check priority; EXT-13 gates live validator assignment."""
    item_id = item.get("id")
    if not isinstance(item_id, str) or not item_id.strip():
        raise PidginCheckError("ITEM_INVALID", "id is required")
    lang = language_id_from_item_id(item_id) or ""
    priority = native_validation_priority(lang)
    row: dict[str, Any] = {
        "card_id": CARD_ID,
        "item_id": item_id.strip(),
        "language_id": lang,
        "native_check_priority": lang == LANGUAGE,
        "queue_rank": priority,
    }
    if lang == LANGUAGE and not validators_ready:
        row["validators_blocked"] = True
        row["blocker"] = "EXT-13"
        row["code"] = CODE_NATIVE_QUEUE_BLOCKED
    else:
        row["validators_blocked"] = False
    return row


def validate_pcm_item(
    item: Mapping[str, Any],
    *,
    root: Path | None = None,
    validators_ready: bool = False,
) -> dict[str, Any]:
    findings: list[PidginFinding] = []
    anchored, anchor_detail = corpus_anchor_ok(item, root=root)
    if not anchored:
        item_id = str(item.get("id", "<unknown>"))
        findings.append(
            PidginFinding(
                CODE_CORPUS_UNANCHORED,
                RULE_PA001,
                item_id,
                "phrasing not anchored to UD-Naija register or licensed anchor phrases",
            )
        )
    findings.extend(detect_anglicisation(item, root=root))
    schedule = schedule_native_validation(item, validators_ready=validators_ready)
    return {
        "card_id": CARD_ID,
        "anchor_ok": anchored,
        "anchor_detail": anchor_detail,
        "findings": [f.__dict__ for f in findings],
        "schedule": schedule,
    }


def _parse_args(argv: Sequence[str] | None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Pidgin corpus anchor and anglicisation lint (P5-040)")
    parser.add_argument("item_json", help="path to item JSON file")
    parser.add_argument(
        "--validators-ready",
        action="store_true",
        help="set when EXT-13 native validators are contracted (default: blocked)",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = _parse_args(argv)
    path = Path(args.item_json)
    with path.open(encoding="utf-8") as fh:
        item = json.load(fh)
    if not isinstance(item, Mapping):
        print("item root must be an object", file=sys.stderr)
        return 2
    try:
        report = validate_pcm_item(item, validators_ready=args.validators_ready)
    except PidginCheckError as exc:
        print(f"{exc.code}: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(report, indent=2, sort_keys=True))
    if report["findings"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
