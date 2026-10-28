"""Block later-wave languages beyond L0 without a lexicon source (P13-003, CURRICULUM §2.4)."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any, Mapping, MutableMapping

from scripts.content.later_wave_admission import load_admission_file, load_licence_register
from tools.content_pipeline.readiness import READINESS_LEVELS

CARD_ID = "P13-003"

_REPO_ROOT = Path(__file__).resolve().parents[2]

_LEXICON_LICENCE_MARKERS = (
    "cc by",
    "cc-by",
    "public domain",
    "pd",
    "cc0",
    "us government",
)

_LEVEL_ORDER = {level: index for index, level in enumerate(READINESS_LEVELS)}


class LexiconGateError(Exception):
    """Lexicon gate blocked promotion or reconciliation."""

    def __init__(self, code: str, message: str, *, language_id: str | None = None) -> None:
        self.code = code
        self.language_id = language_id
        super().__init__(message)


def _language_id_from_admission(doc: Mapping[str, Any]) -> str:
    lang = doc.get("language_id")
    if not isinstance(lang, str) or not lang.strip() or "{{" in lang:
        raise LexiconGateError("LANGUAGE_ID_MISSING", "admission language_id must be set")
    return lang.strip().lower()


def _licence_ok(licence: str) -> bool:
    lower = licence.lower()
    return any(marker in lower for marker in _LEXICON_LICENCE_MARKERS)


def _register_row(register_id: str, rows: list[Mapping[str, Any]]) -> Mapping[str, Any] | None:
    for row in rows:
        if row.get("id") == register_id:
            return row
    return None


def _register_usable(row: Mapping[str, Any]) -> bool:
    use = row.get("use")
    if not isinstance(use, str):
        return True
    lower = use.casefold()
    if "exclude" in lower or lower.strip() == "discovery_only":
        return False
    return True


def assess_lexicon_source(
    admission_doc: Mapping[str, Any],
    *,
    register_rows: list[Mapping[str, Any]],
) -> dict[str, Any]:
    """
    Return whether the admission file documents a licensed or public-domain lexicon source.
    """
    language_id = _language_id_from_admission(admission_doc)
    admission = admission_doc.get("admission")
    if not isinstance(admission, Mapping):
        return {
            "language_id": language_id,
            "ok": False,
            "code": "ADMISSION_MISSING",
            "message": "admission object required",
        }

    entry = admission.get("lexicon")
    if not isinstance(entry, Mapping):
        return {
            "language_id": language_id,
            "ok": False,
            "code": "LEXICON_SOURCE_MISSING",
            "message": f"language {language_id} has no lexicon source in admission file",
        }

    title = entry.get("title")
    licence = entry.get("licence")
    register_id = entry.get("register_id")
    if not isinstance(title, str) or not title.strip():
        return {
            "language_id": language_id,
            "ok": False,
            "code": "LEXICON_SOURCE_MISSING",
            "message": f"language {language_id} has no lexicon source in admission file",
        }
    if not isinstance(licence, str) or not licence.strip():
        return {
            "language_id": language_id,
            "ok": False,
            "code": "LEXICON_LICENCE_MISSING",
            "message": f"language {language_id} lexicon licence is empty",
        }
    if not isinstance(register_id, str) or not register_id.strip():
        return {
            "language_id": language_id,
            "ok": False,
            "code": "LEXICON_REGISTER_MISSING",
            "message": f"language {language_id} lexicon register_id is empty",
        }

    rid = register_id.strip()
    if not _licence_ok(licence.strip()):
        return {
            "language_id": language_id,
            "ok": False,
            "code": "LEXICON_LICENCE_INVALID",
            "message": f"language {language_id} lexicon licence is not licensed or public domain",
        }

    row = _register_row(rid, register_rows)
    if row is None:
        return {
            "language_id": language_id,
            "ok": False,
            "code": "LEXICON_REGISTER_REMOVED",
            "message": f"language {language_id} lexicon register_id {rid} is not in licence register",
        }
    if not _register_usable(row):
        return {
            "language_id": language_id,
            "ok": False,
            "code": "LEXICON_REGISTER_EXCLUDED",
            "message": f"language {language_id} lexicon register row {rid} is not shippable",
        }

    return {
        "language_id": language_id,
        "ok": True,
        "code": None,
        "message": "lexicon source present",
        "register_id": rid,
        "title": title.strip(),
    }


def is_above_l0(level: str) -> bool:
    if level not in _LEVEL_ORDER:
        raise LexiconGateError("LEVEL_INVALID", f"unknown readiness level {level}")
    return _LEVEL_ORDER[level] > 0


def assert_promotion_above_l0_allowed(
    admission_doc: Mapping[str, Any],
    *,
    target_readiness_level: str,
    register_rows: list[Mapping[str, Any]],
) -> None:
    """AC1/AC2: lexicon required for promotion targets above L0."""
    if not is_above_l0(target_readiness_level):
        return
    assessment = assess_lexicon_source(admission_doc, register_rows=register_rows)
    if assessment["ok"]:
        return
    language_id = assessment["language_id"]
    code = str(assessment["code"] or "LEXICON_SOURCE_MISSING")
    if code == "LEXICON_SOURCE_MISSING":
        raise LexiconGateError(
            code,
            f"language {language_id} cannot promote above L0 without a lexicon source",
            language_id=language_id,
        )
    raise LexiconGateError(
        code,
        str(assessment["message"]),
        language_id=language_id,
    )


def reconcile_readiness_after_lexicon_check(
    manifest: MutableMapping[str, Any],
    admission_doc: Mapping[str, Any],
    *,
    register_rows: list[Mapping[str, Any]],
) -> dict[str, Any]:
    """
    AC3: demote languages to L0 and flag when the lexicon source is no longer valid.
    """
    language_id = _language_id_from_admission(admission_doc)
    current = manifest.get("readiness_level", "L0")
    if current not in READINESS_LEVELS:
        raise LexiconGateError("LEVEL_INVALID", "manifest readiness_level must be L0–L3")

    assessment = assess_lexicon_source(admission_doc, register_rows=register_rows)
    if assessment["ok"]:
        return {
            "card_id": CARD_ID,
            "language_id": language_id,
            "demoted": False,
            "readiness_level": current,
            "lexicon_ok": True,
        }

    demoted = False
    if is_above_l0(str(current)):
        manifest["readiness_level"] = "L0"
        flags = manifest.setdefault("lexicon_gate_flags", [])
        if not isinstance(flags, list):
            flags = []
            manifest["lexicon_gate_flags"] = flags
        flag = {
            "code": assessment["code"],
            "message": assessment["message"],
            "card_id": CARD_ID,
        }
        if flag not in flags:
            flags.append(flag)
        demoted = True

    return {
        "card_id": CARD_ID,
        "language_id": language_id,
        "demoted": demoted,
        "readiness_level": manifest.get("readiness_level"),
        "lexicon_ok": False,
        "code": assessment["code"],
        "flagged": demoted or bool(manifest.get("lexicon_gate_flags")),
    }


def gate_promotion_request(
    manifest: MutableMapping[str, Any],
    admission_doc: Mapping[str, Any],
    *,
    target_readiness_level: str,
    register_rows: list[Mapping[str, Any]],
) -> dict[str, Any]:
    """Run lexicon gate before other promotion gates (AC2: other gates still run when lexicon passes)."""
    assert_promotion_above_l0_allowed(
        admission_doc,
        target_readiness_level=target_readiness_level,
        register_rows=register_rows,
    )
    return {
        "card_id": CARD_ID,
        "language_id": _language_id_from_admission(admission_doc),
        "lexicon_gate_passed": True,
        "target_readiness_level": target_readiness_level,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Later-wave lexicon gate (P13-003)")
    sub = parser.add_subparsers(dest="command", required=True)

    assess = sub.add_parser("assess", help="Assess lexicon source from admission YAML")
    assess.add_argument("admission", type=Path)
    assess.add_argument(
        "--register",
        type=Path,
        default=_REPO_ROOT / "curriculum/sources/licence_register.json",
    )

    promote = sub.add_parser("promote-check", help="Fail if target level > L0 without lexicon")
    promote.add_argument("admission", type=Path)
    promote.add_argument("target_level", choices=list(READINESS_LEVELS))
    promote.add_argument("--register", type=Path, default=_REPO_ROOT / "curriculum/sources/licence_register.json")

    reconcile = sub.add_parser("reconcile", help="Demote manifest to L0 when lexicon invalid")
    reconcile.add_argument("admission", type=Path)
    reconcile.add_argument("manifest", type=Path)
    reconcile.add_argument("--register", type=Path, default=_REPO_ROOT / "curriculum/sources/licence_register.json")
    reconcile.add_argument("-o", "--output", type=Path, help="write updated manifest JSON")

    args = parser.parse_args(argv)
    rows = load_licence_register(args.register)

    if args.command == "assess":
        doc = load_admission_file(args.admission)
        result = assess_lexicon_source(doc, register_rows=rows)
        print(json.dumps(result, indent=2))
        return 0 if result["ok"] else 1

    if args.command == "promote-check":
        doc = load_admission_file(args.admission)
        try:
            assert_promotion_above_l0_allowed(
                doc,
                target_readiness_level=args.target_level,
                register_rows=rows,
            )
        except LexiconGateError as exc:
            print(json.dumps({"ok": False, "code": exc.code, "message": str(exc)}, indent=2))
            return 1
        print(json.dumps({"ok": True}, indent=2))
        return 0

    if args.command == "reconcile":
        doc = load_admission_file(args.admission)
        manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
        if not isinstance(manifest, dict):
            raise SystemExit("manifest must be a JSON object")
        result = reconcile_readiness_after_lexicon_check(manifest, doc, register_rows=rows)
        if args.output:
            args.output.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, indent=2))
        return 0

    return 2


if __name__ == "__main__":
    raise SystemExit(main())
