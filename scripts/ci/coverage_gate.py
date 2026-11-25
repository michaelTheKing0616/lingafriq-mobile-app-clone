#!/usr/bin/env python3
"""Fail when domain line coverage is below the configured threshold.

A domain file missing from the lcov report counts as 0% (its non-blank
lines are uncovered). The elevation baseline of 64 Flutter test files is
printed from coverage_domain_paths.yaml.
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CONFIG = ROOT / "coverage_domain_paths.yaml"


def load_config(path: Path) -> tuple[float, list[str], dict[str, str]]:
    threshold = None
    paths: list[str] = []
    status: dict[str, str] = {}
    section = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if line.startswith("  - "):
            if section == "paths":
                paths.append(line.strip()[2:].strip())
            continue
        if ":" not in line:
            raise SystemExit(f"bad coverage config line: {line}")
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip()
        if value == "":
            section = key
            continue
        if section == "status_inputs":
            status[key] = value
        elif key == "threshold":
            threshold = float(value)
    if threshold is None or not paths:
        raise SystemExit("coverage config is missing a threshold or a path")
    return threshold, paths, status


def parse_lcov(text: str) -> dict[str, tuple[int, int]]:
    records: dict[str, tuple[int, int]] = {}
    current = ""
    hit = 0
    found = 0
    da_found = 0
    da_hit = 0
    saw_lf = False

    def finish() -> None:
        nonlocal current, hit, found, da_found, da_hit, saw_lf
        if not current:
            return
        if not saw_lf:
            found = da_found
            hit = da_hit
        records[current.replace("\\", "/")] = (hit, found)
        current = ""
        hit = found = da_found = da_hit = 0
        saw_lf = False

    for line in text.splitlines():
        if line.startswith("SF:"):
            finish()
            current = line[3:].strip()
        elif line.startswith("DA:"):
            da_found += 1
            _, count = line[3:].split(",", 1)
            if int(count) > 0:
                da_hit += 1
        elif line.startswith("LH:"):
            hit = int(line[3:].strip())
        elif line.startswith("LF:"):
            found = int(line[3:].strip())
            saw_lf = True
        elif line == "end_of_record":
            finish()
    finish()
    return records


def in_domain(source: str, roots: list[str]) -> bool:
    norm = source.replace("\\", "/")
    while norm.startswith("./"):
        norm = norm[2:]
    marker = f"/{norm}" if not norm.startswith("/") else norm
    for root in roots:
        if norm == root or norm.startswith(root + "/") or marker.endswith("/" + root) or f"/{root}/" in marker:
            return True
    return False


def source_lines(path: Path) -> int:
    count = 0
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped and not stripped.startswith("//"):
            count += 1
    return count


def domain_sources(roots: list[str], root: Path) -> list[Path]:
    files: list[Path] = []
    for rel in roots:
        path = root / rel
        if path.is_file() and path.suffix == ".dart":
            files.append(path)
        elif path.is_dir():
            files.extend(sorted(path.rglob("*.dart")))
    return files


def coverage(lcov_text: str, roots: list[str], root: Path) -> tuple[int, int]:
    records = parse_lcov(lcov_text)
    hit = 0
    found = 0
    seen: set[str] = set()
    for source, (file_hit, file_found) in records.items():
        if not in_domain(source, roots):
            continue
        hit += file_hit
        found += file_found
        seen.add(source.replace("\\", "/").split("lib/", 1)[-1] if "lib/" in source else source)
    for path in domain_sources(roots, root):
        rel = path.relative_to(root).as_posix()
        if any(rel == item or item.endswith("/" + rel) or item.endswith(rel) for item in seen) or rel in seen:
            continue
        # Also match when lcov stored the path relative to lib's parent.
        if any(item.endswith(rel) for item in records if in_domain(item, roots)):
            continue
        found += source_lines(path)
    return hit, found


def report(hit: int, found: int, threshold: float, status: dict[str, str]) -> int:
    rate = (hit / found) if found else 0.0
    print(f"domain coverage {rate:.1%} ({hit}/{found}) threshold {threshold:.0%}")
    if status:
        parts = [f"{key} {value}" for key, value in status.items()]
        print("status inputs: " + ", ".join(parts))
    if found == 0 or rate < threshold:
        print("domain coverage is below the threshold")
        return 1
    print("domain coverage meets the threshold")
    return 0


def self_test() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        domain = root / "lib" / "learning"
        domain.mkdir(parents=True)
        (domain / "covered.dart").write_text("int a = 1;\n", encoding="utf-8")
        (domain / "new_file.dart").write_text("int missing = 1;\nint also = 2;\n", encoding="utf-8")
        lcov = "SF:lib/learning/covered.dart\nDA:1,1\nLF:1\nLH:1\nend_of_record\n"
        hit, found = coverage(lcov, ["lib/learning"], root)
        if hit != 1 or found != 3:
            raise SystemExit(f"missing file was not counted at 0%: {hit}/{found}")
        if report(hit, found, 0.70, {"elevation_flutter_test_files": "64"}) != 1:
            raise SystemExit("a drop below 70% was allowed")
        if report(8, 10, 0.70, {}) != 0:
            raise SystemExit("80% was rejected")


def main(argv: list[str]) -> int:
    if argv and argv[0] == "--self-test":
        self_test()
        print("coverage gate self-test passed")
        return 0
    lcov_path = Path(argv[0]) if argv else ROOT / "coverage" / "lcov.info"
    if not lcov_path.is_file():
        print(f"coverage report missing: {lcov_path}")
        return 1
    threshold, paths, status = load_config(CONFIG)
    hit, found = coverage(lcov_path.read_text(encoding="utf-8"), paths, ROOT)
    return report(hit, found, threshold, status)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
