#!/usr/bin/env python3
"""P12-022 decision table for release readiness generator."""

from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "release" / "release_readiness_checklist.py"
ITEMS = ROOT / "release" / "release_readiness_items.yaml"
SAMPLE = ROOT / "release" / "fixtures" / "release_readiness_evidence.sample.json"

import importlib.util

_spec = importlib.util.spec_from_file_location("release_readiness_checklist", SCRIPT)
assert _spec and _spec.loader
rr = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = rr
_spec.loader.exec_module(rr)

load_items_config = rr.load_items_config
evaluate_evidence_items = rr.evaluate_evidence_items
evaluate_blocked_items = rr.evaluate_blocked_items
overall_status = rr.overall_status
build_report = rr.build_report
evidence_passed = rr.evidence_passed


class ReleaseReadinessTest(unittest.TestCase):
    def test_evidence_passed_boolean(self) -> None:
        self.assertTrue(evidence_passed({"passed": True})[0])
        self.assertFalse(evidence_passed({"passed": False})[0])
        self.assertFalse(evidence_passed(None)[0])

    def test_all_p12_gates_pass_still_not_ready_with_blockers(self) -> None:
        config = load_items_config(ITEMS)
        evidence = json.loads(SAMPLE.read_text(encoding="utf-8"))
        items = evaluate_evidence_items(config, evidence) + evaluate_blocked_items(config)
        self.assertTrue(all(i.status == "pass" for i in items[:10]))
        self.assertEqual(overall_status(items), "NOT_READY")
        blocked = [i for i in items if i.status == "blocked"]
        self.assertGreaterEqual(len(blocked), 3)
        self.assertTrue(any(i.id == "P12-021" for i in blocked))

    def test_missing_evidence_fails_loud(self) -> None:
        config = load_items_config(ITEMS)
        items = evaluate_evidence_items(config, {})
        self.assertTrue(any(i.status == "missing" for i in items))
        self.assertEqual(overall_status(items), "NOT_READY")

    def test_generate_cli_writes_json(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "report.json"
            rc = rr.main(
                [
                    "generate",
                    "--evidence",
                    str(SAMPLE),
                    "--out-json",
                    str(out),
                ]
            )
            self.assertEqual(rc, 1)
            data = json.loads(out.read_text(encoding="utf-8"))
            self.assertEqual(data["overall"], "NOT_READY")
            self.assertIn("P12-021", {b["id"] for b in data["blockers"]})

    def test_ready_only_with_signoff_and_no_blockers(self) -> None:
        config = load_items_config(ITEMS)
        evidence = json.loads(SAMPLE.read_text(encoding="utf-8"))
        items = evaluate_evidence_items(config, evidence)
        report = build_report(items, SAMPLE, "v9.9.9+99", tope_signed=True)
        self.assertEqual(report["overall"], "READY")


if __name__ == "__main__":
    unittest.main()
