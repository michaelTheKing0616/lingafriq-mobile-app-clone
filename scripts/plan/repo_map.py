#!/usr/bin/env python3
"""Generate docs/build/REPO_MAP.md — static analysis of lib/, backend, RTM hooks (P0-INT-08)."""
from __future__ import annotations

import argparse
import csv
import re
import sys
from collections import deque
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "lib"
RTM = ROOT / "docs/build/RTM.csv"
OUT = ROOT / "docs/build/REPO_MAP.md"
MY_APP = LIB / "my_app.dart"
MAIN = LIB / "main.dart"

SOURCE_REACHABLE = 330
SOURCE_NEVER_IMPORTED = 183
SOURCE_UNREACHABLE_SCREENS = 88
SOURCE_LINE_TOTAL = 49_074
SOURCE_FLUTTER_TESTS = 64
SOURCE_BACKEND_TESTS = 52

IMPORT_RE = re.compile(
    r"^\s*import\s+"
    r"(?:'([^']+)'|\"([^\"]+)\")",
    re.MULTILINE,
)
EXPORT_RE = re.compile(
    r"^\s*export\s+"
    r"(?:'([^']+)'|\"([^\"]+)\")",
    re.MULTILINE,
)
ROUTE_KEY_RE = re.compile(r"'([^']+)'\s*:\s*\(_\)\s*=>\s*const\s+(\w+)\(\)")
ROUTE_KEY_RE2 = re.compile(r"'([^']+)'\s*:\s*\(_\)\s*=>\s*(\w+)\(")
SCREEN_CLASS_RE = re.compile(r"class\s+(\w+Screen)\b")
PROVIDER_CLASS_RE = re.compile(r"class\s+(\w+)\s+extends\s+(?:\w+\s+)?(?:ChangeNotifier|Notifier)")
DART_FILE_RE = re.compile(r"[\w/]+\.dart")
EP2_RE = re.compile(r"^EP-§2-(\d{2})$")
FEATURE_RE = re.compile(r"^F-(\d{3})$")

SOCIAL_LOOP: dict[str, str] = {
    "wa_status": "F-128 Language Status",
    "wa_starred": "F-129 Saved phrases",
    "wa_media": "F-129 Saved phrases",
    "snap_": "F-130 Snaps & Streaks",
    "x_feed": "F-131 Community Feed",
    "x_compose": "F-133 Create Content",
    "x_explore": "F-132 Explore & Search",
    "x_lists": "F-132 Explore & Search",
    "x_post": "F-131 Community Feed",
    "x_profile": "F-132 Community Profile",
}


@dataclass(frozen=True)
class GraphStats:
    reachable: set[Path]
    all_dart: set[Path]
    never_imported: set[Path]
    import_edges: dict[Path, set[Path]]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _lib_path_from_import(importer: Path, spec: str) -> Path | None:
    if spec.startswith("package:lingafriq/"):
        rel = spec.split("package:lingafriq/", 1)[1]
        return (LIB / rel).resolve()
    if spec.startswith("dart:") or spec.startswith("package:flutter") or spec.startswith("package:"):
        return None
    if spec.startswith("package:"):
        return None
    base = (importer.parent / spec).resolve()
    if base.suffix == ".dart" and base.is_file():
        return base
    cand = base.with_suffix(".dart")
    if cand.is_file():
        return cand
    return None


def collect_dart_files(root: Path) -> set[Path]:
    if not root.is_dir():
        return set()
    return {p.resolve() for p in root.rglob("*.dart") if p.is_file()}


def build_import_graph(lib_root: Path) -> tuple[dict[Path, set[Path]], set[Path]]:
    all_files = collect_dart_files(lib_root)
    edges: dict[Path, set[Path]] = {f: set() for f in all_files}
    for path in all_files:
        text = _read(path)
        for m in IMPORT_RE.finditer(text):
            spec = m.group(1) or m.group(2)
            tgt = _lib_path_from_import(path, spec)
            if tgt and tgt in all_files:
                edges[path].add(tgt)
        for m in EXPORT_RE.finditer(text):
            spec = m.group(1) or m.group(2)
            tgt = _lib_path_from_import(path, spec)
            if tgt and tgt in all_files:
                edges[path].add(tgt)
    return edges, all_files


def reachable_from(entry: Path, edges: dict[Path, set[Path]]) -> set[Path]:
    if not entry.is_file():
        return set()
    seen: set[Path] = set()
    q: deque[Path] = deque([entry.resolve()])
    while q:
        cur = q.popleft()
        if cur in seen:
            continue
        seen.add(cur)
        for nxt in edges.get(cur, ()):
            if nxt not in seen:
                q.append(nxt)
    return seen


def count_lines(paths: Iterable[Path]) -> int:
    total = 0
    for p in paths:
        try:
            total += len(_read(p).splitlines())
        except OSError:
            pass
    return total


def parse_routes(my_app: Path) -> list[tuple[str, str]]:
    if not my_app.is_file():
        return []
    text = _read(my_app)
    routes: list[tuple[str, str]] = []
    for m in ROUTE_KEY_RE.finditer(text):
        routes.append((m.group(1), m.group(2)))
    for m in ROUTE_KEY_RE2.finditer(text):
        pair = (m.group(1), m.group(2))
        if pair not in routes:
            routes.append(pair)
    return sorted(routes, key=lambda x: x[0])


def list_screens(lib_root: Path) -> dict[str, Path]:
    out: dict[str, Path] = {}
    for path in collect_dart_files(lib_root):
        for m in SCREEN_CLASS_RE.finditer(_read(path)):
            out.setdefault(m.group(1), path)
    return out


def list_providers(lib_root: Path) -> dict[str, Path]:
    out: dict[str, Path] = {}
    prov_dir = lib_root / "providers"
    files = collect_dart_files(prov_dir) if prov_dir.is_dir() else set()
    for path in files | collect_dart_files(lib_root):
        rel = path.relative_to(lib_root).as_posix()
        if "/providers/" not in rel and not rel.startswith("providers/"):
            if "provider" not in path.name.lower():
                continue
        for m in PROVIDER_CLASS_RE.finditer(_read(path)):
            out.setdefault(m.group(1), path)
    return out


def load_rtm() -> dict[str, dict[str, str]]:
    rows: dict[str, dict[str, str]] = {}
    with RTM.open(encoding="utf-8", newline="") as fh:
        for row in csv.DictReader(fh):
            rows[row["req_id"]] = row
    return rows


def ep2_status_word(hook: str) -> str:
    for word in ("Not built yet", "Broken", "Fake", "Partial"):
        if word.lower() in hook.lower():
            return word
    return "Partial"


def map_ep2_area(req_id: str, hook: str, lib_root: Path) -> str:
    files = DART_FILE_RE.findall(hook)
    hits: list[str] = []
    for name in files:
        base = name.split("/")[-1]
        for p in lib_root.rglob(base):
            hits.append(p.relative_to(lib_root).as_posix())
    if hits:
        return ", ".join(sorted(set(hits))[:8])
    status = ep2_status_word(hook)
    return f"NOT-BUILT ({status})"


def rev_dev_path(hook: str, lib_root: Path) -> tuple[str, str]:
    files = DART_FILE_RE.findall(hook)
    if files:
        for name in files:
            for p in lib_root.rglob(name.split("/")[-1]):
                rel = p.relative_to(lib_root).as_posix()
                return rel, "mapped"
        return files[0], "file-not-found"
    # keyword search from title fragment after comma in some rows
    title = hook.split(",")[-1].strip() if "," in hook else hook
    tokens = [t.lower() for t in re.findall(r"[a-z]{4,}", title)]
    best: Path | None = None
    for p in lib_root.rglob("*.dart"):
        stem = p.stem.lower()
        if any(t in stem for t in tokens[:3]):
            best = p
            break
    if best:
        return best.relative_to(lib_root).as_posix(), "keyword"
    return "NOT-MAPPED", "none"


def social_learning_link(path: Path) -> str:
    name = path.name.lower()
    for prefix, link in SOCIAL_LOOP.items():
        if prefix in name:
            return link
    if "/wa/" in path.as_posix():
        return "F-128 Language Status"
    if "/snap/" in path.as_posix():
        return "F-130 Snaps & Streaks"
    if "/feed/" in path.as_posix() or name.startswith("x_"):
        return "F-131 Community Feed"
    return "NONE"


def feature_row(
    fid: str,
    rtm: dict[str, dict[str, str]],
    screens: dict[str, Path],
    routes: list[tuple[str, str]],
    reachable: set[Path],
) -> tuple[str, str, str]:
    base = rtm.get(fid, {})
    title = base.get("verbatim_hook", fid).split(",")[0]
    lives = rtm.get(f"{fid}.L", {}).get("verbatim_hook", "")
    screen_path = ""
    route_name = ""
    tokens = re.findall(r"[a-z]{4,}", title.lower())
    for cls, path in screens.items():
        stem = path.stem.lower()
        if any(t in stem for t in tokens[:2]):
            screen_path = path.relative_to(LIB).as_posix()
            break
    for rname, cls in routes:
        if tokens and tokens[0] in rname.replace("-", "_"):
            route_name = rname
            break
    reach = "reachable" if screen_path and (LIB / screen_path).resolve() in reachable else (
        "unreachable" if screen_path else "n/a"
    )
    if not screen_path:
        screen_path = "MISSING"
    return fid, title[:80], f"{screen_path} | route={route_name or '-'} | {reach}"


def scan_backend(backend_root: Path) -> tuple[list[str], list[str], bool]:
    if not backend_root.is_dir():
        return [], [], False
    routes: list[str] = []
    sockets: list[str] = []
    routes_dir = backend_root / "src/routes"
    if routes_dir.is_dir():
        for path in routes_dir.rglob("*.ts"):
            text = _read(path)
            for m in re.finditer(r'router\.(?:get|post|put|patch|delete)\(\s*["\']([^"\']+)', text):
                routes.append(f"{path.relative_to(backend_root).as_posix()}: {m.group(1)}")
            for m in re.finditer(r'\.on\(\s*["\']([^"\']+)', text):
                sockets.append(f"{path.relative_to(backend_root).as_posix()}: {m.group(1)}")
    idx = backend_root / "src/routes/index.route.ts"
    if idx.is_file():
        text = _read(idx)
        for m in re.finditer(r'router\.use\(\s*["\']([^"\']+)', text):
            routes.append(f"mount: {m.group(1)}")
    return sorted(set(routes)), sorted(set(sockets)), True


def count_tests() -> tuple[int, int]:
    flutter = len(list((ROOT / "test").rglob("*_test.dart"))) if (ROOT / "test").is_dir() else 0
    backend_root = ROOT.parent / "node-backend"
    backend = (
        len(list(backend_root.rglob("*.test.ts")))
        + len(list(backend_root.rglob("*.spec.ts")))
        if backend_root.is_dir()
        else 0
    )
    return flutter, backend


def analyze(lib_root: Path, entry: Path, backend_root: Path | None) -> tuple[GraphStats, list[tuple[str, str]], dict]:
    edges, all_dart = build_import_graph(lib_root)
    reachable = reachable_from(entry, edges)
    imported_by: dict[Path, set[Path]] = {f: set() for f in all_dart}
    for src, tgts in edges.items():
        for t in tgts:
            imported_by.setdefault(t, set()).add(src)
    never_imported = {f for f in all_dart if f != entry.resolve() and not imported_by.get(f)}
    return (
        GraphStats(reachable=reachable, all_dart=all_dart, never_imported=never_imported, import_edges=edges),
        parse_routes(MY_APP),
        {"screens": list_screens(lib_root), "providers": list_providers(lib_root)},
    )


def render_markdown(
    stats: GraphStats,
    routes: list[tuple[str, str]],
    meta: dict,
    rtm: dict[str, dict[str, str]],
    backend_routes: list[str],
    backend_sockets: list[str],
    backend_present: bool,
    flutter_tests: int,
    backend_tests: int,
) -> str:
    screens: dict[str, Path] = meta["screens"]
    providers: dict[str, Path] = meta["providers"]
    reachable_files = stats.reachable
    unreachable_files = stats.all_dart - reachable_files
    screen_files = {p.resolve() for p in screens.values()}
    unreachable_screens = [cls for cls, p in screens.items() if p.resolve() not in reachable_files]

    lines_reachable = count_lines(reachable_files)
    lines_unreachable = count_lines(unreachable_files)

    parts: list[str] = [
        "# REPO_MAP",
        "",
        "Generated by `python3 scripts/plan/repo_map.py`. Charter v2 / P0-INT-08.",
        "",
        "## Reachability delta (source ELEVATION §0)",
        "",
        "| Metric | Source | Current | Δ |",
        "| --- | ---: | ---: | ---: |",
        f"| Reachable Dart files (from main.dart) | {SOURCE_REACHABLE} | {len(reachable_files)} | {len(reachable_files) - SOURCE_REACHABLE} |",
        f"| Dart files imported by nothing | {SOURCE_NEVER_IMPORTED} | {len(stats.never_imported)} | {len(stats.never_imported) - SOURCE_NEVER_IMPORTED} |",
        f"| Unreachable screen classes | {SOURCE_UNREACHABLE_SCREENS} | {len(unreachable_screens)} | {len(unreachable_screens) - SOURCE_UNREACHABLE_SCREENS} |",
        f"| Lines in unreachable files | {SOURCE_LINE_TOTAL:,} | {lines_unreachable:,} | {lines_unreachable - SOURCE_LINE_TOTAL:,} |",
        "",
        f"Reachable lines total: {lines_reachable:,}.",
        "",
        "## Routes (`lib/my_app.dart`)",
        "",
        "| Route | Screen class |",
        "| --- | --- |",
    ]
    for rname, cls in routes:
        parts.append(f"| `{rname}` | `{cls}` |")
    parts.extend(["", "## Screens", "", "| Screen class | File | Reachable |", "| --- | --- | --- |"])
    for cls in sorted(screens):
        p = screens[cls]
        rel = p.relative_to(LIB).as_posix()
        reach = "yes" if p.resolve() in reachable_files else "no"
        parts.append(f"| `{cls}` | `{rel}` | {reach} |")

    parts.extend(["", "## Providers", "", "| Provider | File |", "| --- | --- |"])
    for name in sorted(providers):
        rel = providers[name].relative_to(LIB).as_posix()
        parts.append(f"| `{name}` | `{rel}` |")

    parts.extend(["", "## Feature areas EP-§2-01…44", "", "| Area | Mapping |", "| --- | --- |"])
    for i in range(1, 45):
        rid = f"EP-§2-{i:02d}"
        hook = rtm.get(rid, {}).get("verbatim_hook", "")
        parts.append(f"| `{rid}` | {map_ep2_area(rid, hook, LIB)} |")

    parts.extend(["", "## Revival screens REV-01…25", "", "| ID | Title | File | Reachable |", "| --- | --- | --- | --- |"])
    for i in range(1, 26):
        rid = f"REV-{i:02d}"
        hook = rtm.get(rid, {}).get("verbatim_hook", "")
        title = hook.split(",")[-1].strip() if hook else rid
        path, _ = rev_dev_path(hook, LIB)
        reach = "n/a"
        if path not in ("NOT-MAPPED",) and not path.endswith(".dart") and "/" in path:
            reach = "yes" if (LIB / path).resolve() in reachable_files else "no"
        elif path.endswith(".dart"):
            cand = LIB / path
            if cand.is_file():
                reach = "yes" if cand.resolve() in reachable_files else "no"
        parts.append(f"| `{rid}` | {title[:60]} | `{path}` | {reach} |")

    parts.extend(["", "## Developer examples DEV-01…03", "", "| ID | File | Reachable |", "| --- | --- | --- |"])
    for i in range(1, 4):
        rid = f"DEV-{i:02d}"
        hook = rtm.get(rid, {}).get("verbatim_hook", "")
        path, _ = rev_dev_path(hook, LIB)
        reach = "n/a"
        cand = LIB / path if not path.startswith("NOT") else None
        if cand and cand.is_file():
            reach = "yes" if cand.resolve() in reachable_files else "no"
        parts.append(f"| `{rid}` | `{path}` | {reach} |")

    parts.extend(["", "## Features F-001…151 (user-facing)", "", "| Feature | Title | Screen / route |", "| --- | --- | --- |"])
    for n in range(1, 152):
        fid = f"F-{n:03d}"
        title, detail = feature_row(fid, rtm, screens, routes, reachable_files)[1:]
        parts.append(f"| `{fid}` | {title} | {detail} |")

    parts.extend(["", "## Social-pattern screens (wa / snap / x)", "", "| File | Learning-loop link | Reachable |", "| --- | --- | --- |"])
    social_paths = sorted(
        p for p in collect_dart_files(LIB)
        if "/wa/" in p.as_posix() or "/snap/" in p.as_posix() or "/feed/" in p.as_posix() or re.search(r"/x_", p.name)
    )
    for p in social_paths:
        rel = p.relative_to(LIB).as_posix()
        parts.append(
            f"| `{rel}` | {social_learning_link(p)} | {'yes' if p in reachable_files else 'no'} |"
        )

    parts.extend(["", "## Tests", "", "| Suite | Source figure | Current | Δ |", "| --- | ---: | ---: | ---: |"])
    parts.append(f"| Flutter `*_test.dart` | {SOURCE_FLUTTER_TESTS} | {flutter_tests} | {flutter_tests - SOURCE_FLUTTER_TESTS} |")
    parts.append(f"| Backend `*.test.ts` | {SOURCE_BACKEND_TESTS} | {backend_tests} | {backend_tests - SOURCE_BACKEND_TESTS} |")

    parts.extend(["", "## Backend routes & sockets", ""])
    if not backend_present:
        parts.append("**BACKEND-NOT-IN-REPO** — section unmapped (configure `--backend` or sibling `node-backend`).")
    else:
        parts.append("### HTTP routes (sample)")
        for line in backend_routes[:400]:
            parts.append(f"- `{line}`")
        if len(backend_routes) > 400:
            parts.append(f"- … {len(backend_routes) - 400} more")
        parts.append("")
        parts.append("### Socket events (sample)")
        for line in backend_sockets[:200]:
            parts.append(f"- `{line}`")
        if not backend_sockets:
            parts.append("- _(none found in src/routes scan)_")

    return "\n".join(parts) + "\n"


def walk_import_graph(edges: dict[Path, set[Path]], entry: Path) -> set[Path]:
    return reachable_from(entry, edges)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--lib", type=Path, default=LIB)
    parser.add_argument("--entry", type=Path, default=MAIN)
    parser.add_argument("--backend", type=Path, default=ROOT.parent / "node-backend")
    parser.add_argument("--out", type=Path, default=OUT)
    parser.add_argument("--stdout", action="store_true")
    args = parser.parse_args(argv)

    if not args.entry.is_file():
        print(f"missing entry {args.entry}", file=sys.stderr)
        return 1

    stats, routes, meta = analyze(args.lib, args.entry, args.backend)
    rtm = load_rtm()
    br, bs, bp = scan_backend(args.backend)
    ft, bt = count_tests()
    md = render_markdown(stats, routes, meta, rtm, br, bs, bp, ft, bt)
    if args.stdout:
        print(md, end="")
    else:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(md, encoding="utf-8")
        print(f"Wrote {args.out.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
