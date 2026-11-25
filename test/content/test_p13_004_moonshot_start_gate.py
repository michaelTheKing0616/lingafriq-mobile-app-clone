"""P13-004 moonshot start gate (RM-STOP-01)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from scripts.plan.moonshot_start_gate import (  # noqa: E402
    MoonshotStartGateError,
    assert_moonshot_status_allowed,
    assess_rm_stop_01,
    count_feature_completion,
    count_unreachable_features,
    load_card_status_rows,
    refresh_evidence,
    try_status_change,
)

_ADR = _REPO_ROOT / "docs/build/adr/ADR-037-moonshot-start-gate.md"
_EVIDENCE = _REPO_ROOT / "docs/build/moonshot/rm_stop_01_evidence.json"


def test_adr_037_names_tope_and_evidence_path() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "Tope" in text
    assert "rm_stop_01_evidence.json" in text
    assert "P13-005" in text and "P13-011" in text
    assert "RM-STOP-01" in text


def test_live_rm_stop_01_not_satisfied_yet() -> None:
    assessment = assess_rm_stop_01()
    assert assessment.feature_cards_total == 151
    assert not assessment.satisfied
    assert assessment.feature_cards_done < 151


def test_refuses_moonshot_ready_promotion() -> None:
    result = try_status_change("P13-005", "Ready")
    assert result["ok"] is False
    assert result["code"] == "MOONSHOT_START_REFUSED"
    assert result["reasons"]


def test_non_moonshot_card_not_blocked() -> None:
    assert_moonshot_status_allowed("P13-004", "Done")


def test_refresh_evidence_writes_metrics(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    card_status = tmp_path / "CARD_STATUS.tsv"
    card_status.write_text(
        "F-001\tDone\tx\n" + "\n".join(f"F-{i:03d}\tDraft\tx" for i in range(2, 152)),
        encoding="utf-8",
    )
    repo_map = tmp_path / "REPO_MAP.md"
    repo_map.write_text(
        "## Features F-001…151\n\n"
        "| Feature | Title | Screen | route | reach |\n"
        "| --- | --- | --- | --- | --- |\n"
        + "\n".join(f"| `F-{i:03d}` | t | s | r | reachable |" for i in range(1, 152)),
        encoding="utf-8",
    )
    evidence = tmp_path / "evidence.json"
    evidence.write_text(
        json.dumps(
            {
                "charter": "v2",
                "tope_signed_off": True,
                "refusal_log": [],
            }
        ),
        encoding="utf-8",
    )
    monkeypatch.setattr(
        "scripts.plan.moonshot_start_gate._CARD_STATUS",
        card_status,
    )
    monkeypatch.setattr("scripts.plan.moonshot_start_gate._REPO_MAP", repo_map)
    monkeypatch.setattr("scripts.plan.moonshot_start_gate._EVIDENCE", evidence)

    total, done = count_feature_completion(load_card_status_rows(card_status))
    assert total == 151 and done == 1
    assert count_unreachable_features(repo_map) == 0

    refresh_evidence(card_status=card_status, repo_map=repo_map, evidence=evidence)
    doc = json.loads(evidence.read_text(encoding="utf-8"))
    assert doc["feature_cards_done"] == 1
    assert doc["rm_stop_01_satisfied"] is False

    with pytest.raises(MoonshotStartGateError):
        assert_moonshot_status_allowed("P13-006", "Build")
