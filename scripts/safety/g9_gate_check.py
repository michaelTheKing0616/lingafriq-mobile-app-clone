#!/usr/bin/env python3
"""P9-936: Assemble and verify G9 guardian + moderation gate evidence."""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = ROOT.parent
PACKET = ROOT / "docs" / "build" / "external" / "G9_gate_packet.md"
EXTERNAL = ROOT / "docs" / "build" / "EXTERNAL.md"
INCIDENT = ROOT / "docs" / "safety" / "INCIDENT_RESPONSE.md"
LOADTEST = ROOT / "docs" / "build" / "external" / "loadtest_report.md"
BACKEND = REPO_ROOT / "node-backend"

FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
EXT_ROW = re.compile(
    r"^\|\s*(EXT-\d+)\s*\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|[^|]+\|\s*(Open|Done|Blocked)\s*\|",
    re.MULTILINE,
)


def load_packet() -> tuple[dict, str]:
    text = PACKET.read_text(encoding="utf-8")
    m = FM_RE.match(text)
    if not m:
        raise ValueError("G9_gate_packet.md: missing YAML front matter")
    meta = yaml.safe_load(m.group(1)) or {}
    return meta, text[m.end() :]


def ext_status(ext_id: str) -> str | None:
    if not EXTERNAL.is_file():
        return None
    body = EXTERNAL.read_text(encoding="utf-8")
    for m in EXT_ROW.finditer(body):
        if m.group(1) == ext_id:
            return m.group(2).strip()
    return None


def check_packet_structure(meta: dict, body: str, errors: list[str]) -> None:
    if meta.get("gate") != "G9":
        errors.append("front matter gate must be G9")
    if meta.get("card_id") != "P9-936":
        errors.append("front matter card_id must be P9-936")
    rec = (meta.get("recommendation") or "").strip().upper()
    if rec not in ("NO-GO", "GO", "GO-WITH-CONDITIONS"):
        errors.append("recommendation must be GO / NO-GO / GO-WITH-CONDITIONS")
    if "Exit criteria" not in body:
        errors.append("packet missing Exit criteria section")
    if "Tests and evals" not in body:
        errors.append("packet missing Tests and evals section")
    links = meta.get("evidence_links") or {}
    for key, rel in links.items():
        path = ROOT / rel.split("#")[0]
        if not path.is_file():
            errors.append(f"evidence_links.{key} missing file: {rel}")
    for path in (INCIDENT, LOADTEST):
        if not path.is_file():
            errors.append(f"missing required artefact: {path.relative_to(ROOT)}")


def check_gate_logic(meta: dict, errors: list[str]) -> None:
    open_high = meta.get("open_high_findings") or []
    gate_open = meta.get("gate_open")
    rec = (meta.get("recommendation") or "").strip().upper()

    for ext_id in ("EXT-17", "EXT-25"):
        status = ext_status(ext_id)
        if status is None:
            errors.append(f"could not read {ext_id} status from EXTERNAL.md")
        elif status == "Open" and ext_id not in open_high:
            errors.append(f"{ext_id} is Open but not listed in open_high_findings")

    if "EXT-17" in open_high or "EXT-25" in open_high:
        if gate_open is True:
            errors.append("gate_open must be false while EXT-17/EXT-25 high findings open")
        if rec == "GO":
            errors.append("recommendation cannot be GO while open_high_findings non-empty")

    logged = meta.get("blocked_external_logged") or []
    ids = {row.get("id") for row in logged if isinstance(row, dict)}
    if "P9-935" not in ids:
        errors.append("blocked_external_logged must include P9-935 (EXT-17)")


def check_policy_matrix(meta: dict, errors: list[str], run_tests: bool) -> None:
    matrix = meta.get("policy_matrix_tests") or {}
    for repo_label, paths in (("backend", matrix.get("backend") or []), ("mobile", matrix.get("mobile") or [])):
        for rel in paths:
            if repo_label == "backend":
                path = REPO_ROOT / rel
            else:
                path = ROOT / rel
            if not path.is_file():
                errors.append(f"policy_matrix_tests missing: {rel}")

    if not run_tests:
        return

    for rel in matrix.get("backend") or []:
        test_path = REPO_ROOT / rel
        name = test_path.name
        proc = subprocess.run(
            ["npm", "test", "--", str(test_path.relative_to(BACKEND))],
            cwd=BACKEND,
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            errors.append(f"backend test failed {name}: {(proc.stderr or proc.stdout)[-800:]}")

    for rel in matrix.get("mobile") or []:
        proc = subprocess.run(
            ["flutter", "test", rel],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )
        if proc.returncode != 0:
            errors.append(f"mobile test failed {rel}: {(proc.stderr or proc.stdout)[-800:]}")


def run_gate(*, run_tests: bool = False) -> list[str]:
    errors: list[str] = []
    if not PACKET.is_file():
        return ["G9_gate_packet.md missing"]
    try:
        meta, body = load_packet()
    except ValueError as exc:
        return [str(exc)]
    check_packet_structure(meta, body, errors)
    check_gate_logic(meta, errors)
    check_policy_matrix(meta, errors, run_tests)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="Validate packet and matrix paths")
    parser.add_argument(
        "--with-tests",
        action="store_true",
        help="Also run listed Jest and Flutter policy-matrix suites",
    )
    args = parser.parse_args()
    if not args.check and not args.with_tests:
        parser.print_help()
        return 2
    errors = run_gate(run_tests=args.with_tests)
    if errors:
        for e in errors:
            print(f"g9_gate_check: {e}", file=sys.stderr)
        return 1
    print("g9_gate_check: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
