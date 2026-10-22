#!/usr/bin/env python3
"""T0: split RTM.csv into per-phase slices for card drafting (charter: v2).

Output: docs/build/rtm_slices/<slice>.csv (same columns as RTM.csv).
Every RTM row lands in exactly one slice; exit 1 otherwise. Feature rows are split by hub.
"""
from __future__ import annotations

import csv
import re
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RTM = ROOT / "docs" / "build" / "RTM.csv"
OUT = ROOT / "docs" / "build" / "rtm_slices"

# (slice name, regex on req_id). First match wins.
RULES: list[tuple[str, str]] = [
    ("P1_containment", r"^(P0-\d+|RM-P0-\d+|EP-§13\.1-)"),
    ("P0_intake", r"^(UNV-|EP-§0-|EP-§2-|RM-STOP-|CP-§pre-|CP-§0-|CP-§1-|D[1-5]$)"),
    ("P2_platform", r"^EP-§(13\.4|13\.5|13\.9|6\.3|11\.1|11\.3)-"),
    ("P3_design_shell", r"^(EP-§(3\.\d|17|17\.[1-5]|5\.\d|13\.7|13\.8)-|REV-|CON-|DEV-|OB-)"),
    ("P4_content_engine", r"^(CP-§(2\.[1-3]|2\.4-(yo|ig|ha|pcm|sw|zu|xh)|3\.\d|8|9\.1)-|EP-§(6\.4|6\.5|6\.6|14\.\d)-)"),
    ("P5_content_waves", r"^(CP-§([4-7]|7-\w+|9\.[2-4])-|EP-§(6\.1|6\.2|6\.7)-)"),
    ("P6_speech_ai", r"^EP-§7\.\d-"),
    ("P7_features_today", r"^F-00[1-6]\b"),
    ("P7_features_learn", r"^F-0(0[7-9]|[12]\d|3[0-4])\b"),
    ("P7_features_speak", r"^F-0(3[5-9]|4\d|5[0-4])\b"),
    ("P7_hub_eng", r"^EP-§(11\.2|17\.6|17\.7)-"),
    ("P8_features_play_a", r"^F-0(5[5-9]|6\d|7[0-8])\b"),
    ("P8_features_play_b", r"^F-(079|08\d|09\d|10[0-2])\b"),
    ("P8_play_eng", r"^EP-§10\.\d-"),
    ("P9_features_village_a", r"^F-1(0[3-9]|1\d)\b"),
    ("P9_features_village_b", r"^F-1(2\d|3[0-6])\b"),
    ("P9_village_eng", r"^EP-§(9\.\d|13\.3)-"),
    ("P10_features_me", r"^F-1(3[7-9]|4\d|5[01])\b"),
    ("P10_me_eng", r"^EP-§(12\.\d|13\.2|15)-"),
    ("P11_personas_avatars", r"^(EP-§(8\.\d|4|4\.\d)-|AV-)"),
    ("EPICS_roadmap", r"^RM-P[12]-"),  # owned by the Orchestrator via epic cards
    ("P12_release", r"^EP-§13\.6-"),
    ("P13_scale", r"^(RM-MS-|CP-§2\.4-later-)"),
]
COMPILED = [(name, re.compile(rx)) for name, rx in RULES]


def main() -> int:
    with RTM.open(encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        fields = reader.fieldnames or []
        rows = list(reader)
    slices: dict[str, list[dict]] = defaultdict(list)
    orphans: list[str] = []
    for r in rows:
        for name, rx in COMPILED:
            if rx.match(r["req_id"]):
                slices[name].append(r)
                break
        else:
            orphans.append(r["req_id"])
    OUT.mkdir(parents=True, exist_ok=True)
    for old in OUT.glob("*.csv"):
        old.unlink()
    for name, rs in slices.items():
        with (OUT / f"{name}.csv").open("w", encoding="utf-8", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=fields)
            w.writeheader()
            w.writerows(rs)
    print("  ".join(f"{n}:{len(slices[n])}" for n, _ in RULES))
    if orphans:
        print(f"orphans ({len(orphans)}): {orphans[:30]}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
