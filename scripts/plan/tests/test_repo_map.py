"""Unit tests for scripts/plan/repo_map.py (P0-INT-08)."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

_PLAN = Path(__file__).resolve().parents[1]
_spec = importlib.util.spec_from_file_location("repo_map", _PLAN / "repo_map.py")
rm = importlib.util.module_from_spec(_spec)
assert _spec and _spec.loader
sys.modules["repo_map"] = rm
_spec.loader.exec_module(rm)


def test_import_graph_fixture_cycle_and_orphan(tmp_path: Path) -> None:
    lib = tmp_path / "lib"
    lib.mkdir()
    (lib / "main.dart").write_text(
        "import 'a.dart';\nimport 'package:flutter/material.dart';\n",
        encoding="utf-8",
    )
    (lib / "a.dart").write_text("import 'b.dart';\n", encoding="utf-8")
    (lib / "b.dart").write_text("import 'a.dart';\n", encoding="utf-8")
    (lib / "orphan.dart").write_text("// alone\n", encoding="utf-8")
    edges, all_dart = rm.build_import_graph(lib)
    reach = rm.walk_import_graph(edges, lib / "main.dart")
    assert (lib / "main.dart").resolve() in reach
    assert (lib / "a.dart").resolve() in reach
    assert (lib / "b.dart").resolve() in reach
    assert (lib / "orphan.dart").resolve() not in reach
    assert len(all_dart) == 4


def test_real_repo_map_sections_present() -> None:
    stats, routes, meta = rm.analyze(rm.LIB, rm.MAIN, rm.ROOT.parent / "node-backend")
    rtm = rm.load_rtm()
    br, bs, bp = rm.scan_backend(rm.ROOT.parent / "node-backend")
    ft, bt = rm.count_tests()
    md = rm.render_markdown(stats, routes, meta, rtm, br, bs, bp, ft, bt)
    for header in (
        "## Reachability delta",
        "## Routes",
        "## Feature areas EP-§2-01…44",
        "## Revival screens REV-01…25",
        "## Features F-001…151",
        "## Social-pattern screens",
        "## Tests",
        "## Backend routes & sockets",
    ):
        assert header in md
    assert "| `F-001` |" in md
    assert "| `REV-01` |" in md
    assert "| `EP-§2-01` |" in md
    assert len(routes) > 50
    if bp:
        assert "mount:" in md or "router" in md
    else:
        assert "BACKEND-NOT-IN-REPO" in md
