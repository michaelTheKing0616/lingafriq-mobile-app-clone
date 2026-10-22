#!/usr/bin/env python3
"""Fail when a GitHub Actions `uses` ref is not a full commit SHA. charter: v2"""

from __future__ import annotations

import re
import sys
import tempfile
from pathlib import Path

USES = re.compile(r"uses:\s+(\S+)")
SHA = re.compile(r"^[0-9a-f]{40}$")


def unpinned(text: str) -> list[str]:
    found = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("#"):
            continue
        match = USES.search(line)
        if not match:
            continue
        ref = match.group(1)
        if ref.startswith("./") or ref.startswith("docker://"):
            continue
        if "@" not in ref:
            found.append(ref)
            continue
        _, version = ref.rsplit("@", 1)
        version = version.split()[0]
        if not SHA.match(version):
            found.append(ref)
    return found


def scan(paths: list[Path]) -> list[str]:
    problems = []
    for path in paths:
        if path.is_dir():
            files = sorted(path.rglob("*.yml")) + sorted(path.rglob("*.yaml"))
        else:
            files = [path]
        for file in files:
            for ref in unpinned(file.read_text(encoding="utf-8")):
                problems.append(f"{file}: {ref}")
    return problems


def self_test() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        bad = root / "bad.yml"
        good = root / "good.yml"
        bad.write_text("jobs:\n  a:\n    steps:\n      - uses: actions/checkout@v4\n", encoding="utf-8")
        good.write_text(
            "jobs:\n  a:\n    steps:\n      - uses: actions/checkout@"
            + ("a" * 40)
            + " # v4\n      - uses: ./.github/actions/local\n",
            encoding="utf-8",
        )
        if unpinned(bad.read_text(encoding="utf-8")) != ["actions/checkout@v4"]:
            raise SystemExit("unpinned tag was not detected")
        if unpinned(good.read_text(encoding="utf-8")):
            raise SystemExit("a full SHA was treated as unpinned")
        if not scan([bad]):
            raise SystemExit("scan missed the unpinned workflow")


def main(argv: list[str]) -> int:
    if argv and argv[0] == "--self-test":
        self_test()
        print("pin lint self-test passed")
        return 0
    roots = [Path(arg) for arg in argv] or [Path(".github/workflows")]
    problems = scan(roots)
    if problems:
        print("\n".join(problems))
        print(f"{len(problems)} unpinned action reference(s)")
        return 1
    print("action refs are pinned")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
