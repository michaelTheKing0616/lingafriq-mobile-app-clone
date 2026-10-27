#!/usr/bin/env python3
# charter: v2
"""Release asset hygiene: no code files in assets, dev examples off lib/, font refs (P12-002).

Usage:
  python3 scripts/ci/asset_audit.py [--root .]

Exit codes:
  0  all checks pass
  1  policy violation (details on stderr)
  2  usage or parse error
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

FORBIDDEN_ASSET_SUFFIXES = (".py", ".dart")
DEV_EXAMPLE_FILES = (
    "integrated_screen_example.dart",
    "errorhandler_integration_example.dart",
    "performance_utilities_example.dart",
)
FORBIDDEN_LIB_DIRS = (
    "lib/examples",
    "lib/screens/examples",
)


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


def parse_pubspec_font_assets(pubspec_text: str) -> list[str]:
    fonts: list[str] = []
    for line in pubspec_text.splitlines():
        m = re.match(r"^\s*-\s+asset:\s+(.+\.ttf)\s*$", line)
        if m:
            fonts.append(m.group(1).strip())
    return fonts


def collect_dart_sources(root: Path) -> str:
    chunks: list[str] = []
    for base in (root / "lib", root / "test"):
        if not base.is_dir():
            continue
        for path in base.rglob("*.dart"):
            try:
                chunks.append(path.read_text(encoding="utf-8", errors="replace"))
            except OSError as exc:
                sys.stderr.write(f"ASSET_AUDIT_READ_FAIL {path}: {exc}\n")
                raise
    return "\n".join(chunks)


def expanded_asset_paths(root: Path, pubspec_assets: list[str]) -> list[Path]:
    paths: list[Path] = []
    for entry in pubspec_assets:
        p = root / entry
        if entry.endswith("/"):
            if p.is_dir():
                paths.extend(sorted(p.rglob("*")))
            continue
        if p.is_file():
            paths.append(p)
        elif p.is_dir():
            paths.extend(sorted(p.rglob("*")))
    return [p for p in paths if p.is_file()]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("."), help="Repo root (mobile app)")
    args = parser.parse_args()
    root = args.root.resolve()
    pubspec_path = root / "pubspec.yaml"
    if not pubspec_path.is_file():
        sys.stderr.write(f"missing pubspec: {pubspec_path}\n")
        return 2

    pubspec_text = pubspec_path.read_text(encoding="utf-8")
    failures: list[str] = []

    for rel_dir in FORBIDDEN_LIB_DIRS:
        path = root / rel_dir
        if path.is_dir() and any(path.iterdir()):
            failures.append(f"DEV_EXAMPLE_STILL_IN_LIB {rel_dir}/")

    dev_examples = root / "dev" / "examples"
    for name in DEV_EXAMPLE_FILES:
        if not (dev_examples / name).is_file():
            failures.append(f"DEV_EXAMPLE_MISSING dev/examples/{name}")

    pubspec_assets = parse_pubspec_asset_lines(pubspec_text)
    for file_path in expanded_asset_paths(root, pubspec_assets):
        rel = file_path.relative_to(root).as_posix()
        if file_path.suffix.lower() in FORBIDDEN_ASSET_SUFFIXES:
            failures.append(f"FORBIDDEN_ASSET_CODE {rel}")

    fonts_dir = root / "assets" / "fonts"
    declared_fonts = parse_pubspec_font_assets(pubspec_text)
    if fonts_dir.is_dir():
        on_disk = sorted(p for p in fonts_dir.glob("*.ttf"))
        declared_set = {root / f for f in declared_fonts}
        for path in on_disk:
            if path not in declared_set:
                failures.append(f"FONT_UNDECLARED {path.relative_to(root).as_posix()}")
        for rel in declared_fonts:
            if not (root / rel).is_file():
                failures.append(f"FONT_MISSING_ON_DISK {rel}")

    try:
        dart_blob = collect_dart_sources(root)
    except OSError:
        return 1

    for rel in declared_fonts:
        basename = Path(rel).name
        if basename not in dart_blob and f"assets/fonts/{basename}" not in dart_blob:
            failures.append(f"FONT_UNREFERENCED {rel}")

    if failures:
        for item in failures:
            sys.stderr.write(item + "\n")
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
