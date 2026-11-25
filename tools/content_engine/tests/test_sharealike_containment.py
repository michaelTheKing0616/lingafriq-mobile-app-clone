"""Tests for share-alike containment of the evidence layer (P4-009)."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Any

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.licences.register_schema import (  # noqa: E402
    LicenceRegisterError,
)
from tools.content_engine.linters.sharealike_containment import (  # noqa: E402
    ShareAlikeContainmentError,
    check_sharealike_containment,
)

_FSI_ATTRIBUTION = (
    "US government work (Foreign Service Institute Basic Course). Public domain."
)


def _cite(
    item_id: str,
    layer: str,
    source_id: str,
    *,
    verbatim: bool = False,
    attribution_text: str | None = None,
) -> dict[str, Any]:
    artefact: dict[str, Any] = {
        "item_id": item_id,
        "layer": layer,
        "provenance": [{"source_id": source_id, "verbatim": verbatim}],
    }
    if attribution_text is not None:
        artefact["attribution_text"] = attribution_text
    return artefact


def test_lexicon_wiktionary_fails_sharealike_leak() -> None:
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite("lex-001", "lexicon", "wiktionary-kaikki"),
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "SHAREALIKE_LEAK"
    assert "lex-001" in message
    assert "wiktionary-kaikki" in message


def test_evidence_wiktionary_with_attribution_passes() -> None:
    check_sharealike_containment(
        _cite(
            "ev-001",
            "evidence",
            "wiktionary-kaikki",
            attribution_text=(
                "Wiktionary via Kaikki.org (CC BY-SA 4.0); verification evidence only."
            ),
        ),
    )


@pytest.mark.parametrize("provenance", [None, []])
def test_learner_text_empty_provenance_fails_provenance_missing(
    provenance: object,
) -> None:
    artefact: dict[str, Any] = {
        "item_id": "lt-empty",
        "layer": "learner-text",
        "provenance": provenance,
    }
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(artefact)
    assert exc_info.value.code == "PROVENANCE_MISSING"


def test_learner_text_fsi_yoruba_verbatim_passes() -> None:
    check_sharealike_containment(
        _cite(
            "lt-fsi-yoruba",
            "learner-text",
            "fsi-yoruba",
            verbatim=True,
            attribution_text=_FSI_ATTRIBUTION,
        ),
    )


def test_learner_text_wiktionary_verbatim_fails() -> None:
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite(
                "lt-wiktionary",
                "learner-text",
                "wiktionary-kaikki",
                verbatim=True,
                attribution_text=(
                    "Wiktionary via Kaikki.org (CC BY-SA 4.0); cited as evidence."
                ),
            ),
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "SHAREALIKE_LEAK"
    assert "lt-wiktionary" in message
    assert "wiktionary-kaikki" in message
    cause = exc_info.value.__cause__
    assert isinstance(cause, LicenceRegisterError)
    assert cause.code == "VERBATIM_INCOMPATIBLE"


@pytest.mark.parametrize("attribution_text", ["", "   "])
def test_evidence_sharealike_empty_attribution_fails(attribution_text: str) -> None:
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite(
                "ev-empty",
                "evidence",
                "wiktionary-kaikki",
                attribution_text=attribution_text,
            ),
        )
    assert exc_info.value.code == "ATTRIBUTION_MISSING"


def test_proprietary_lexicon_wiktionary_fails_sharealike_leak() -> None:
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite("plex-001", "proprietary-lexicon", "wiktionary-kaikki"),
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "SHAREALIKE_LEAK"
    assert "plex-001" in message
    assert "wiktionary-kaikki" in message


def test_share_alike_flag_leaks_without_by_sa_licence() -> None:
    rows = [
        {
            "source_id": "marked-sa",
            "licence": "public-domain",
            "share_alike": "true",
        }
    ]
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite("lex-flag", "lexicon", "marked-sa"),
            rows,
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "SHAREALIKE_LEAK"
    assert "lex-flag" in message
    assert "marked-sa" in message


def test_by_sa_licence_leaks_when_share_alike_flag_is_false() -> None:
    rows = [
        {
            "source_id": "marked-no",
            "licence": "CC BY-SA 4.0",
            "share_alike": "false",
        }
    ]
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite("lex-no", "lexicon", "marked-no"),
            rows,
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "SHAREALIKE_LEAK"
    assert "lex-no" in message
    assert "marked-no" in message


def test_lexicon_cc_by_not_sharealike_passes() -> None:
    check_sharealike_containment(_cite("lex-waxal-ghana", "lexicon", "waxal-ghana"))


def test_learner_text_verbatim_incompatible_delegates_to_check_verbatim() -> None:
    with pytest.raises(LicenceRegisterError) as exc_info:
        check_sharealike_containment(
            _cite(
                "lt-peace-corps",
                "learner-text",
                "peace-corps-hausa",
                verbatim=True,
                attribution_text="Peace Corps Hausa manual.",
            ),
        )
    assert exc_info.value.code == "VERBATIM_INCOMPATIBLE"


def test_evidence_registered_non_sharealike_with_attribution_passes() -> None:
    check_sharealike_containment(
        _cite(
            "ev-fsi",
            "evidence",
            "fsi-yoruba",
            attribution_text=_FSI_ATTRIBUTION,
        ),
    )


def test_evidence_unregistered_source_fails() -> None:
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite(
                "ev-unknown",
                "evidence",
                "not-a-source",
                attribution_text="Unregistered source.",
            ),
            [],
        )
    message = str(exc_info.value)
    assert exc_info.value.code == "LICENCE_UNREGISTERED"
    assert "ev-unknown" in message
    assert "not-a-source" in message


def test_unknown_layer_fails_closed() -> None:
    with pytest.raises(ShareAlikeContainmentError) as exc_info:
        check_sharealike_containment(
            _cite(
                "x-1",
                "notes",
                "wiktionary-kaikki",
                attribution_text="Should not pass.",
            ),
        )
    assert exc_info.value.code == "LAYER_INVALID"
