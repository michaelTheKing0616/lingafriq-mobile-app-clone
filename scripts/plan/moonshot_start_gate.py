#!/usr/bin/env python3
"""RM-STOP-01 moonshot start gate (P13-004). Refuses moonshot card promotion without proof."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence

CARD_ID = "P13-004"

_REPO_ROOT = Path(__file__).resolve().parents[2]
_CARD_STATUS = _REPO_ROOT / "docs/plan/CARD_STATUS.tsv"
_REPO_MAP = _REPO_ROOT / "docs/build/REPO_MAP.md"
_EVIDENCE = _REPO_ROOT / "docs/build/moonshot/rm_stop_01_evidence.json"
_ADR = _REPO_ROOT / "docs/build/adr/ADR-037-moonshot-start-gate.md"

MOONSHOT_CARD_IDS: frozenset[str] = frozenset(
    {
        "P13-005",
        "P13-006",
        "P13-007",
        "P13-008",
        "P13-009",
        "P13-010",
        "P13-011",
    }
)

BLOCKED_TARGET_STATUSES: frozenset[str] = frozenset(
    {"Ready", "Spec-Tests", "Build", "Test", "Review", "Done"}
)

FEATURE_ID_RE = re.compile(r"^F-(\d{3})$")
FEATURE_ROW_RE = re.compile(
    r"^\|\s*`(F-\d{3})`\s*\|[^|]+\|[^|]+\|[^|]+\|\s*(reachable|unreachable)\s*\|",
    re.IGNORECASE,
)


class MoonshotStartGateError(Exception):
    """Moonshot promotion blocked (RM-STOP-01)."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class RmStop01Assessment:
    feature_cards_total: int
    feature_cards_done: int
    feature_cards_unreachable: int
    tope_signed_off: bool
    satisfied: bool
    reasons: tuple[str, ...]


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def load_card_status_rows(path: Path = _CARD_STATUS) -> list[tuple[str, str]]:
    rows: list[tuple[str, str]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip() or line.startswith("id\t"):
            continue
        parts = line.split("\t", 2)
        if len(parts) < 2:
            continue
        rows.append((parts[0].strip(), parts[1].strip()))
    return rows


def count_feature_completion(rows: Sequence[tuple[str, str]]) -> tuple[int, int]:
    total = 0
    done = 0
    for card_id, status in rows:
        if not FEATURE_ID_RE.match(card_id):
            continue
        total += 1
        if status == "Done":
            done += 1
    return total, done


def count_unreachable_features(repo_map: Path = _REPO_MAP) -> int:
    if not repo_map.is_file():
        return 151
    unreachable = 0
    in_features = False
    for line in repo_map.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Features F-001"):
            in_features = True
            continue
        if in_features and line.startswith("## "):
            break
        if not in_features:
            continue
        match = FEATURE_ROW_RE.match(line)
        if match and match.group(2).casefold() == "unreachable":
            unreachable += 1
    return unreachable


def load_evidence(path: Path = _EVIDENCE) -> dict[str, Any]:
    if not path.is_file():
        raise MoonshotStartGateError("EVIDENCE_MISSING", f"missing evidence file: {path}")
    doc = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(doc, dict):
        raise MoonshotStartGateError("EVIDENCE_INVALID", "evidence root must be object")
    return doc


def assess_rm_stop_01(
    *,
    card_status: Path = _CARD_STATUS,
    repo_map: Path = _REPO_MAP,
    evidence: Path = _EVIDENCE,
) -> RmStop01Assessment:
    rows = load_card_status_rows(card_status)
    total, done = count_feature_completion(rows)
    unreachable = count_unreachable_features(repo_map)
    ev = load_evidence(evidence)
    tope_signed_off = bool(ev.get("tope_signed_off"))
    reasons: list[str] = []
    if total != 151:
        reasons.append(f"FEATURE_CARD_COUNT_{total}_NOT_151")
    if done != 151:
        reasons.append(f"FEATURES_NOT_DONE_{done}_OF_151")
    if unreachable != 0:
        reasons.append(f"FEATURES_UNREACHABLE_{unreachable}")
    if not tope_signed_off:
        reasons.append("TOPE_SIGN_OFF_PENDING")
    satisfied = not reasons
    return RmStop01Assessment(
        feature_cards_total=total,
        feature_cards_done=done,
        feature_cards_unreachable=unreachable,
        tope_signed_off=tope_signed_off,
        satisfied=satisfied,
        reasons=tuple(reasons),
    )


def refresh_evidence(
    *,
    card_status: Path = _CARD_STATUS,
    repo_map: Path = _REPO_MAP,
    evidence: Path = _EVIDENCE,
) -> dict[str, Any]:
    assessment = assess_rm_stop_01(
        card_status=card_status, repo_map=repo_map, evidence=evidence
    )
    doc = load_evidence(evidence)
    doc["feature_cards_total"] = assessment.feature_cards_total
    doc["feature_cards_done"] = assessment.feature_cards_done
    doc["feature_cards_unreachable"] = assessment.feature_cards_unreachable
    doc["rm_stop_01_satisfied"] = assessment.satisfied
    doc["refreshed_at"] = _utc_now_iso()
    evidence.parent.mkdir(parents=True, exist_ok=True)
    evidence.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    return doc


def assert_moonshot_status_allowed(
    card_id: str,
    target_status: str,
    *,
    assessment: RmStop01Assessment | None = None,
) -> None:
    if card_id not in MOONSHOT_CARD_IDS:
        return
    if target_status not in BLOCKED_TARGET_STATUSES:
        return
    if assessment is None:
        assessment = assess_rm_stop_01()
    if assessment.satisfied:
        return
    reason = ";".join(assessment.reasons) or "RM_STOP_01_OPEN"
    raise MoonshotStartGateError(
        "MOONSHOT_START_REFUSED",
        f"{card_id} cannot move to {target_status}: {reason}",
    )


def log_refusal(card_id: str, target_status: str, assessment: RmStop01Assessment) -> None:
    doc = load_evidence()
    log = doc.get("refusal_log")
    if not isinstance(log, list):
        log = []
    log.append(
        {
            "at": _utc_now_iso(),
            "card_id": card_id,
            "target_status": target_status,
            "reasons": list(assessment.reasons),
        }
    )
    doc["refusal_log"] = log[-50:]
    _EVIDENCE.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")


def try_status_change(card_id: str, target_status: str) -> dict[str, Any]:
    assessment = assess_rm_stop_01()
    try:
        assert_moonshot_status_allowed(card_id, target_status, assessment=assessment)
        return {"ok": True, "card_id": card_id, "target_status": target_status}
    except MoonshotStartGateError as exc:
        log_refusal(card_id, target_status, assessment)
        return {
            "ok": False,
            "code": exc.code,
            "message": str(exc),
            "reasons": list(assessment.reasons),
        }


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="RM-STOP-01 moonshot start gate (P13-004)")
    parser.add_argument("--refresh", action="store_true", help="Rewrite rm_stop_01_evidence.json metrics")
    parser.add_argument("--gate", action="store_true", help="Exit 1 if RM-STOP-01 not satisfied (CI)")
    parser.add_argument("--card", help="Moonshot card id to simulate promotion")
    parser.add_argument("--to", dest="target_status", default="Ready", help="Target status (default Ready)")
    args = parser.parse_args(list(argv) if argv is not None else None)

    if not _ADR.is_file():
        print("ADR-037 missing", file=sys.stderr)
        return 1

    if args.refresh:
        refresh_evidence()
        print(json.dumps(load_evidence(), indent=2))
        return 0

    if args.card:
        result = try_status_change(args.card.strip(), args.target_status.strip())
        print(json.dumps(result, indent=2))
        return 0 if result["ok"] else 1

    assessment = assess_rm_stop_01()
    if args.gate:
        if assessment.satisfied:
            return 0
        print(";".join(assessment.reasons), file=sys.stderr)
        return 1

    print(
        json.dumps(
            {
                "rm_stop_01_satisfied": assessment.satisfied,
                "feature_cards_done": assessment.feature_cards_done,
                "feature_cards_unreachable": assessment.feature_cards_unreachable,
                "tope_signed_off": assessment.tope_signed_off,
                "reasons": list(assessment.reasons),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
