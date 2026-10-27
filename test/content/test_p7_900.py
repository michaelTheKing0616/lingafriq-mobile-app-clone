"""P7-900 / ADR-009: Lens naming, pipeline stages, retained point-and-say route."""

from __future__ import annotations

from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parents[2]
_ADR = _REPO_ROOT / "docs/build/adr/ADR-009-lens-point-and-say.md"
_MY_APP = _REPO_ROOT / "lib/my_app.dart"


def test_adr_009_exists_and_records_lens_pipeline() -> None:
    text = _ADR.read_text(encoding="utf-8")
    assert "Accepted" in text and "2026-10-27" in text
    for phrase in (
        "Lens",
        "Point & Say",
        "point-and-say",
        "MobileNetV4",
        "SigLIP",
        "opt-in",
        "P7-945",
        "P7-946",
        "P7-950",
        "ML Kit",
    ):
        assert phrase in text


def test_point_and_say_route_retained_in_app_router() -> None:
    text = _MY_APP.read_text(encoding="utf-8")
    assert "'point-and-say'" in text
    assert "PointAndSayScreen" in text
