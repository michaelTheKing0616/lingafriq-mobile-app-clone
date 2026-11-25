#!/usr/bin/env python3
"""P12-020: run schema-versioned local migration drill and append ledger row."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_REPORT = ROOT / "release" / "fixtures" / "local_migration_drill_report.json"
DEFAULT_LEDGER = ROOT / "release" / "local_migration_drill_ledger.json"
TEST = ROOT / "test" / "db" / "p12_020_migration_drill_test.dart"


def run_flutter_drill(report_path: Path) -> tuple[int, dict[str, Any] | None]:
    env = {**dict(**__import__("os").environ), "P12_020_REPORT": str(report_path)}
    proc = subprocess.run(
        ["flutter", "test", str(TEST)],
        cwd=ROOT,
        env=env,
        capture_output=True,
        text=True,
    )
    if proc.stdout:
        print(proc.stdout, end="")
    if proc.stderr:
        print(proc.stderr, end="", file=sys.stderr)
    if proc.returncode != 0:
        return proc.returncode, None
    if not report_path.is_file():
        return 1, None
    return 0, json.loads(report_path.read_text())


def cmd_run(args: argparse.Namespace) -> int:
    rc, payload = run_flutter_drill(args.report)
    if rc != 0 or payload is None:
        print(json.dumps({"passed": False, "error": "flutter test failed"}))
        return rc or 1
    args.report.write_text(json.dumps(payload, indent=2) + "\n")
    if args.ledger:
        rows: list[dict[str, Any]] = []
        if args.ledger.exists():
            rows = json.loads(args.ledger.read_text())
        rows.append(
            {
                "at": payload.get("tested_at") or datetime.now(timezone.utc).isoformat(),
                "passed": payload.get("passed"),
                "latest_schema": payload.get("latest_schema"),
                "versions": payload.get("versions"),
            }
        )
        args.ledger.write_text(json.dumps(rows, indent=2) + "\n")
    print(json.dumps({"passed": payload.get("passed")}))
    return 0 if payload.get("passed") else 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    run = sub.add_parser("run", help="Execute migration drill via flutter test")
    run.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    run.add_argument("--ledger", type=Path, default=DEFAULT_LEDGER)
    run.set_defaults(func=cmd_run)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
