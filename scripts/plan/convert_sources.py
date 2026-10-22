#!/usr/bin/env python3
"""T0: convert source PDFs to anchored Markdown once (charter: v2).

Inputs : PDFs in docs/source/*.pdf (copied from Downloads by the caller).
Outputs: docs/source/ELEVATION.md, docs/source/CURRICULUM.md, docs/source/ANCHORS.txt
Side effects: overwrites the three outputs. Never run a second time without reason.
"""
from __future__ import annotations

import re
import sys
import unicodedata
from pathlib import Path

from pypdf import PdfReader

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "docs" / "source"
SOURCES = {
    "ELEVATION": "LINGAFRIQ_ELEVATION_PLAN_3.pdf",
    "CURRICULUM": "LINGAFRIQ_CURRICULUM_PLAN.pdf",
}
# Numbered headings such as "1.2 Title", "§3.4", "Part 2", "Appendix A"
HEADING_RE = re.compile(r"^(§?\d{1,2}(\.\d{1,2}){0,2}\.?\s+[A-Z][^\n]{2,90}|Part\s+\d+.*|Appendix\s+[A-Z].*)$")


def extract(pdf: Path) -> list[str]:
    reader = PdfReader(str(pdf))
    lines: list[str] = []
    for page_no, page in enumerate(reader.pages, start=1):
        text = page.extract_text() or ""
        lines.append(f"<!-- page {page_no} -->")
        for raw in text.splitlines():
            # NFKC folds PDF ligatures (ﬁ, ﬂ) so grep anchors match plain text.
            line = re.sub(r"[ \t\u00a0]+", " ", unicodedata.normalize("NFKC", raw)).strip()
            if line:
                lines.append(line)
    return lines


def main() -> int:
    SRC.mkdir(parents=True, exist_ok=True)
    anchors: list[str] = []
    for name, filename in SOURCES.items():
        pdf = SRC / filename
        if not pdf.exists():
            print(f"missing {pdf}", file=sys.stderr)
            return 1
        lines = extract(pdf)
        out = SRC / f"{name}.md"
        out.write_text("\n".join(lines) + "\n", encoding="utf-8")
        for idx, line in enumerate(lines, start=1):
            if HEADING_RE.match(line):
                anchors.append(f"{name}.md\t{idx}\t{line}")
        print(f"{out.name}: {len(lines)} lines, {len(reader_pages(pdf))} pages")
    (SRC / "ANCHORS.txt").write_text("\n".join(anchors) + "\n", encoding="utf-8")
    print(f"ANCHORS.txt: {len(anchors)} headings")
    return 0


def reader_pages(pdf: Path):
    return PdfReader(str(pdf)).pages


if __name__ == "__main__":
    raise SystemExit(main())
