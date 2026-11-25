#!/usr/bin/env python3
# charter: v2
"""P12-008: Report and gate deletion of superseded duplicate screens.

Usage:
  python3 scripts/ci/dead_screen_report.py [--root .] verify
  python3 scripts/ci/dead_screen_report.py [--root .] record-ledger [--note TEXT]

Exit codes:
  0  verify passed (no duplicate file with inbound import/route)
  1  blocked duplicate still referenced
  2  usage error
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path

CARD_ID = "P12-008"

# Authoritative consolidation pairs (replacement shipped; duplicate eligible for deletion).
CONSOLIDATIONS: tuple[tuple[str, str, str], ...] = (
    (
        "lib/screens/chat/global_chat_screen.dart",
        "lib/screens/chat/global_chat_screen_material3.dart",
        "P9-F-113",
    ),
    (
        "lib/screens/ai_chat/ai_chat_screen.dart",
        "lib/features/polie_workspace/polie_workspace_screen.dart",
        "P3-065",
    ),
    (
        "lib/screens/ai_chat/ai_chat_screen_new.dart",
        "lib/features/polie_workspace/polie_workspace_screen.dart",
        "P3-065",
    ),
    (
        "lib/screens/ai_chat/ai_chat_screen_with_tracking.dart",
        "lib/features/polie_workspace/polie_workspace_screen.dart",
        "P3-065",
    ),
    (
        "lib/screens/ai_chat/conversation_enhanced_screen.dart",
        "lib/features/polie_workspace/polie_workspace_screen.dart",
        "P3-065",
    ),
)

IMPORT_RE = re.compile(
    r"import\s+['\"](?:package:lingafriq/)?([^'\"]+)['\"]",
    re.MULTILINE,
)
PART_RE = re.compile(
    r"part\s+['\"](?:package:lingafriq/)?([^'\"]+)['\"]",
    re.MULTILINE,
)
EXPORT_RE = re.compile(
    r"export\s+['\"](?:package:lingafriq/)?([^'\"]+)['\"]",
    re.MULTILINE,
)


@dataclass(frozen=True)
class InboundRef:
    importer: str
    line_hint: str


def _normalize_path(rel: str) -> str:
    p = rel.replace("\\", "/")
    if p.startswith("lib/"):
        return p
    return f"lib/{p}" if not p.startswith("lib/") else p


def _resolve_import(root: Path, importer: Path, spec: str) -> str | None:
    spec = spec.strip()
    if spec.startswith("dart:"):
        return None
    if spec.startswith("package:") and not spec.startswith("package:lingafriq/"):
        return None
    if spec.startswith("package:lingafriq/"):
        spec = spec[len("package:lingafriq/") :]
    base = (importer.parent / spec).resolve()
    candidates = [base]
    if base.suffix != ".dart":
        candidates.append(Path(str(base) + ".dart"))
    for c in candidates:
        try:
            rel = c.relative_to(root)
        except ValueError:
            continue
        s = str(rel).replace("\\", "/")
        if s.startswith("lib/") and s.endswith(".dart"):
            return s
    return None


def collect_inbound_graph(root: Path) -> dict[str, list[InboundRef]]:
    graph: dict[str, list[InboundRef]] = {}
    lib = root / "lib"
    if not lib.is_dir():
        return graph
    for dart in lib.rglob("*.dart"):
        text = dart.read_text(encoding="utf-8", errors="replace")
        rel_importer = str(dart.relative_to(root)).replace("\\", "/")
        for regex in (IMPORT_RE, PART_RE, EXPORT_RE):
            for m in regex.finditer(text):
                target = _resolve_import(root, dart, m.group(1))
                if not target:
                    continue
                graph.setdefault(target, []).append(
                    InboundRef(importer=rel_importer, line_hint=m.group(0)[:80])
                )
    return graph


def route_table_text(root: Path) -> str:
    my_app = root / "lib/my_app.dart"
    if not my_app.is_file():
        return ""
    return my_app.read_text(encoding="utf-8", errors="replace")


def inbound_routes(root: Path, duplicate_rel: str) -> list[str]:
    """Heuristic: duplicate basename or legacy class name referenced in routes map."""
    text = route_table_text(root)
    if not text:
        return []
    base = Path(duplicate_rel).stem
    hits: list[str] = []
    # e.g. GlobalChatScreen without Material3
    legacy_class = "".join(p.capitalize() for p in base.replace("_screen", "").split("_"))
    if legacy_class.endswith("Screen") is False and base.endswith("_screen"):
        legacy_class = legacy_class + "Screen"
    for token in (base, legacy_class):
        if token and token in text:
            # Ignore if only the Material3 replacement mentions it
            if "Material3" in text and f"{legacy_class}Material3" in text:
                if token == legacy_class and f"const {legacy_class}(" in text:
                    hits.append(f"route_widget:{legacy_class}")
            elif f"/{token}" in text or f"'{token}'" in text:
                hits.append(f"route_key:{token}")
    return hits


def verify(root: Path) -> int:
    graph = collect_inbound_graph(root)
    blocked: list[str] = []
    for dup, replacement, card in CONSOLIDATIONS:
        dup_path = root / dup
        if dup_path.is_file():
            refs = graph.get(dup, [])
            routes = inbound_routes(root, dup)
            if refs or routes:
                blocked.append(
                    f"BLOCKED_INBOUND duplicate={dup} replacement={replacement} "
                    f"card={card} importers={[r.importer for r in refs]} routes={routes}"
                )
    if blocked:
        sys.stderr.write(f"{CARD_ID} dead_screen_report verify FAILED\n")
        for line in blocked:
            sys.stderr.write(line + "\n")
        return 1
    missing_replacement = [
        f"MISSING_REPLACEMENT {rep}"
        for dup, rep, _ in CONSOLIDATIONS
        if not (root / rep).is_file()
    ]
    if missing_replacement:
        sys.stderr.write(f"{CARD_ID} dead_screen_report verify FAILED\n")
        for line in missing_replacement:
            sys.stderr.write(line + "\n")
        return 1
    print(f"{CARD_ID} dead_screen_report: all consolidated duplicates absent or unreferenced")
    return 0


def record_ledger(root: Path, note: str) -> int:
    ledger_path = root / "scripts/ci/screen_consolidation_ledger.json"
    data: dict
    if ledger_path.is_file():
        data = json.loads(ledger_path.read_text(encoding="utf-8"))
    else:
        data = {"card": CARD_ID, "entries": []}
    entries = data.setdefault("entries", [])
    deleted_bytes = 0
    for dup, replacement, card in CONSOLIDATIONS:
        p = root / dup
        if p.is_file():
            deleted_bytes += p.stat().st_size
    apk_baseline = root / "scripts/ci/apk_size_baseline.json"
    apk_snapshot: dict | None = None
    if apk_baseline.is_file():
        apk_snapshot = json.loads(apk_baseline.read_text(encoding="utf-8"))
    entries.append(
        {
            "at": datetime.now(timezone.utc).isoformat(),
            "note": note,
            "deleted_source_bytes_removed": deleted_bytes,
            "apk_baseline_snapshot": apk_snapshot,
            "pairs": [{"duplicate": d, "replacement": r, "card": c} for d, r, c in CONSOLIDATIONS],
        }
    )
    ledger_path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    print(f"{CARD_ID} ledger appended: {ledger_path} (deleted_source_bytes_removed={deleted_bytes})")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Dead / superseded screen report (P12-008)")
    parser.add_argument("--root", type=Path, default=Path("."))
    parser.add_argument(
        "command",
        choices=("verify", "record-ledger"),
        help="verify graph or append APK/source ledger row",
    )
    parser.add_argument("--note", default="post-deletion verify")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    if args.command == "verify":
        return verify(root)
    return record_ledger(root, args.note)


if __name__ == "__main__":
    raise SystemExit(main())
