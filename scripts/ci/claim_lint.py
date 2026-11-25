#!/usr/bin/env python3
"""Fail when bundled curriculum has a banned claim or a lesson/tone note with no source.

Usage:
  python3 scripts/ci/claim_lint.py [--patterns FILE] [--baseline FILE] [path ...]
  python3 scripts/ci/claim_lint.py --write-baseline FILE [path ...]

With no paths, this scans repo-bundled curriculum only (assets/data and the
four legacy bundles). It does not scan lib/, node-backend, or a learner's
Import Media. A runtime lesson tagged "from your media" or
"AI-generated, unreviewed" is skipped even if its file is passed in.

A source is a lexicon or dictionary entry, a licensed corpus item, a native
speaker id with a review date, or an Import Media id with a timestamp or span.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import placeholder_lint as gate


def main(argv: list[str]) -> int:
    patterns_path, baseline, write, paths = gate.parse_args(argv, empty_paths=gate.curriculum_roots())
    if not patterns_path.is_file():
        print(f"patterns not found: {patterns_path}", file=sys.stderr)
        return 2
    patterns = gate.load_patterns(patterns_path)
    hits = gate.scan(paths, patterns, gate.claim_hits)
    return gate.report(hits, patterns, baseline, write)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
