#!/usr/bin/env python3
"""T0: write the epic cards (dependency anchors with hard-stop tags) and EXT-* external cards (charter: v2).

Inputs : docs/build/EXTERNAL.md (table), docs/build/RTM.csv
Outputs: docs/build/cards/<phase>/E-*.yaml, docs/build/cards/EXT/EXT-nn.yaml  (idempotent overwrite)
"""
from __future__ import annotations

import csv
import re
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "docs" / "build"
CARDS = BUILD / "cards"
RTM_IDS = {r["req_id"] for r in csv.DictReader((BUILD / "RTM.csv").open(encoding="utf-8", newline=""))}
ID_RE = re.compile(r"(P0-\d+|F-\d{3}(?:\.[DEUL])?|EP-§[\d.]+-[\w-]+|CP-§[\w.]+-[\w-]+|AV-step\d|OB-step\d|REV-\d+|CON-\d+|DEV-\d+|RM-(?:P0|P1|P2|MS|STOP)-\d+|D[1-5]|UNV-[EC]\d+)")

EPICS = [
    ("E-P0-INTAKE", "P0", "G0", "Intake: RTM, charter enforcement, repo map, verification cards", [], [f"RM-STOP-{n:02d}" for n in range(1, 9)]),
    ("E-P1-CONTAINMENT", "P1", "G1", "Containment: close all 27 P0s with evidence", ["ai_disclosure"], [f"RM-P0-{n:02d}" for n in range(1, 14)]),
    ("E-P2-PLATFORM", "P2", "G2", "Platform foundation: CI gates, OpenAPI client, outbox, auth v2, observability, learner model", ["placeholder_linter"], ["RM-P1-02", "RM-P1-09"]),
    ("E-P3-DESIGN-SYSTEM", "P3", "G3", "Design system, IA shell, onboarding v2", [], ["RM-P1-03", "RM-P1-18", "RM-P1-19", "RM-P1-04", "RM-P1-16", "RM-P1-11"]),
    ("E-P4-CONTENT-ENGINE", "P4", "G4", "Content engine: licence register, language kits, linters, Studio, pipeline", ["licence_register"], ["RM-P1-01"]),
    ("E-P5-CONTENT-REAL", "P5", "G5", "Stage-1 content waves A1→A2→B1 with honest labels", ["content_real", "native_verified_rule"], ["RM-P1-13", "RM-P1-14", "RM-P1-15", "RM-P2-01"]),
    ("E-P6-SCORER", "P6", "G8", "Speech and AI: real scorer, gated TTS, realtime voice, gateway modes", ["scorer_real", "tone_accuracy_gate"], ["RM-P1-05", "RM-P1-20", "RM-P2-05", "RM-P2-06"]),
    ("E-P7-HUBS", "P7", "HUB", "Today, Learn and Speak hubs: every feature kept, wired and elevated", [], ["EP-§17-01", "EP-§17-03"]),
    ("E-P8-PLAY", "P8", "HUB", "Play hub: flagship games on real scoring, every game on a shelf", [], ["RM-P2-07"]),
    ("E-P9-SAFETY", "P9", "G9", "Safety and social: guardian hub, age tiers, moderation, E2EE, pen test", ["guardian_moderation"], ["RM-P1-08", "RM-P2-08", "RM-P2-09"]),
    ("E-P10-ME", "P10", "G10", "Me hub, monetisation, credentials, offline packs", [], ["RM-P1-12", "RM-P2-10", "RM-P2-11"]),
    ("E-P11-PERSONAS-AVATARS", "P11", "G11", "Personas v1 and Avatar v1", [], ["RM-P1-06", "RM-P1-21", "RM-P1-07", "RM-P1-17", "RM-P1-22"]),
    ("E-P12-RELEASE", "P12", "G12", "Hardening, privacy programme, a11y audit, release readiness", [], ["RM-P1-10", "RM-P2-12", "RM-P2-13"]),
    ("E-P13-SCALE", "P13", "G13", "Scale: Waves 2–4, contributor programme, moonshots", [], ["RM-P2-02", "RM-P2-14", "RM-P2-03", "RM-P2-04"]),
]
EPIC_DEPENDS = {"E-P1-CONTAINMENT": ["E-P0-INTAKE"], "E-P2-PLATFORM": ["E-P1-CONTAINMENT"], "E-P3-DESIGN-SYSTEM": ["E-P2-PLATFORM"],
                "E-P4-CONTENT-ENGINE": ["E-P2-PLATFORM"], "E-P5-CONTENT-REAL": ["E-P4-CONTENT-ENGINE"], "E-P6-SCORER": ["E-P2-PLATFORM"],
                "E-P7-HUBS": ["E-P3-DESIGN-SYSTEM", "E-P5-CONTENT-REAL", "E-P6-SCORER"],
                "E-P8-PLAY": ["E-P3-DESIGN-SYSTEM", "E-P6-SCORER"], "E-P9-SAFETY": ["E-P3-DESIGN-SYSTEM"], "E-P10-ME": ["E-P5-CONTENT-REAL", "E-P6-SCORER"],
                "E-P11-PERSONAS-AVATARS": ["E-P3-DESIGN-SYSTEM", "E-P1-CONTAINMENT"], "E-P12-RELEASE": ["E-P10-ME"], "E-P13-SCALE": ["E-P12-RELEASE"]}


def dump(path: Path, card: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(yaml.safe_dump(card, sort_keys=False, allow_unicode=True, width=120), encoding="utf-8")


def epics() -> int:
    for cid, phase, gate, title, tags, req_ids in EPICS:
        missing = [r for r in req_ids if r not in RTM_IDS]
        assert not missing, (cid, missing)
        card = {
            "charter": "v2", "id": cid, "kind": "epic", "title": title, "phase": phase, "epic": cid,
            "req_ids": req_ids, "depends_on": EPIC_DEPENDS.get(cid, []), "size": "S",
            "difficulty": {"score": 0, "blast": 0, "ambiguity": 0, "coupling": 0, "depth": 0, "size": 0},
            "tiers": {"worker": "T4", "tester": "T0", "reviewer": "T4", "justification": "epic gate owned by the Orchestrator; no implementation"},
            "token_budget": 10000, "file_allowlist": [], "context_anchors": [],
            "acceptance_criteria": [
                {"id": "AC1", "text": "Every member card of this epic is Done with Tester evidence and Reviewer PASS"},
                {"id": "AC2", "text": "The epic integration test(s) are green in CI"},
                {"id": "AC3", "text": "All RTM rows owned by member cards are Verified-Done, Blocked-External or Waived-by-Tope"},
                {"id": "AC4", "text": "LEDGER.csv shows the epic within budget; routing notes written to 04_ROUTING.md"},
            ],
            "tags": tags, "gate": gate, "status": "Draft",
        }
        dump(CARDS / phase / f"{cid}.yaml", card)
    return len(EPICS)


def externals() -> int:
    text = (BUILD / "EXTERNAL.md").read_text(encoding="utf-8")
    n = 0
    for line in text.splitlines():
        m = re.match(r"^\| (EXT-\d+) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \| (.*?) \| (\w+) \|$", line)
        if not m:
            continue
        ext_id, item, owner, due, artefact, unblocks, status = m.groups()
        if status == "Resolved":
            continue
        req_ids = [r for r in dict.fromkeys(ID_RE.findall(unblocks)) if r in RTM_IDS]
        gate = re.search(r"G\d+", due)
        card = {
            "charter": "v2", "id": ext_id, "kind": "external", "title": f"Obtain: {item}", "phase": "P0", "epic": "E-P0-INTAKE",
            "req_ids": req_ids, "depends_on": [], "size": "S",
            "difficulty": {"score": 1, "blast": 0, "ambiguity": 1, "coupling": 0, "depth": 0, "size": 0},
            "tiers": {"worker": "T1", "tester": "T0", "reviewer": "T2", "justification": "agent prepares the artefact; a human completes the item"},
            "token_budget": 20000, "file_allowlist": [], "context_anchors": [],
            "acceptance_criteria": [
                {"id": "AC1", "text": f"Artefact prepared and stored under docs/build/external/{ext_id}/: {artefact}"},
                {"id": "AC2", "text": f"Owner ({owner}) has the artefact and a one-line status in EXTERNAL.md; due gate {due}"},
            ],
            "owner": owner, "due_gate": gate.group(0) if gate else "G0", "external_blockers": [ext_id],
            "gate": gate.group(0) if gate else "G0", "status": "Blocked-External",
        }
        if not req_ids:
            print(f"warning: {ext_id} has no concrete RTM ids in its Unblocks column")
        dump(CARDS / "EXT" / f"{ext_id}.yaml", card)
        n += 1
    return n


if __name__ == "__main__":
    print(f"epics: {epics()} · externals: {externals()}")
