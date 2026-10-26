"""Content graph → feature surface map loader and silo/IRT gates (P5-032)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Mapping, Sequence

import yaml

from tools.content.placeholder_linter import repo_root

CARD_ID = "P5-032"
MAP_REL = "docs/build/content_graph_features.yaml"
RULE_GM001 = "GM-001"
RULE_GM002 = "GM-002"
RULE_GM003 = "GM-003"
IRT_SURFACES = frozenset({"checkpoints", "placement_test"})


@dataclass(frozen=True)
class GraphMapFinding:
    rule_id: str
    field: str
    detail: str


def map_path(root: Path | None = None) -> Path:
    return repo_root(root) / MAP_REL


def load_content_graph_map(root: Path | None = None) -> dict[str, Any]:
    path = map_path(root)
    with path.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, Mapping):
        raise ValueError(f"{MAP_REL} must be a mapping")
    return dict(data)


def _surface_sources(surface_row: Mapping[str, Any]) -> set[str]:
    if "source_node" in surface_row:
        return {str(surface_row["source_node"])}
    nodes = surface_row.get("source_nodes")
    if isinstance(nodes, list):
        return {str(n) for n in nodes}
    return set()


def validate_map_structure(doc: Mapping[str, Any]) -> list[GraphMapFinding]:
    findings: list[GraphMapFinding] = []
    nodes = doc.get("graph_nodes")
    surfaces = doc.get("surfaces")
    if not isinstance(nodes, Mapping) or not isinstance(surfaces, Mapping):
        return [
            GraphMapFinding(RULE_GM001, "root", "graph_nodes and surfaces mappings required")
        ]

    feeds_union: dict[str, set[str]] = {}
    for node_id, node_row in nodes.items():
        if not isinstance(node_row, Mapping):
            findings.append(GraphMapFinding(RULE_GM001, f"graph_nodes.{node_id}", "invalid node"))
            continue
        feeds = node_row.get("feeds")
        if not isinstance(feeds, list) or len(feeds) < 1:
            findings.append(
                GraphMapFinding(RULE_GM001, f"graph_nodes.{node_id}.feeds", "feeds required")
            )
            continue
        feeds_union[str(node_id)] = {str(f) for f in feeds}

    for surface_id, surface_row in surfaces.items():
        if not isinstance(surface_row, Mapping):
            findings.append(GraphMapFinding(RULE_GM001, f"surfaces.{surface_id}", "invalid surface"))
            continue
        sources = _surface_sources(surface_row)
        if not sources:
            findings.append(
                GraphMapFinding(
                    RULE_GM001,
                    f"surfaces.{surface_id}",
                    "source_node or source_nodes required",
                )
            )
            continue
        for node_id in sources:
            allowed = feeds_union.get(node_id)
            if allowed is None:
                findings.append(
                    GraphMapFinding(
                        RULE_GM001,
                        f"surfaces.{surface_id}",
                        f"unknown graph node {node_id}",
                    )
                )
            elif surface_id not in allowed:
                findings.append(
                    GraphMapFinding(
                        RULE_GM001,
                        f"surfaces.{surface_id}",
                        f"not listed under graph_nodes.{node_id}.feeds",
                    )
                )

    required_nodes = (
        "lexeme",
        "pattern",
        "dialogue",
        "exercise_item",
        "culture_card",
        "can_do",
    )
    for node_id in required_nodes:
        if node_id not in nodes:
            findings.append(
                GraphMapFinding(RULE_GM001, "graph_nodes", f"missing required node {node_id}")
            )
    return findings


def check_feature_binding(
    binding: Mapping[str, Any],
    doc: Mapping[str, Any],
) -> list[GraphMapFinding]:
    consumer_id = str(binding.get("consumer_id") or "<unknown>")
    findings: list[GraphMapFinding] = []
    read_mode = str(binding.get("read_mode") or "")
    if read_mode != "graph_ref":
        findings.append(
            GraphMapFinding(
                RULE_GM002,
                consumer_id,
                f"read_mode must be graph_ref, got {read_mode!r}",
            )
        )
    silo_patterns = doc.get("silo_forbidden_patterns")
    if isinstance(silo_patterns, list):
        for pattern in silo_patterns:
            if pattern == read_mode or pattern == binding.get("source_ref"):
                findings.append(
                    GraphMapFinding(RULE_GM002, consumer_id, f"siloed pattern {pattern}")
                )

    graph_node = str(binding.get("graph_node") or "")
    nodes = doc.get("graph_nodes")
    if not isinstance(nodes, Mapping) or graph_node not in nodes:
        findings.append(
            GraphMapFinding(RULE_GM002, consumer_id, f"unknown graph_node {graph_node}")
        )
        return findings

    surfaces = binding.get("surfaces")
    if not isinstance(surfaces, list):
        findings.append(GraphMapFinding(RULE_GM002, consumer_id, "surfaces must be a list"))
        return findings

    surface_map = doc.get("surfaces")
    if not isinstance(surface_map, Mapping):
        return findings

    node_feeds = {str(f) for f in nodes[graph_node].get("feeds", [])}
    for surface in surfaces:
        sid = str(surface)
        if sid not in node_feeds:
            findings.append(
                GraphMapFinding(
                    RULE_GM002,
                    consumer_id,
                    f"surface {sid} not fed by graph node {graph_node}",
                )
            )
        row = surface_map.get(sid)
        if not isinstance(row, Mapping):
            findings.append(
                GraphMapFinding(RULE_GM002, consumer_id, f"unknown surface {sid}")
            )
            continue
        if graph_node not in _surface_sources(row):
            findings.append(
                GraphMapFinding(
                    RULE_GM002,
                    consumer_id,
                    f"surface {sid} source does not include {graph_node}",
                )
            )

    source_ref = binding.get("source_ref")
    if not isinstance(source_ref, str) or not source_ref.strip():
        findings.append(GraphMapFinding(RULE_GM002, consumer_id, "source_ref required"))
    return findings


def lint_feature_bindings(doc: Mapping[str, Any]) -> list[GraphMapFinding]:
    bindings = doc.get("feature_bindings")
    if not isinstance(bindings, list):
        return [GraphMapFinding(RULE_GM002, "feature_bindings", "must be a list")]
    findings: list[GraphMapFinding] = []
    for index, binding in enumerate(bindings):
        if not isinstance(binding, Mapping):
            findings.append(
                GraphMapFinding(RULE_GM002, f"feature_bindings[{index}]", "invalid binding")
            )
            continue
        findings.extend(check_feature_binding(binding, doc))
    return findings


def exercise_item_irt_eligible(
    item: Mapping[str, Any],
    *,
    surface: str,
) -> bool:
    """Return True if item may appear on surface (calibrated or surface does not require IRT)."""
    if surface not in IRT_SURFACES:
        return True
    irt = item.get("irt")
    if not isinstance(irt, Mapping):
        return False
    return str(irt.get("irt_status")) == "calibrated"


def lint_exercise_pool(
    items: Sequence[Mapping[str, Any]],
    *,
    surface: str,
) -> list[GraphMapFinding]:
    if surface not in IRT_SURFACES:
        return []
    findings: list[GraphMapFinding] = []
    for index, item in enumerate(items):
        item_id = str(item.get("id") or f"index:{index}")
        if not exercise_item_irt_eligible(item, surface=surface):
            findings.append(
                GraphMapFinding(
                    RULE_GM003,
                    item_id,
                    f"uncalibrated item excluded from {surface}",
                )
            )
    return findings


def lint_dialogue_surfaces_registered(
    dialogue: Mapping[str, Any],
    doc: Mapping[str, Any],
) -> list[GraphMapFinding]:
    dialogue_id = str(dialogue.get("id") or "<unknown>")
    nodes = doc.get("graph_nodes")
    if not isinstance(nodes, Mapping):
        return []
    allowed = {str(f) for f in nodes.get("dialogue", {}).get("feeds", [])}
    graph = dialogue.get("content_graph")
    if not isinstance(graph, Mapping):
        return [
            GraphMapFinding(RULE_GM001, dialogue_id, "content_graph required for dialogue node")
        ]
    surfaces = graph.get("surfaces")
    if not isinstance(surfaces, list):
        return [GraphMapFinding(RULE_GM001, dialogue_id, "content_graph.surfaces must be a list")]
    findings: list[GraphMapFinding] = []
    for surface in surfaces:
        sid = str(surface)
        if sid not in allowed:
            findings.append(
                GraphMapFinding(
                    RULE_GM001,
                    dialogue_id,
                    f"surface {sid} not in dialogue graph feeds",
                )
            )
    return findings


def lint_all(root: Path | None = None) -> list[GraphMapFinding]:
    doc = load_content_graph_map(root)
    findings = validate_map_structure(doc) + lint_feature_bindings(doc)
    dialogues_dir = repo_root(root) / "assets/data/dialogues"
    if dialogues_dir.is_dir():
        for path in sorted(dialogues_dir.glob("*.json")):
            try:
                payload = json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                continue
            dialogues = payload.get("dialogues")
            if not isinstance(dialogues, list):
                continue
            for dialogue in dialogues:
                if isinstance(dialogue, Mapping):
                    findings.extend(lint_dialogue_surfaces_registered(dialogue, doc))
    return findings


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Lint content graph feature map (P5-032).")
    parser.add_argument("--root", type=Path, default=None)
    args = parser.parse_args(list(argv) if argv is not None else None)
    findings = lint_all(args.root)
    for finding in findings:
        print(f"{finding.rule_id}\t{finding.field}\t{finding.detail}")
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
