#!/usr/bin/env python3
"""Coverage and import-scan checks for the consolidation harvest report."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "nav" / "harvest_check.py"
CARDS = ROOT / "docs" / "build" / "cards" / "P3"


def load_module():
    spec = importlib.util.spec_from_file_location("harvest_check", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


harvest_check = load_module()


class HarvestLedgerTest(unittest.TestCase):
    def test_every_harvest_list_item_has_a_row(self):
        lists = harvest_check.load_harvest_lists(CARDS)
        missing = harvest_check.uncovered_items(lists)
        self.assertEqual(missing, [])
        self.assertEqual(len(lists), 6)

    def test_dropped_rows_keep_the_card_reason_and_unrecorded_approver(self):
        dropped = [row for row in harvest_check.LEDGER if row["status"] == "Dropped"]
        self.assertGreater(len(dropped), 0)
        for row in dropped:
            self.assertTrue(row["text"].strip(), row["entry"])
            self.assertEqual(row["approver"], "Unrecorded")
        for row in harvest_check.LEDGER:
            if row["status"] != "Dropped":
                self.assertEqual(row["approver"], "n/a")

    def test_seventh_template_stays_unnamed(self):
        seventh = [
            row
            for row in harvest_check.LEDGER
            if row["card"] == "P3-068" and row["entry"] == "seventh template"
        ]
        self.assertEqual(len(seventh), 1)
        self.assertEqual(seventh[0]["status"], "Unresolved")
        self.assertIn("not present", seventh[0]["text"])
        self.assertNotIn("template_seventh", seventh[0]["text"])

    def test_shell_is_kept(self):
        shell = [
            row
            for row in harvest_check.LEDGER
            if row["entry"] == "game_template_shell.dart"
        ]
        self.assertEqual(len(shell), 1)
        self.assertEqual(shell[0]["status"], "Kept")
        self.assertIn("BaseGameScreen", shell[0]["text"])

    def test_report_has_no_em_dash(self):
        report = harvest_check.render_report(
            lists=harvest_check.load_harvest_lists(CARDS),
            missing=[],
            removed=[],
            kept_hits=[],
            lib_dir=ROOT / "lib",
            card_status="Draft",
        )
        self.assertNotIn("\u2014", report)
        self.assertNotIn("\u2013", report)
        self.assertIn("Status stays Draft", report)
        self.assertIn("Approver is Unrecorded", report)


class HarvestScanTest(unittest.TestCase):
    def test_deleted_legacy_import_exits_1_and_names_the_import(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lib = root / "lib" / "screens"
            lib.mkdir(parents=True)
            (lib / "still_wired.dart").write_text(
                "import 'package:lingafriq/legacy/ai_chat/ai_mode_selection_screen.dart';\n",
                encoding="utf-8",
            )
            out = root / "HARVEST_REPORT.md"
            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--root",
                    str(root),
                    "--cards",
                    str(CARDS),
                    "--lib",
                    str(root / "lib"),
                    "--out",
                    str(out),
                ],
                check=False,
                capture_output=True,
                text=True,
            )
            report = out.read_text(encoding="utf-8")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("ai_mode_selection_screen.dart", result.stderr)
        self.assertIn("lib/screens/still_wired.dart:1", result.stderr)
        self.assertIn("Remaining imports from lib/", report)
        self.assertIn("ai_mode_selection_screen.dart", report)
        self.assertIn("Status stays Draft", report)

    def test_kept_shell_import_is_not_a_failure(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lib = root / "lib" / "screens" / "games"
            lib.mkdir(parents=True)
            (lib / "base_game_screen.dart").write_text(
                "import 'templates/game_template_shell.dart';\n",
                encoding="utf-8",
            )
            code = harvest_check.main(
                [
                    "--root",
                    str(root),
                    "--cards",
                    str(CARDS),
                    "--lib",
                    str(root / "lib"),
                    "--no-write",
                ]
            )
        self.assertEqual(code, 0)

    def test_survivor_proverb_import_and_comments_are_not_failures(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lib = root / "lib" / "games" / "proverb_unlocker"
            lib.mkdir(parents=True)
            (lib / "holder.dart").write_text(
                "import '../proverb_unlocker/proverb_unlocker_game.dart';\n"
                "/// `lib/screens/games/cultural/proverb_unlocker_game.dart`.\n"
                "import 'package:lingafriq/screens/onboarding/unified_onboarding_screen.dart';\n",
                encoding="utf-8",
            )
            removed, kept = harvest_check.scan_lib(root / "lib", root)
        self.assertEqual(removed, [])
        self.assertEqual(kept, [])

    def test_old_tablet_import_fails_and_quiz_enhanced_import_fails(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lib = root / "lib"
            lib.mkdir()
            (lib / "old.dart").write_text(
                "import 'package:lingafriq/screens/games/cultural/proverb_unlocker_game.dart';\n"
                "import 'package:lingafriq/screens/ugc/create_quiz_screen_enhanced.dart';\n",
                encoding="utf-8",
            )
            removed, _kept = harvest_check.scan_lib(lib, root)
        basenames = {hit["basename"] for hit in removed}
        self.assertEqual(
            basenames,
            {"proverb_unlocker_game.dart", "create_quiz_screen_enhanced.dart"},
        )
        self.assertEqual(len(removed), 2)

    def test_exact_basename_does_not_flag_the_survivor_names(self):
        self.assertIsNone(
            harvest_check.classify_uri(
                "package:lingafriq/screens/onboarding/unified_onboarding_screen.dart"
            )
        )
        self.assertIsNone(
            harvest_check.classify_uri(
                "package:lingafriq/screens/ai_chat/polie_workspace_screen.dart"
            )
        )
        self.assertIsNone(
            harvest_check.classify_uri("package:lingafriq/design/legacy_shim.dart")
        )
        self.assertIsNone(harvest_check.classify_uri("package:riverpod/legacy.dart"))
        kind, _note = harvest_check.classify_uri(
            "package:lingafriq/screens/onboarding/onboarding_screen.dart"
        )
        self.assertEqual(kind, "removed")


if __name__ == "__main__":
    unittest.main()
