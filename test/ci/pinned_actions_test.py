#!/usr/bin/env python3
"""Pin checker fixtures. A tag fails and the report names the action."""

from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHECK = ROOT / "scripts" / "ci" / "check_pinned_actions.py"


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(CHECK), *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


class PinnedActionsTest(unittest.TestCase):
    def test_tag_fails_and_names_the_action(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "bad.yml"
            path.write_text("jobs:\n  a:\n    steps:\n      - uses: actions/checkout@v4\n", encoding="utf-8")
            result = run(str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("actions/checkout@v4", result.stdout)

    def test_full_sha_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "good.yml"
            path.write_text(
                "jobs:\n  a:\n    steps:\n      - uses: actions/checkout@" + ("a" * 40) + " # v4\n",
                encoding="utf-8",
            )
            result = run(str(path))
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("action refs are pinned", result.stdout)

    def test_repo_workflows_are_pinned(self) -> None:
        result = run(str(ROOT / ".github" / "workflows"))
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_self_test_passes(self) -> None:
        result = run("--self-test")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
