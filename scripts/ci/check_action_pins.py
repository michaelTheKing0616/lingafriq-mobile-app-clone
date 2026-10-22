#!/usr/bin/env python3
"""Fail when a GitHub Actions `uses` ref is not a full commit SHA. charter: v2"""

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
            for ref in unpinned(file.read_text()):
                problems.append(f"{file}: {ref}")
    return problems


def self_test() -> None:
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        bad = root / "bad.yml"
        good = root / "good.yml"
        bad.write_text("jobs:\n  a:\n    steps:\n      - uses: actions/checkout@v4\n")
        good.write_text(
            "jobs:\n  a:\n    steps:\n      - uses: actions/checkout@"
            + "a" * 40
            + " # v4\n      - uses: ./.github/actions/local\n"
        )
        if unpinned(bad.read_text()) != ["actions/checkout@v4"]:
            raise SystemExit("unpinned tag was not detected")
        if unpinned(good.read_text()):
            raise SystemExit("a full SHA was treated as unpinned")
        if not scan([bad]):
            raise SystemExit("scan missed the unpinned workflow")


def main() -> None:
    if len(sys.argv) > 1 and sys.argv[1] == "--self-test":
        self_test()
        print("pin lint self-test passed")
        return
    roots = [Path(arg) for arg in sys.argv[1:]] or [Path(".github/workflows")]
    problems = scan(roots)
    if problems:
        print("\n".join(problems))
        raise SystemExit(f"{len(problems)} unpinned action reference(s)")
    print("action refs are pinned")


if __name__ == "__main__":
    main()
