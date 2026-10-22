#!/usr/bin/env python3
"""Fail when grammar uses a banned generic claim, or a tone line has no lexicon source.

Usage:
  python3 scripts/ci/claim_lint.py [--patterns FILE] [--baseline FILE] [path ...]
  python3 scripts/ci/claim_lint.py --write-baseline FILE [path ...]

The rejected span is printed after the rule id. A tone line passes when a
lexicon source reference appears within the configured window of lines.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import placeholder_lint as gate


def main(argv: list[str]) -> int:
    patterns_path, baseline, write, paths = gate.parse_args(argv)
    if not patterns_path.is_file():
        print(f"patterns not found: {patterns_path}", file=sys.stderr)
        return 2
    patterns = gate.load_patterns(patterns_path)
    hits = gate.scan(paths, patterns, gate.claim_hits)
    return gate.report(hits, patterns, baseline, write)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
