#!/usr/bin/env python3
"""T0: mechanical RTM segmentation of the converted sources (charter: v2).

Inputs : docs/source/ELEVATION.md, docs/source/CURRICULUM.md
Output : docs/build/rtm_parts/00_mechanical.csv (P0-*, F-* facets, D1-D5, UNV-*)
Side effects: overwrites that single file. Prose sections are extracted by
model passes into sibling CSVs; merge_rtm.py combines and validates them.

Row schema (shared by every rtm_parts CSV):
req_id, source_doc, anchor, type, verbatim_hook, priority, owner, card_ids, status
"""
from __future__ import annotations

import csv
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "source"
OUT = ROOT / "docs" / "build" / "rtm_parts" / "00_mechanical.csv"
FIELDS = ["req_id", "source_doc", "anchor", "type", "verbatim_hook", "priority", "owner", "card_ids", "status"]
HOOK_WORDS = 12
FEATURE_COUNT = 151
P0_COUNT = 27
DEEP_DIVE_LABELS = ("What it is.", "Code.", "Current state.", "Defects.", "Elevation.", "UX and render.", "Lives in.")
FACETS = {"Defects.": "D", "Elevation.": "E", "UX and render.": "U", "Lives in.": "L"}
UNVERIFIED_RE = re.compile(r"\[(verify[^\]]*|purchase[^\]]*|quote[^\]]*|Unverified[^\]]*|estimate[^\]]*)\]", re.I)


def hook(text: str) -> str:
    words = re.sub(r"\s+", " ", text).strip().split(" ")
    return " ".join(words[:HOOK_WORDS])


def load(name: str) -> list[str]:
    return (SRC / name).read_text(encoding="utf-8").splitlines()


def section_at(lines: list[str], idx: int, pattern: re.Pattern[str]) -> str:
    for back in range(idx, -1, -1):
        match = pattern.match(lines[back])
        if match:
            return match.group(1)
    return "?"


def p0_rows(lines: list[str]) -> list[dict]:
    rows: list[dict] = []
    starts = [(i, m) for i, line in enumerate(lines) if (m := re.match(r"^P0-(\d+) (.*)$", line)) and i < 420]
    for n, (i, m) in enumerate(starts):
        end = starts[n + 1][0] - 1 if n + 1 < len(starts) else i + 12
        block = " ".join(lines[i:end])
        rows.append(dict(req_id=f"P0-{m.group(1)}", source_doc="ELEVATION", anchor=f"§1:L{i+1}-L{end}",
                         type="requirement", verbatim_hook=hook(m.group(2) + " " + lines[i + 1] if i + 1 < len(lines) else m.group(2)),
                         priority="P0", owner="agent", card_ids="", status="Open"))
    assert len(rows) == P0_COUNT, f"expected {P0_COUNT} P0 rows, found {len(rows)}"
    return rows


def feature_rows(lines: list[str]) -> list[dict]:
    """Walk §18.2-§18.7; a feature block is a title line followed by 'What it is.'."""
    start = next(i for i, l in enumerate(lines) if l.startswith("18.2 Today hub"))
    hub_re = re.compile(r"^18\.(\d) (\w+) hub")
    rows: list[dict] = []
    titles: list[int] = []
    for i in range(start, len(lines) - 1):
        if not lines[i + 1].startswith("What it is."):
            continue
        # a page-break comment may sit between the title and its first label
        title_idx = i - 1 if lines[i].startswith("<!--") else i
        titles.append(title_idx)
    assert len(titles) == FEATURE_COUNT, f"expected {FEATURE_COUNT} features, found {len(titles)}"
    for n, t in enumerate(titles):
        end = titles[n + 1] - 1 if n + 1 < len(titles) else len(lines) - 1
        fid = f"F-{n+1:03d}"
        hub_match = section_at(lines, t, hub_re)
        hub = hub_re.match(hub_match).group(2) if hub_re.match(hub_match) else hub_match
        sub = section_at(lines, t, re.compile(r"^(18\.\d) "))
        rows.append(dict(req_id=fid, source_doc="ELEVATION", anchor=f"§{sub}:L{t+1}-L{end+1}", type="requirement",
                         verbatim_hook=hook(lines[t]), priority="P1", owner="agent", card_ids="", status="Open"))
        # facet sub-rows, each anchored to its own label line
        facet_lines = {label: i for i in range(t + 1, end + 1) for label in FACETS if lines[i].startswith(label)}
        for label, code in FACETS.items():
            if label not in facet_lines:
                continue
            li = facet_lines[label]
            text = lines[li][len(label):]
            rows.append(dict(req_id=f"{fid}.{code}", source_doc="ELEVATION", anchor=f"§{sub}:L{li+1}", type="requirement",
                             verbatim_hook=hook(f"[{hub}] {text}"), priority="P1", owner="agent", card_ids="", status="Open"))
    return rows


def decision_rows(lines: list[str]) -> list[dict]:
    start = next(i for i, l in enumerate(lines) if l.startswith("10. Decisions for Tope"))
    rows: list[dict] = []
    for i in range(start + 1, len(lines)):
        m = re.match(r"^([1-5])\. (.*)$", lines[i])
        if m:
            rows.append(dict(req_id=f"D{m.group(1)}", source_doc="CURRICULUM", anchor=f"§10:L{i+1}", type="decision",
                             verbatim_hook=hook(m.group(2)), priority="G0", owner="Tope", card_ids="", status="Open"))
    assert len(rows) == 5, rows
    return rows


# Lines that define or summarise the tags rather than carrying an item (0-based indices).
META_TAG_LINES = {"ELEVATION": {10, 2443, 5643}, "CURRICULUM": {863}}
SUBSECTION_RE = re.compile(r"^(\d{1,2}\.\d{1,2}) [A-Z]")
TOP_RE = re.compile(r"^(\d{1,2})\. [A-Z]")
MAX_HEADING_WORDS = 12  # numbered list items are full sentences; headings are short


def section_index(lines: list[str]) -> list[str]:
    """Section label per line. Subsection headings 'N.M Title' are unambiguous; a
    top-level 'N. Title' is accepted only when N follows the previous top level,
    which filters numbered list items."""
    labels: list[str] = []
    current, top = "pre", -1
    for line in lines:
        if m := SUBSECTION_RE.match(line):
            current = m.group(1)
            top = int(current.split(".")[0])
        elif (m := TOP_RE.match(line)) and int(m.group(1)) == top + 1 and len(line.split()) <= MAX_HEADING_WORDS:
            current = m.group(1)
            top = int(current)
        labels.append(current)
    return labels


def unverified_rows(doc: str, lines: list[str], sec_re: re.Pattern[str]) -> list[dict]:
    rows: list[dict] = []
    n = 0
    labels = section_index(lines)
    for i, line in enumerate(lines):
        if i in META_TAG_LINES[doc]:
            continue
        for m in UNVERIFIED_RE.finditer(line):
            n += 1
            sec = labels[i]
            rows.append(dict(req_id=f"UNV-{doc[0]}{n:02d}", source_doc=doc, anchor=f"§{sec}:L{i+1}", type="external",
                             verbatim_hook=hook(f"[{m.group(1)}] {line}"), priority="P1", owner="external", card_ids="", status="Open"))
    return rows


def main() -> int:
    elev, curr = load("ELEVATION.md"), load("CURRICULUM.md")
    sec_re = re.compile(r"^(\d{1,2}(?:\.\d{1,2})?)\.? [A-Z]")
    rows = p0_rows(elev) + feature_rows(elev) + decision_rows(curr)
    rows += unverified_rows("ELEVATION", elev, sec_re) + unverified_rows("CURRICULUM", curr, sec_re)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)
    kinds = {}
    for r in rows:
        kinds[r["req_id"].split("-")[0].split(".")[0]] = kinds.get(r["req_id"].split("-")[0].split(".")[0], 0) + 1
    print(f"{OUT.relative_to(ROOT)}: {len(rows)} rows {kinds}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
