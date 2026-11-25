#!/usr/bin/env python3
"""Block a staged promotion when crash-free users or the ANR rate miss the gate."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Play-style floors. A rollout stops when either line is crossed.
MIN_CRASH_FREE_USERS = 0.995
MAX_ANR_RATE = 0.0047


def blocked(crash_free_users: float, anr_rate: float) -> list[str]:
    reasons: list[str] = []
    if crash_free_users < MIN_CRASH_FREE_USERS:
        reasons.append(
            f"crash-free users {crash_free_users:.4f} are below {MIN_CRASH_FREE_USERS:.4f}"
        )
    if anr_rate > MAX_ANR_RATE:
        reasons.append(f"ANR rate {anr_rate:.4f} is above {MAX_ANR_RATE:.4f}")
    return reasons


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("report", type=Path)
    args = parser.parse_args(argv)
    payload = json.loads(args.report.read_text())
    reasons = blocked(float(payload["crash_free_users"]), float(payload["anr_rate"]))
    if reasons:
        for reason in reasons:
            print(reason, file=sys.stderr)
        return 1
    print("promotion allowed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
