#!/usr/bin/env python3
"""Fail when source or content adds a placeholder, a sample token, or an empty field.

Usage:
  python3 scripts/ci/placeholder_lint.py [--patterns FILE] [--baseline FILE] [path ...]
  python3 scripts/ci/placeholder_lint.py --write-baseline FILE [path ...]

With no paths, scans lib/, the sibling node-backend tree, and the four legacy
content bundles. Lockfiles and dependency folders are skipped. A baseline count
lets a legacy file keep its current hits; a higher count fails and prints
path:line plus the rule id.
"""

from __future__ import annotations

import re
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_PATTERNS = ROOT / "scripts" / "ci" / "lint_patterns.yaml"
TEXT_SUFFIXES = frozenset({
    ".dart", ".ts", ".js", ".tsx", ".jsx", ".json", ".yaml", ".yml",
    ".arb", ".md", ".txt", ".csv", ".html",
})
CONTENT_SUFFIXES = frozenset({".json", ".yaml", ".yml", ".arb"})
SKIP_DIRS = frozenset({
    ".git", "node_modules", "build", ".dart_tool", "dist", "coverage",
    ".gradle", ".next", "Pods",
})
SKIP_NAMES = frozenset({"package-lock.json", "yarn.lock", "pubspec.lock"})

BUNDLE_DIRS = (
    "curriculum_bundle",
    "curriculum_expanded_bundle",
    "lingafriq_FINAL_curriculum",
    "lingafriq_full_curriculum_bundle",
)


@dataclass(frozen=True)
class Hit:
    path: str
    line: int
    rule: str
    span: str


@dataclass
class Patterns:
    placeholder: list[tuple[str, re.Pattern[str]]]
    empty_field_id: str
    empty_field: re.Pattern[str] | None
    claims: list[tuple[str, re.Pattern[str]]]
    tone_id: str
    lesson_id: str
    tone_statement: re.Pattern[str] | None
    tone_window: int
    lesson_key: re.Pattern[str] | None
    source_lexicon: re.Pattern[str] | None
    source_corpus: re.Pattern[str] | None
    source_licence: re.Pattern[str] | None
    source_person: re.Pattern[str] | None
    source_date: re.Pattern[str] | None
    source_media: re.Pattern[str] | None
    source_span: re.Pattern[str] | None
    runtime_provenance: re.Pattern[str] | None
    allowlist: list[dict[str, str]]


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        value = value[1:-1]
    return value.replace("\\d", r"\d").replace("\\s", r"\s")


def load_patterns(path: Path) -> Patterns:
    """Load the subset of YAML this linter writes. No PyYAML dependency."""
    placeholder: list[tuple[str, str]] = []
    claims: list[tuple[str, str]] = []
    allowlist: list[dict[str, str]] = []
    scalars: dict[str, str] = {}
    section: str | None = None
    current: dict[str, str] | None = None
    bucket: list | None = None

    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.split("#", 1)[0].rstrip()
        if not line.strip():
            continue
        if not line.startswith(" ") and not line.startswith("\t") and line.endswith(":") is False and ":" in line and not line.startswith("-"):
            key, value = line.split(":", 1)
            scalars[key.strip()] = _unquote(value)
            section = None
            current = None
            continue
        if re.match(r"^[A-Za-z0-9_]+:\s*$", line):
            section = line.split(":", 1)[0]
            current = None
            if section == "placeholder_rules":
                bucket = placeholder
            elif section == "claim_rules":
                bucket = claims
            elif section == "allowlist":
                bucket = allowlist
            else:
                bucket = None
            continue
        item = line.strip()
        if item.startswith("- "):
            current = {}
            if bucket is not None and section in {"placeholder_rules", "claim_rules", "allowlist"}:
                bucket.append(current)
            body = item[2:]
            if ":" in body:
                key, value = body.split(":", 1)
                current[key.strip()] = _unquote(value)
            continue
        if current is not None and ":" in item:
            key, value = item.split(":", 1)
            current[key.strip()] = _unquote(value)

    def compiled(pairs: list[tuple[str, str]]) -> list[tuple[str, re.Pattern[str]]]:
        return [(rule_id, re.compile(pattern, re.IGNORECASE)) for rule_id, pattern in pairs]

    placeholder_pairs = [(item["id"], item["pattern"]) for item in placeholder if item.get("id") and item.get("pattern")]
    claim_pairs = [(item["id"], item["pattern"]) for item in claims if item.get("id") and item.get("pattern")]
    keys = [k.strip() for k in scalars.get("empty_field_keys", "").split(",") if k.strip()]
    empty = None
    if keys:
        joined = "|".join(re.escape(k) for k in keys)
        empty = re.compile(
            rf"""(?ix)
            (?:
              ["'](?:{joined})["']\s*:\s*(?:["']\s*["']|null)
              |
              ^(?:{joined})\s*:\s*(?:["']\s*["']|null|~)?\s*$
            )
            """
        )
    def compiled_scalar(key: str) -> re.Pattern[str] | None:
        value = scalars.get(key)
        return re.compile(value, re.IGNORECASE) if value else None

    tone_statement = compiled_scalar("tone_statement")
    lesson_names = scalars.get("lesson_key")
    lesson_key = (
        re.compile(rf'"(?:{lesson_names})"\s*:', re.IGNORECASE) if lesson_names else None
    )
    return Patterns(
        placeholder=compiled(placeholder_pairs),
        empty_field_id=scalars.get("empty_field_id", "empty_field"),
        empty_field=empty,
        claims=compiled(claim_pairs),
        tone_id=scalars.get("tone_id", "claim.tone_without_source"),
        lesson_id=scalars.get("lesson_id", "claim.lesson_without_source"),
        tone_statement=tone_statement,
        tone_window=int(scalars.get("tone_window_lines", "40")),
        lesson_key=lesson_key,
        source_lexicon=compiled_scalar("source_lexicon"),
        source_corpus=compiled_scalar("source_corpus"),
        source_licence=compiled_scalar("source_licence"),
        source_person=compiled_scalar("source_person"),
        source_date=compiled_scalar("source_date"),
        source_media=compiled_scalar("source_media"),
        source_span=compiled_scalar("source_span"),
        runtime_provenance=compiled_scalar("runtime_provenance"),
        allowlist=[item for item in allowlist if isinstance(item, dict)],
    )


def rel_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        return resolved.relative_to(ROOT).as_posix()
    except ValueError:
        pass
    sibling = (ROOT.parent / "node-backend").resolve()
    try:
        return "node-backend/" + resolved.relative_to(sibling).as_posix()
    except ValueError:
        return resolved.as_posix()


def default_roots() -> list[Path]:
    roots = [ROOT / "lib", ROOT / "assets" / "data", ROOT.parent / "node-backend"]
    roots.extend(ROOT / name for name in BUNDLE_DIRS)
    return [p for p in roots if p.exists()]


def curriculum_roots() -> list[Path]:
    """Bundled curriculum only. Runtime Import Media lessons are not in this list."""
    roots = [ROOT / "assets" / "data"]
    roots.extend(ROOT / name for name in BUNDLE_DIRS)
    return [p for p in roots if p.exists()]


def walk_files(root: Path):
    if root.is_file():
        if root.name not in SKIP_NAMES and root.suffix.lower() in TEXT_SUFFIXES:
            yield root
        return
    for dirpath, dirnames, filenames in __import__("os").walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".")]
        for name in filenames:
            if name in SKIP_NAMES or name.endswith(".lock"):
                continue
            path = Path(dirpath) / name
            if path.suffix.lower() in TEXT_SUFFIXES:
                yield path


def allowlist_covers(hit: Hit, entries: list[dict[str, str]]) -> bool:
    for entry in entries:
        reason = (entry.get("reason") or "").strip()
        owner = (entry.get("owner") or "").strip()
        if not reason or not owner:
            continue
        if entry.get("rule") != hit.rule:
            continue
        if (entry.get("span") or "").casefold() != hit.span.casefold():
            continue
        wanted = entry.get("path") or ""
        if hit.path == wanted or hit.path.endswith("/" + wanted):
            return True
    return False


def placeholder_hits(path: Path, patterns: Patterns) -> list[Hit]:
    rel = rel_path(path)
    hits: list[Hit] = []
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return hits
    check_empty = patterns.empty_field is not None and path.suffix.lower() in CONTENT_SUFFIXES
    for number, line in enumerate(lines, 1):
        for rule_id, pattern in patterns.placeholder:
            for match in pattern.finditer(line):
                hits.append(Hit(rel, number, rule_id, match.group(0)))
        if check_empty and patterns.empty_field.search(line):
            hits.append(Hit(rel, number, patterns.empty_field_id, line.strip()[:120]))
    return hits


def _value_after(label: re.Pattern[str], text: str, value: str) -> bool:
    return re.search(
        r"(?:" + label.pattern + r")\s*\"?\s*[:=]\s*\"?" + value,
        text,
        re.IGNORECASE,
    ) is not None


def is_runtime_lesson(path: Path, text: str, patterns: Patterns) -> bool:
    """Import Media lessons live outside the bundled curriculum and are not a CI failure."""
    if patterns.runtime_provenance is None or patterns.runtime_provenance.search(text) is None:
        return False
    resolved = path.resolve()
    for root in curriculum_roots():
        try:
            resolved.relative_to(root.resolve())
            return False
        except ValueError:
            continue
    return True


def has_citation(nearby: str, patterns: Patterns) -> bool:
    """A lexicon entry, a licensed corpus item, a named native speaker with a date, or Import Media."""
    if patterns.source_lexicon is not None and patterns.source_lexicon.search(nearby):
        return True
    if (
        patterns.source_corpus is not None
        and patterns.source_licence is not None
        and patterns.source_corpus.search(nearby)
        and patterns.source_licence.search(nearby)
    ):
        return True
    if (
        patterns.source_person is not None
        and patterns.source_date is not None
        and _value_after(patterns.source_person, nearby, r"[A-Za-z0-9][A-Za-z0-9_.-]*")
        and _value_after(patterns.source_date, nearby, r"\d{4}-\d{2}-\d{2}")
    ):
        return True
    if (
        patterns.source_media is not None
        and patterns.source_span is not None
        and _value_after(patterns.source_media, nearby, r"[A-Za-z0-9][A-Za-z0-9_.-]*")
        and _value_after(patterns.source_span, nearby, r"\S+")
    ):
        return True
    return False


def claim_hits(path: Path, patterns: Patterns) -> list[Hit]:
    rel = rel_path(path)
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return []
    if is_runtime_lesson(path, "\n".join(lines), patterns):
        return []
    hits: list[Hit] = []
    window = patterns.tone_window
    lesson_at: int | None = None
    for number, line in enumerate(lines, 1):
        for rule_id, pattern in patterns.claims:
            for match in pattern.finditer(line):
                hits.append(Hit(rel, number, rule_id, match.group(0)))
        if patterns.lesson_key is not None and patterns.lesson_key.search(line):
            lesson_at = number
        is_tone = patterns.tone_statement is not None and patterns.tone_statement.search(line) is not None
        is_lesson = (
            not is_tone
            and lesson_at is not None
            and number - lesson_at <= 8
            and re.search(r'"[^"]{12,}"', line) is not None
        )
        if not is_tone and not is_lesson:
            continue
        start = max(0, number - 1 - window)
        end = min(len(lines), number - 1 + window + 1)
        if has_citation("\n".join(lines[start:end]), patterns):
            continue
        if is_tone and patterns.tone_statement is not None:
            match = patterns.tone_statement.search(line)
            span = line.strip() if len(line.strip()) <= 200 else (match.group(0) if match else line.strip())
            hits.append(Hit(rel, number, patterns.tone_id, span))
        else:
            quoted = re.search(r'"([^"]{12,})"', line)
            span = quoted.group(1) if quoted else line.strip()[:200]
            hits.append(Hit(rel, number, patterns.lesson_id, span))
    return hits


def parse_args(
    argv: list[str],
    empty_paths: list[Path] | None = None,
) -> tuple[Path, Path | None, Path | None, list[Path]]:
    patterns = DEFAULT_PATTERNS
    baseline: Path | None = None
    write: Path | None = None
    paths: list[Path] = []
    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--patterns":
            i += 1
            patterns = Path(argv[i])
        elif arg == "--baseline":
            i += 1
            baseline = Path(argv[i])
        elif arg == "--write-baseline":
            i += 1
            write = Path(argv[i])
        elif arg.startswith("-"):
            print(f"unknown argument: {arg}", file=sys.stderr)
            raise SystemExit(2)
        else:
            paths.append(Path(arg))
        i += 1
    if not paths:
        paths = list(empty_paths) if empty_paths is not None else default_roots()
    return patterns, baseline, write, paths


def load_baseline(path: Path | None) -> dict[tuple[str, str], int]:
    if path is None:
        return {}
    counts: dict[tuple[str, str], int] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line or line.startswith("#"):
            continue
        file_path, rule, count = line.split("\t")
        counts[(file_path, rule)] = int(count)
    return counts


def report(hits: list[Hit], patterns: Patterns, baseline: Path | None, write: Path | None) -> int:
    kept = [hit for hit in hits if not allowlist_covers(hit, patterns.allowlist)]
    grouped: dict[tuple[str, str], list[Hit]] = defaultdict(list)
    for hit in kept:
        grouped[(hit.path, hit.rule)].append(hit)
    if write is not None:
        rows = [f"{path}\t{rule}\t{len(group)}" for (path, rule), group in sorted(grouped.items())]
        write.parent.mkdir(parents=True, exist_ok=True)
        write.write_text("\n".join(rows) + ("\n" if rows else ""), encoding="utf-8")
        print(f"wrote {len(rows)} baseline rows to {write}")
        return 0
    limits = load_baseline(baseline)
    failed = False
    for key in sorted(grouped):
        group = grouped[key]
        limit = limits.get(key, 0)
        if len(group) <= limit:
            continue
        failed = True
        shown = group if limit == 0 else group[:20]
        for hit in shown:
            print(f"{hit.path}:{hit.line} {hit.rule} {hit.span}")
        print(f"{key[0]} {key[1]} baseline {limit} now {len(group)}")
    return 1 if failed else 0


def scan(paths: list[Path], patterns: Patterns, collector) -> list[Hit]:
    hits: list[Hit] = []
    for root in paths:
        if not root.exists():
            print(f"path not found: {root}", file=sys.stderr)
            raise SystemExit(2)
        for path in walk_files(root):
            hits.extend(collector(path, patterns))
    return hits


def main(argv: list[str]) -> int:
    patterns_path, baseline, write, paths = parse_args(argv)
    if not patterns_path.is_file():
        print(f"patterns not found: {patterns_path}", file=sys.stderr)
        return 2
    patterns = load_patterns(patterns_path)
    hits = scan(paths, patterns, placeholder_hits)
    return report(hits, patterns, baseline, write)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
