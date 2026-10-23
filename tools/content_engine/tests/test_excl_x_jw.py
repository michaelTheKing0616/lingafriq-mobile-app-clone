"""JW300 and Masakhane exclusion declarations (P4-011)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.linters.exclusion_enforce import (  # noqa: E402
    ExclusionEnforceError,
    load_exclusions,
    scan_manifest,
)

_JW300_REASON = "built-in-breach-of-jw.org-terms"
_JW300_DECLARATION = "no-JW300-derived-data"
_MASAKHANE_ACTION = "exclude-or-request-commercial-licence-from-Masakhane"


def test_jw300_excluded_with_reason_and_declaration() -> None:
    table = load_exclusions()
    row = table["sources"]["jw300"]
    assert row["status"] == "excluded"
    assert row["reason"] == _JW300_REASON
    assert row["declaration"] == _JW300_DECLARATION
    assert row["uses"]["display"] is False
    assert row["uses"]["evidence"] is False
    assert row["uses"]["training"] is False


@pytest.mark.parametrize("source_id", ["mafand-mt", "masakhaner-2"])
def test_masakhane_sources_excluded_with_action(source_id: str) -> None:
    table = load_exclusions()
    row = table["sources"][source_id]
    assert row["status"] == "excluded"
    assert row["licence"] == "CC BY-NC 4.0"
    assert row["action"] == _MASAKHANE_ACTION


def test_manifest_jw300_derived_source_id_fails_jw300_derived_data() -> None:
    table = load_exclusions()
    with pytest.raises(ExclusionEnforceError) as exc_info:
        scan_manifest(
            [{"source_id": "jw300-derived", "layer": "corpus"}],
            table,
        )
    assert exc_info.value.code == "JW300_DERIVED_DATA"
    assert "jw300-derived" in str(exc_info.value)
