#!/usr/bin/env python3
"""Move root status Markdown into docs/archive/status without deleting it.

Keep AGENTS.md and README.md (P0-INT-09). Also keep HANDOFF.md, ARCHITECTURE.md,
and STATUS.md: the standing handoff lives at the repo root, and this card writes
the other two there. Builder default, 2026-10-23.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import subprocess
import sys
import tempfile
from pathlib import Path

SOURCE_STATED = 319
KEEP = ("AGENTS.md", "ARCHITECTURE.md", "HANDOFF.md", "README.md", "STATUS.md")
DEST = Path("docs/archive/status")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    digest.update(path.read_bytes())
    return digest.hexdigest()


def root_markdown(root: Path) -> list[Path]:
    return sorted(path for path in root.glob("*.md") if path.is_file())


def to_move(root: Path) -> list[Path]:
    return [path for path in root_markdown(root) if path.name not in KEEP]


def collisions(root: Path, files: list[Path]) -> list[str]:
    found = []
    for path in files:
        if (root / DEST / path.name).exists():
            found.append(path.name)
    return found


def git_repo(root: Path) -> bool:
    result = subprocess.run(
        ["git", "-C", str(root), "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
        text=True,
    )
    return result.returncode == 0 and result.stdout.strip() == "true"


def move_file(root: Path, src: Path, dest: Path, use_git: bool) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    if not use_git:
        src.rename(dest)
        return
    rel_src = src.relative_to(root).as_posix()
    rel_dest = dest.relative_to(root).as_posix()
    tracked = subprocess.run(
        ["git", "-C", str(root), "ls-files", "--error-unmatch", rel_src],
        capture_output=True,
        text=True,
    )
    if tracked.returncode == 0:
        subprocess.check_call(["git", "-C", str(root), "mv", rel_src, rel_dest])
    else:
        src.rename(dest)


def write_manifest(root: Path, rows: list[tuple[str, str, str]], root_count: int) -> None:
    dest = root / DEST
    dest.mkdir(parents=True, exist_ok=True)
    path = dest / "MANIFEST.csv"
    delta = root_count - SOURCE_STATED
    with path.open("w", encoding="utf-8", newline="") as handle:
        handle.write(f"# source_stated={SOURCE_STATED}\n")
        handle.write(f"# root_markdown={root_count}\n")
        handle.write(f"# delta={delta}\n")
        handle.write(f"# moved={len(rows)}\n")
        handle.write("# kept=" + ";".join(KEEP) + "\n")
        writer = csv.writer(handle)
        writer.writerow(["name", "sha256_before", "sha256_after"])
        writer.writerows(rows)


def apply(root: Path, use_git: bool) -> int:
    files = to_move(root)
    blocked = collisions(root, files)
    if blocked:
        print("destination collision:", ", ".join(blocked), file=sys.stderr)
        return 1
    root_count = len(root_markdown(root))
    rows = []
    for src in files:
        before = sha256(src)
        dest = root / DEST / src.name
        move_file(root, src, dest, use_git)
        after = sha256(dest)
        rows.append((src.name, before, after))
        if before != after:
            print(f"hash changed: {src.name}", file=sys.stderr)
            return 1
    write_manifest(root, rows, root_count)
    print(f"moved {len(rows)} files to {DEST.as_posix()}")
    return 0


def check(root: Path) -> int:
    extra = [path.name for path in to_move(root)]
    if extra:
        print("root markdown outside the keep list:", ", ".join(extra), file=sys.stderr)
        return 1
    return 0


def self_test() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "AGENTS.md").write_text("keep\n", encoding="utf-8")
        (root / "README.md").write_text("keep\n", encoding="utf-8")
        (root / "HANDOFF.md").write_text("keep\n", encoding="utf-8")
        (root / "ONE.md").write_text("one\n", encoding="utf-8")
        (root / "TWO.md").write_text("two\n", encoding="utf-8")
        (root / DEST).mkdir(parents=True)
        (root / DEST / "TWO.md").write_text("already\n", encoding="utf-8")
        if apply(root, use_git=False) == 0:
            print("collision should fail before a move", file=sys.stderr)
            return 1
        if not (root / "ONE.md").is_file() or not (root / "TWO.md").is_file():
            print("collision moved a file", file=sys.stderr)
            return 1
        (root / DEST / "TWO.md").unlink()
        if apply(root, use_git=False) != 0:
            return 1
        if (root / "ONE.md").exists() or (root / "TWO.md").exists():
            print("source still present", file=sys.stderr)
            return 1
        if not (root / DEST / "ONE.md").is_file():
            print("archive missing", file=sys.stderr)
            return 1
        text = (root / DEST / "MANIFEST.csv").read_text(encoding="utf-8")
        if "source_stated=319" not in text or "delta=" not in text:
            print("manifest header missing", file=sys.stderr)
            return 1
        if "sha256" not in text:
            return 1
        for line in text.splitlines():
            if line.startswith("#") or line.startswith("name,"):
                continue
            _name, before, after = line.split(",")
            if before != after:
                print("hash mismatch in fixture", file=sys.stderr)
                return 1
        (root / "NEW.md").write_text("new\n", encoding="utf-8")
        if check(root) != 1:
            print("check should name NEW.md", file=sys.stderr)
            return 1
        (root / "NEW.md").unlink()
        if check(root) != 0:
            return 1
    print("archive self-test passed")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    root = args.root.resolve()
    if args.check:
        return check(root)
    if not args.apply:
        files = to_move(root)
        print(f"would move {len(files)} root markdown files")
        return 0
    return apply(root, use_git=git_repo(root))


if __name__ == "__main__":
    sys.exit(main())
