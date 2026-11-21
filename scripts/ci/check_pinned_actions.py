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


def release_workflow_problems(text: str) -> list[str]:
    """The store workflow must build the triggering SHA and must not publish from a PR."""
    problems = []
    if re.search(r"^\s*ref:\s*main\s*$", text, re.MULTILINE):
        problems.append(
            "checkout hardcodes ref: main; build the PR head or the push/dispatch SHA"
        )
    if re.search(
        r"Skipping TestFlight:.*\n\s*exit 0",
        text,
    ):
        problems.append("TestFlight treats missing signing as success")
    release_job = re.search(
        r"\n  create-release:.*?(?=\n  [A-Za-z0-9_-]+:|\Z)",
        text,
        re.DOTALL,
    )
    block = release_job.group(0) if release_job else ""
    if not block:
        problems.append("create-release job is missing")
    elif re.search(r"^\s*if:\s*always\(\)\s*$", block, re.MULTILINE):
        problems.append("create-release runs on pull requests and failed builds")
    elif "workflow_dispatch" not in block or "refs/heads/main" not in block:
        problems.append("create-release is not limited to a main push or manual dispatch")
    release_at = block.find("Create GitHub Release")
    if release_at >= 0 and "continue-on-error:" in block[release_at:release_at + 600]:
        problems.append("GitHub Release step ignores publish failures")
    return problems


def main(argv: list[str]) -> int:
    if argv and argv[0] == "--self-test":
        self_test()
        stale = "jobs:\n  build-android:\n    steps:\n      - with:\n          ref: main\n  create-release:\n    if: always()\n"
        if "ref: main" not in release_workflow_problems(stale)[0]:
            raise SystemExit("stale main checkout was not detected")
        print("pin lint self-test passed")
        return 0
    roots = [Path(arg) for arg in argv] or [Path(".github/workflows")]
    problems = scan(roots)
    for root in roots:
        workflow = root / "build-and-release.yml" if root.is_dir() else root
        if workflow.name == "build-and-release.yml" and workflow.is_file():
            problems.extend(
                f"{workflow}: {item}"
                for item in release_workflow_problems(workflow.read_text(encoding="utf-8"))
            )
    if problems:
        print("\n".join(problems))
        print(f"{len(problems)} workflow problem(s)")
        return 1
    print("action refs are pinned")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
