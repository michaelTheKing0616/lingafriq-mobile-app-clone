#!/usr/bin/env python3
# charter: v2
"""Fail CI when byte-identical curriculum JSONs are both declared in pubspec assets.

Usage:
  python3 scripts/ci/dedupe_assets_check.py [--pubspec pubspec.yaml]

Exit codes:
  0  at most one pubspec asset per identical hash group
  1  duplicate hashes still bundled
  2  usage or parse error
"""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from collections import defaultdict
from pathlib import Path

CURRICULUM_GLOB = "lingafriq_authentic_curriculum_*.json"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def parse_pubspec_asset_lines(pubspec_text: str) -> list[str]:
    assets: list[str] = []
    in_assets = False
    for line in pubspec_text.splitlines():
        if re.match(r"^\s*assets:\s*$", line):
            in_assets = True
            continue
        if in_assets:
            if re.match(r"^\S", line) and not line.strip().startswith("#"):
                break
            m = re.match(r"^\s*-\s+(.+?)\s*$", line)
            if m:
                assets.append(m.group(1).strip())
    return assets


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--pubspec",
        type=Path,
        default=Path("pubspec.yaml"),
        help="Flutter pubspec path (default: pubspec.yaml)",
    )
    parser.add_argument(
        "--data-dir",
        type=Path,
        default=Path("assets/data"),
        help="Directory containing curriculum JSON files",
    )
    args = parser.parse_args()

    if not args.pubspec.is_file():
        sys.stderr.write(f"missing pubspec: {args.pubspec}\n")
        return 2
    if not args.data_dir.is_dir():
        sys.stderr.write(f"missing data dir: {args.data_dir}\n")
        return 2

    pubspec_assets = set(parse_pubspec_asset_lines(args.pubspec.read_text(encoding="utf-8")))
    files = sorted(args.data_dir.glob(CURRICULUM_GLOB))
    if not files:
        sys.stderr.write(f"no files matching {CURRICULUM_GLOB} under {args.data_dir}\n")
        return 2

    by_hash: dict[str, list[Path]] = defaultdict(list)
    for path in files:
        by_hash[sha256_file(path)].append(path)

    failed = False
    for digest, paths in sorted(by_hash.items(), key=lambda item: item[1][0].name):
        rels = [p.relative_to(args.pubspec.parent).as_posix() for p in paths]
        bundled = [r for r in rels if r in pubspec_assets]
        if len(paths) > 1:
            sys.stdout.write(
                f"identical group sha256={digest[:12]}…: {', '.join(p.name for p in paths)}\n"
            )
        if len(bundled) > 1:
            failed = True
            sys.stderr.write(
                "PUBSPEC_DUPLICATE_ASSET: "
                f"hash {digest[:12]}… has {len(bundled)} bundled members: {', '.join(bundled)}\n"
            )
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
