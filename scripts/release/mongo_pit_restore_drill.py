#!/usr/bin/env python3
"""P12-018: quarterly MongoDB Atlas point-in-time restore verification drill."""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Callable

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = ROOT / "release" / "mongo_pit_restore_config.json"
QUARTERLY_DAYS = 90


@dataclass
class CollectionCheck:
    name: str
    source_count: int
    restored_count: int

    @property
    def matched(self) -> bool:
        return self.source_count == self.restored_count

    def to_json(self) -> dict[str, Any]:
        return {
            "name": self.name,
            "source_count": self.source_count,
            "restored_count": self.restored_count,
            "matched": self.matched,
        }


@dataclass
class DrillReport:
    card: str = "P12-018"
    mode: str = "simulate"
    passed: bool = False
    p0_incident: bool = False
    tested_at: datetime | None = None
    restore_duration_ms: float | None = None
    pit_timestamp: str | None = None
    next_test_due: datetime | None = None
    collections: list[CollectionCheck] = field(default_factory=list)
    error: str | None = None
    notes: list[str] = field(default_factory=list)

    def to_json(self) -> dict[str, Any]:
        return {
            "card": self.card,
            "mode": self.mode,
            "passed": self.passed,
            "p0_incident": self.p0_incident,
            "tested_at": self.tested_at.isoformat() if self.tested_at else None,
            "restore_duration_ms": self.restore_duration_ms,
            "pit_timestamp": self.pit_timestamp,
            "next_test_due": self.next_test_due.isoformat() if self.next_test_due else None,
            "collections": [c.to_json() for c in self.collections],
            "error": self.error,
            "notes": self.notes,
        }


def load_config(path: Path) -> dict[str, Any]:
    payload = json.loads(path.read_text())
    names = payload.get("verify_collections")
    if not isinstance(names, list) or len(names) != 3:
        raise ValueError("verify_collections must list exactly 3 named collections")
    return payload


def compare_counts(
    collection_names: list[str],
    source_counts: dict[str, int],
    restored_counts: dict[str, int],
) -> list[CollectionCheck]:
    checks: list[CollectionCheck] = []
    for name in collection_names:
        src = int(source_counts.get(name, -1))
        rst = int(restored_counts.get(name, -1))
        checks.append(CollectionCheck(name=name, source_count=src, restored_count=rst))
    return checks


def _mongosh_count(uri: str, db_name: str, collection: str) -> int:
    script = f"db.getSiblingDB('{db_name}').getCollection('{collection}').countDocuments({{}})"
    proc = subprocess.run(
        ["mongosh", uri, "--quiet", "--eval", script],
        capture_output=True,
        text=True,
        check=False,
    )
    if proc.returncode != 0:
        raise RuntimeError(
            f"mongosh count failed for {collection}: {proc.stderr.strip() or proc.stdout}"
        )
    line = proc.stdout.strip().splitlines()[-1] if proc.stdout.strip() else ""
    try:
        return int(line)
    except ValueError as exc:
        raise RuntimeError(f"unexpected mongosh output for {collection}: {line}") from exc


def _default_db_from_uri(uri: str) -> str:
    # mongodb+srv://.../dbname?opts
    if "/" not in uri.split("?", 1)[0].rstrip("/").split("@")[-1]:
        return "lingafriq"
    tail = uri.split("@", 1)[-1]
    path = tail.split("/", 1)[1] if "/" in tail else ""
    db = path.split("?", 1)[0].strip("/")
    return db or "lingafriq"


def live_count_fn(uri: str) -> Callable[[str], int]:
    db = _default_db_from_uri(uri)

    def counter(collection: str) -> int:
        return _mongosh_count(uri, db, collection)

    return counter


def run_drill(
    config: dict[str, Any],
    *,
    mode: str = "simulate",
    now_fn: Callable[[], datetime] | None = None,
    restore_fn: Callable[[], None] | None = None,
    source_count_fn: Callable[[str], int] | None = None,
    restored_count_fn: Callable[[str], int] | None = None,
    pit_timestamp: str | None = None,
) -> DrillReport:
    now_fn = now_fn or (lambda: datetime.now(timezone.utc))
    names: list[str] = list(config["verify_collections"])
    interval = int(config.get("quarterly_interval_days", QUARTERLY_DAYS))
    tested = now_fn()
    report = DrillReport(mode=mode, tested_at=tested, pit_timestamp=pit_timestamp)
    report.next_test_due = tested + timedelta(days=interval)

    if mode == "simulate":
        fixture = {
            "user": 120_431,
            "reward_ledger": 88_204,
            "verified_lexicon_entries": 12_907,
        }
        source_count_fn = source_count_fn or (lambda c: fixture[c])
        restored_count_fn = restored_count_fn or (lambda c: fixture[c])
        report.restore_duration_ms = 1.0
        report.notes.append("simulated restore; no Atlas credentials required")
    elif mode == "live":
        harness = (
            restore_fn is not None
            and source_count_fn is not None
            and restored_count_fn is not None
        )
        env = config.get("atlas_env") or {}
        src_key = env.get("source_uri", "ATLAS_SOURCE_URI")
        rst_key = env.get("restored_uri", "ATLAS_RESTORED_URI")
        confirm_key = env.get("restore_confirmed", "ATLAS_RESTORE_CONFIRMED")
        pit_key = env.get("pit_timestamp", "ATLAS_PIT_TIMESTAMP")
        source_uri = os.environ.get(src_key, "")
        restored_uri = os.environ.get(rst_key, "")
        if not harness:
            if not source_uri or not restored_uri:
                report.error = "Atlas URIs not configured"
                report.p0_incident = True
                report.passed = False
                return report
            if os.environ.get(confirm_key, "") != "1":
                report.error = f"Set {confirm_key}=1 to run live restore drill"
                report.passed = False
                return report
        if pit_timestamp is None:
            pit_timestamp = os.environ.get(pit_key)
        report.pit_timestamp = pit_timestamp
        t0 = now_fn()
        try:
            if restore_fn is not None:
                restore_fn()
            else:
                subprocess.run(
                    [
                        "bash",
                        str(ROOT.parent / "node-backend" / "scripts" / "ops" / "atlas_restore_drill.sh"),
                    ],
                    check=True,
                    env=os.environ.copy(),
                )
        except (subprocess.CalledProcessError, OSError, RuntimeError) as exc:
            report.error = f"restore failed: {exc}"
            report.p0_incident = True
            report.passed = False
            return report
        t1 = now_fn()
        report.restore_duration_ms = (t1 - t0).total_seconds() * 1000.0
        if not harness:
            source_count_fn = source_count_fn or live_count_fn(source_uri)
            restored_count_fn = restored_count_fn or live_count_fn(restored_uri)
    else:
        raise ValueError(f"unknown mode: {mode}")

    assert source_count_fn is not None and restored_count_fn is not None
    source = {n: source_count_fn(n) for n in names}
    restored = {n: restored_count_fn(n) for n in names}
    report.collections = compare_counts(names, source, restored)
    if all(c.matched for c in report.collections):
        report.passed = True
    else:
        report.error = "collection count mismatch after restore"
        report.p0_incident = True
        report.passed = False
    return report


def cmd_run(args: argparse.Namespace) -> int:
    config = load_config(args.config)
    report = run_drill(
        config,
        mode=args.mode,
        pit_timestamp=args.pit_timestamp,
    )
    payload = report.to_json()
    args.report.write_text(json.dumps(payload, indent=2) + "\n")
    if args.ledger:
        rows: list[dict[str, Any]] = []
        if args.ledger.exists():
            rows = json.loads(args.ledger.read_text())
        rows.append(
            {
                "at": report.tested_at.isoformat() if report.tested_at else None,
                "passed": report.passed,
                "p0_incident": report.p0_incident,
                "restore_duration_ms": report.restore_duration_ms,
                "next_test_due": report.next_test_due.isoformat() if report.next_test_due else None,
            }
        )
        args.ledger.write_text(json.dumps(rows, indent=2) + "\n")
    print(json.dumps({"passed": report.passed, "p0_incident": report.p0_incident}))
    if report.p0_incident:
        print("P0_INCIDENT: MongoDB PIT restore drill failed", file=sys.stderr)
    return 0 if report.passed else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    run = sub.add_parser("run", help="Execute PIT restore drill and write report")
    run.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    run.add_argument("--mode", choices=("simulate", "live"), default="simulate")
    run.add_argument("--pit-timestamp", dest="pit_timestamp", default=None)
    run.add_argument(
        "--report",
        type=Path,
        default=ROOT / "release" / "fixtures" / "mongo_pit_restore_report.json",
    )
    run.add_argument(
        "--ledger",
        type=Path,
        default=ROOT / "release" / "mongo_pit_restore_ledger.json",
    )
    run.set_defaults(func=cmd_run)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
