#!/usr/bin/env python3
"""Gate tests. Eval items here are labelled fixtures, not a live model run."""

from __future__ import annotations

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GATE = ROOT / "scripts" / "ci" / "ai_eval_gate.py"
PROMPT = "lib/ai/modes/mode_prompts.dart"


def run(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["python3", str(GATE), *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )


def passing_items() -> list[dict]:
    return [
        {
            "metric": "diacritic_completeness",
            "output": "ọkọ̀",
            "reference": "ọkọ̀",
        },
        {
            "metric": "refusal_correctness",
            "refused": True,
            "expected_refused": True,
        },
        {
            "metric": "persona_fidelity",
            "output": "Quoted from the Nkrumah dossier.",
            "citation": "Nkrumah dossier",
        },
    ]


class AiEvalGateTest(unittest.TestCase):
    def hash_for(self, path: str) -> str:
        result = run("--print-sources-hash", "--changed", path)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    def write_outputs(self, directory: Path, items: list[dict], digest: str) -> Path:
        path = directory / "outputs.json"
        path.write_text(
            json.dumps({"sources_sha256": digest, "source": "labelled-fixture", "items": items}),
            encoding="utf-8",
        )
        return path

    def test_unrelated_change_is_skipped_with_a_reason(self) -> None:
        result = run("--changed", "README.md")
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("skipped: no prompt or model identifier change", result.stdout)

    def test_prompt_change_without_outputs_fails_loud(self) -> None:
        result = run("--changed", PROMPT, "--outputs", "/tmp/lingafriq-missing-eval-outputs.json")
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("eval infrastructure failure:", result.stdout)
        self.assertNotIn("skipped", result.stdout)

    def test_prompt_change_below_threshold_is_blocked(self) -> None:
        items = passing_items()
        items[0] = {"metric": "diacritic_completeness", "output": "oko", "reference": "ọkọ̀"}
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_outputs(Path(tmp), items, self.hash_for(PROMPT))
            result = run("--changed", PROMPT, "--outputs", str(path))
        self.assertEqual(result.returncode, 1, result.stdout)
        self.assertIn("blocked: diacritic_completeness", result.stdout)
        self.assertNotIn("skipped", result.stdout)

    def test_prompt_change_meeting_threshold_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_outputs(Path(tmp), passing_items(), self.hash_for(PROMPT))
            result = run("--changed", PROMPT, "--outputs", str(path))
        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("eval passed", result.stdout)
        self.assertNotIn("skipped", result.stdout)

    def test_stale_outputs_are_an_infrastructure_failure(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = self.write_outputs(Path(tmp), passing_items(), "0" * 64)
            result = run("--changed", PROMPT, "--outputs", str(path))
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("eval infrastructure failure:", result.stdout)
        self.assertNotIn("skipped", result.stdout)

    def test_model_identifier_change_without_outputs_fails_loud(self) -> None:
        result = run(
            "--changed",
            "tools/llm_authoring/_llm_clients.py",
            "--outputs",
            "/tmp/lingafriq-missing-model-eval.json",
        )
        self.assertEqual(result.returncode, 2, result.stdout)
        self.assertIn("eval infrastructure failure:", result.stdout)
        self.assertNotIn("skipped", result.stdout)


if __name__ == "__main__":
    unittest.main()
