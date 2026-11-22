#!/usr/bin/env python3
"""Parser coverage and the unmapped-route failure for the route-to-hub map."""

from __future__ import annotations

import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts" / "nav" / "route_map.py"

HUBS = {"Today", "Learn", "Speak", "Play", "Village", "Me"}
JOBS = {"learn it", "say it", "live it"}
STAGES = {
    "Day 1",
    "Account created",
    "Week 1 / A1 unit 3",
    "A2",
    "B1",
    "native speaker (any level)",
}


def load_module():
    spec = importlib.util.spec_from_file_location("route_map", SCRIPT)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


route_map = load_module()


FIXTURE_APP = """
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final routes = <String, WidgetBuilder>{
    'curriculum': (_) => const LessonsMapEntryScreen(),
    // 'commented-out': (_) => const Hidden(),
    'daily_goals': (_) => const DailyGoalsScreen(),
    'wa-status': (_) => const WaStatusListScreen(),
    'lingchat_ai': (_) => const LingChatAiConversationScreen(),
  };
  final later = <String, WidgetBuilder>{
    'not-in-the-table': (_) => const Other(),
  };
  return null;
}
"""

FIXTURE_DRAWER = """
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });
}

class AppDrawer extends StatelessWidget {
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DrawerItem(
          icon: PanAfricanIcons.home,
          label: 'Dashboard',
          onTap: () {},
          isDark: false,
        ),
        _DrawerItem(
          icon: PanAfricanIcons.chat,
          label: l10nOf(context).shellGlobalChat,
          onTap: () {},
          isDark: false,
        ),
      ],
    );
  }
}
"""

UNMAPPED_APP = """
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  final routes = <String, WidgetBuilder>{
    'curriculum': (_) => const LessonsMapEntryScreen(),
    'not-a-home': (_) => const MysteryScreen(),
  };
  return null;
}
"""

UNMAPPED_DRAWER = """
_DrawerItem(
  icon: Icons.help,
  label: 'Nowhere',
  onTap: () {},
  isDark: false,
)
"""


def write_tree(root: Path, app: str, drawer: str | None) -> None:
    app_path = root / "lib" / "my_app.dart"
    app_path.parent.mkdir(parents=True, exist_ok=True)
    app_path.write_text(app, encoding="utf-8")
    if drawer is None:
        return
    drawer_path = root / "lib" / "screens" / "tabs_view" / "app_drawer" / "app_drawer.dart"
    drawer_path.parent.mkdir(parents=True, exist_ok=True)
    drawer_path.write_text(drawer, encoding="utf-8")


class RouteMapParseTest(unittest.TestCase):
    def test_parser_reads_only_the_named_route_table(self):
        names = route_map.parse_routes(FIXTURE_APP)
        self.assertEqual(
            names,
            ["curriculum", "daily_goals", "wa-status", "lingchat_ai"],
        )

    def test_parser_reads_drawer_items_and_skips_the_constructor(self):
        items = route_map.parse_drawer_items(
            FIXTURE_DRAWER,
            "lib/screens/tabs_view/app_drawer/app_drawer.dart",
        )
        self.assertEqual([item.key for item in items], ["Dashboard", "shellGlobalChat"])

    def test_fixture_map_names_one_home_job_stage_and_loop(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_tree(root, FIXTURE_APP, FIXTURE_DRAWER)
            out = root / "ROUTE_MAP.csv"
            code = route_map.main(["--root", str(root), "--out", str(out)])
            self.assertEqual(code, 0)
            text = out.read_text(encoding="utf-8")
        rows = list(route_map.csv.DictReader(text.splitlines()))
        by_key = {(row["kind"], row["key"]): row for row in rows}
        self.assertEqual(by_key[("route", "curriculum")]["hub"], "Learn")
        self.assertEqual(by_key[("route", "curriculum")]["job"], "learn it")
        self.assertEqual(by_key[("route", "daily_goals")]["hub"], "Today")
        status = by_key[("route", "wa-status")]
        self.assertEqual(status["hub"], "Village")
        self.assertEqual(status["surface"], "status")
        self.assertEqual(status["learning_loop"], "Language Status")
        chat = by_key[("drawer", "shellGlobalChat")]
        self.assertEqual(chat["hub"], "Village")
        self.assertEqual(chat["surface"], "chat")
        self.assertEqual(chat["learning_loop"], "Language Squares")
        tutor = by_key[("route", "lingchat_ai")]
        self.assertEqual(tutor["hub"], "Speak")
        self.assertEqual(tutor["surface"], "")
        for row in rows:
            self.assertIn(row["hub"], HUBS)
            self.assertIn(row["job"], JOBS)
            self.assertIn(row["unlock_stage"], STAGES)
            self.assertTrue(row["learning_loop"])
            self.assertNotIn("|", row["learning_loop"])

    def test_fixture_run_prints_the_route_count(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_tree(root, FIXTURE_APP, FIXTURE_DRAWER)
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--root", str(root), "--out", str(root / "out.csv")],
                check=False,
                capture_output=True,
                text=True,
            )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("registered routes: 4", result.stdout)
        self.assertIn("wrote ", result.stdout)


class UnmappedRouteTest(unittest.TestCase):
    def test_unmapped_route_and_drawer_item_fail_and_are_listed(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_tree(root, UNMAPPED_APP, UNMAPPED_DRAWER)
            out = root / "ROUTE_MAP.csv"
            result = subprocess.run(
                [sys.executable, str(SCRIPT), "--root", str(root), "--out", str(out)],
                check=False,
                capture_output=True,
                text=True,
            )
            wrote = out.exists()
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("registered routes: 2", result.stdout)
        self.assertIn("unmapped route: not-a-home", result.stdout)
        self.assertIn("unmapped drawer:", result.stdout)
        self.assertIn("Nowhere", result.stdout)
        self.assertNotIn("unmapped route: curriculum", result.stdout)
        self.assertFalse(wrote)


class RepoRouteMapTest(unittest.TestCase):
    def test_repo_routes_are_about_120_to_125_and_fully_mapped(self):
        routes, drawers = route_map.load_tree(ROOT)
        problems = route_map.audit(routes, drawers)
        self.assertEqual(problems, [], "\n".join(problems))
        self.assertGreaterEqual(len(routes), 120)
        self.assertLessEqual(len(routes), 130)
        rows = route_map.build_rows(routes, drawers, route_map.load_english_labels(ROOT))
        route_rows = [row for row in rows if row.kind == "route"]
        drawer_rows = [row for row in rows if row.kind == "drawer"]
        self.assertEqual(len(route_rows), len(routes))
        self.assertEqual(len(drawer_rows), len(drawers))
        self.assertGreaterEqual(len(drawers), 36)
        for row in rows:
            self.assertIn(row.hub, HUBS)
            self.assertIn(row.job, JOBS)
            self.assertIn(row.unlock_stage, STAGES)
            self.assertTrue(row.learning_loop)
            if row.surface in {"chat", "status", "clips", "square"}:
                self.assertEqual(row.hub, "Village", row.key)
                self.assertTrue(row.learning_loop, row.key)
        social = {row.key: row for row in route_rows}
        self.assertEqual(social["global_chat"].learning_loop, "Language Squares")
        self.assertEqual(social["private-chat-inbox"].learning_loop, "Language-exchange DMs")
        self.assertEqual(social["wa-status"].learning_loop, "Language Status")
        self.assertEqual(social["wa-status-create"].surface, "status")
        self.assertEqual(social["snap-camera"].learning_loop, "Clips")
        self.assertEqual(social["snap-viewer"].surface, "clips")
        self.assertEqual(social["x-feed-home"].learning_loop, "Square")
        self.assertEqual(social["ai_chat_select"].hub, "Speak")
        self.assertEqual(social["lingchat_ai"].hub, "Speak")
        self.assertNotEqual(social["lingchat_ai"].surface, "chat")
        text = route_map.render(rows)
        committed = (ROOT / "docs/build/design/ROUTE_MAP.csv").read_text(encoding="utf-8")
        self.assertEqual(committed, text)

    def test_check_command_prints_the_registered_count(self):
        result = subprocess.run(
            [sys.executable, str(SCRIPT), "--root", str(ROOT), "--check"],
            check=False,
            capture_output=True,
            text=True,
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("registered routes: ", result.stdout)
        count = int(result.stdout.split("registered routes: ", 1)[1].splitlines()[0])
        self.assertGreaterEqual(count, 120)
        self.assertLessEqual(count, 130)


if __name__ == "__main__":
    unittest.main()
