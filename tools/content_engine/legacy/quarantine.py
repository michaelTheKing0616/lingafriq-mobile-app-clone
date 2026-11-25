"""Quarantine placeholder and duplicate legacy curriculum bundles (P4-081, CURRICULUM §8.1).

Moves known placeholder bundles out of app build paths. Salvage (P4-082) reads the
canonical JSON from the quarantine tree via ``salvage_source_path``.
"""

from __future__ import annotations

import argparse
import json
import shutil
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

MANIFEST_FILENAME = "legacy_quarantine_manifest.json"
QUARANTINE_DIRNAME = "quarantine/legacy"

# ELEVATION §6.1: three identical 11.3 MB authentic curriculum copies.
PLACEHOLDER_AUTHENTIC_BUNDLES: tuple[str, ...] = (
    "assets/data/lingafriq_authentic_curriculum_a1_a2_b1.json",
    "assets/data/lingafriq_authentic_curriculum_a1_c1.json",
    "assets/data/lingafriq_authentic_curriculum_a1_c2.json",
)

# Duplicated expanded tree (also embedded under lingafriq_full_curriculum_bundle).
DUPLICATE_EXPANDED_BUNDLE = "curriculum_expanded_bundle"

QUARANTINE_SOURCES: tuple[str, ...] = (
    *PLACEHOLDER_AUTHENTIC_BUNDLES,
    DUPLICATE_EXPANDED_BUNDLE,
)

CANONICAL_SALVAGE_SOURCE = "assets/data/lingafriq_authentic_curriculum_a1_c2.json"


@dataclass(frozen=True)
class QuarantineAction:
    source_rel: str
    dest_rel: str
    action: str  # "move" | "skip"


@dataclass(frozen=True)
class QuarantineResult:
    actions: tuple[QuarantineAction, ...]
    manifest_path: Path


def repo_root(explicit: Path | None = None) -> Path:
    if explicit is not None:
        return explicit.resolve()
    return Path(__file__).resolve().parents[3]


def quarantine_dir(root: Path) -> Path:
    return root / QUARANTINE_DIRNAME


def manifest_path(root: Path) -> Path:
    return quarantine_dir(root) / MANIFEST_FILENAME


def salvage_source_path(root: Path) -> Path:
    """Path to the canonical authentic curriculum JSON after quarantine."""
    return quarantine_dir(root) / CANONICAL_SALVAGE_SOURCE


def build_excluded_relpaths(root: Path | None = None) -> frozenset[str]:
    """Paths that runtime and build steps must not read (quarantine tree only)."""
    base = repo_root(root)
    excluded = {QUARANTINE_DIRNAME, f"{QUARANTINE_DIRNAME}/"}
    manifest = load_manifest(base)
    if manifest is not None:
        for entry in manifest.get("quarantined", []):
            rel = entry.get("dest_rel")
            if isinstance(rel, str) and rel:
                excluded.add(rel)
    return frozenset(excluded)


def path_is_build_excluded(path: Path, root: Path | None = None) -> bool:
    base = repo_root(root)
    try:
        rel = path.resolve().relative_to(base.resolve()).as_posix()
    except ValueError:
        return False
    if rel == QUARANTINE_DIRNAME or rel.startswith(f"{QUARANTINE_DIRNAME}/"):
        return True
    return rel in build_excluded_relpaths(base)


def load_manifest(root: Path) -> dict[str, Any] | None:
    path = manifest_path(root)
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def _dest_rel(source_rel: str) -> str:
    return f"{QUARANTINE_DIRNAME}/{source_rel}"


def _plan_actions(root: Path) -> list[QuarantineAction]:
    actions: list[QuarantineAction] = []
    existing = load_manifest(root)
    already: set[str] = set()
    if existing:
        for entry in existing.get("quarantined", []):
            src = entry.get("source_rel")
            if isinstance(src, str):
                already.add(src)

    for source_rel in QUARANTINE_SOURCES:
        dest_rel = _dest_rel(source_rel)
        src = root / source_rel
        dest = root / dest_rel
        if dest.exists():
            actions.append(QuarantineAction(source_rel, dest_rel, "skip"))
            continue
        if not src.exists():
            if source_rel in already:
                actions.append(QuarantineAction(source_rel, dest_rel, "skip"))
            continue
        actions.append(QuarantineAction(source_rel, dest_rel, "move"))
    return actions


def run_quarantine(root: Path | None = None, *, dry_run: bool = False) -> QuarantineResult:
    base = repo_root(root)
    actions = _plan_actions(base)
    qdir = quarantine_dir(base)
    manifest_file = manifest_path(base)

    if not dry_run:
        qdir.mkdir(parents=True, exist_ok=True)
        for act in actions:
            if act.action != "move":
                continue
            src = base / act.source_rel
            dest = base / act.dest_rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dest))

        quarantined: list[dict[str, str]] = []
        for source_rel in QUARANTINE_SOURCES:
            dest_rel = _dest_rel(source_rel)
            if (base / dest_rel).exists():
                quarantined.append({"source_rel": source_rel, "dest_rel": dest_rel})

        payload: dict[str, Any] = {
            "card": "P4-081",
            "quarantined_at": datetime.now(timezone.utc).isoformat(),
            "quarantined": quarantined,
            "build_excluded_root": QUARANTINE_DIRNAME,
            "salvage_source_rel": _dest_rel(CANONICAL_SALVAGE_SOURCE),
        }
        manifest_file.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    return QuarantineResult(tuple(actions), manifest_file)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Quarantine legacy placeholder curriculum bundles.")
    parser.add_argument("--dry-run", action="store_true", help="List planned moves without changing files.")
    parser.add_argument("--repo-root", type=Path, default=None, help="Repository root (defaults to mobile app clone).")
    args = parser.parse_args(argv)

    result = run_quarantine(args.repo_root, dry_run=args.dry_run)
    for act in result.actions:
        print(f"{act.action}\t{act.source_rel}\t->\t{act.dest_rel}")
    if not args.dry_run:
        print(f"manifest\t{result.manifest_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
