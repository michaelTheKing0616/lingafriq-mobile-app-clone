"""P10-936: Efficacy study design brief — structure and no invented outcomes."""

from __future__ import annotations

import re
from pathlib import Path

import yaml

_REPO_ROOT = Path(__file__).resolve().parents[2]
_BRIEF = _REPO_ROOT / "docs/analytics/EFFICACY_STUDY_BRIEF.md"
_ADR = _REPO_ROOT / "docs/build/adr/ADR-023-efficacy-study-languages.md"

FM_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
SECTIONS_BLOCK_RE = re.compile(
    r"efficacy_required_sections:\s*\n((?:\s+-\s+\".+\"\s*\n)+)",
    re.MULTILINE,
)
SECTION_ITEM_RE = re.compile(r'^\s*-\s*"(.+)"\s*$', re.MULTILINE)
HEADING_RE = re.compile(r"^## (.+)$", re.MULTILINE)

# Outcome stats that must not appear until a study completes (allow TBD / none language).
_FORBIDDEN_EFFICACY_STATS = [
    re.compile(r"\b\d+(\.\d+)?%\s*(improvement|gain|increase|boost)\b", re.I),
    re.compile(r"\bcohen['']?s\s*d\s*=\s*[-+]?\d", re.I),
    re.compile(r"\bp\s*<\s*0\.\d+\b", re.I),
    re.compile(r"\beffect size of\s+\d", re.I),
    re.compile(r"\bN\s*=\s*\d{2,}\b"),  # concrete sample sizes
]


def _load_brief() -> tuple[dict, str]:
    text = _BRIEF.read_text(encoding="utf-8")
    m = FM_RE.match(text)
    assert m, "EFFICACY_STUDY_BRIEF.md: missing YAML front matter"
    meta = yaml.safe_load(m.group(1)) or {}
    body = text[m.end() :]
    return meta, body


def test_brief_front_matter_open_ext20() -> None:
    meta, _ = _load_brief()
    assert meta.get("card") == "P10-936"
    assert meta.get("status") == "open"
    assert meta.get("partner_blocker") == "EXT-20"
    assert meta.get("study_results") == "none"
    arms = meta.get("language_arms") or []
    ids = {a["language_id"] for a in arms}
    assert ids == {"yo", "zu"}


def test_brief_required_sections_present() -> None:
    text = _BRIEF.read_text(encoding="utf-8")
    m = SECTIONS_BLOCK_RE.search(text)
    assert m, "missing efficacy_required_sections in front matter"
    required = [g.strip() for g in SECTION_ITEM_RE.findall(m.group(1))]
    headings = {h.strip() for h in HEADING_RE.findall(text)}
    missing = [s for s in required if s not in headings]
    assert not missing, f"missing ## sections: {missing}"


def test_brief_defines_opi_blinded_raters_per_language() -> None:
    _, body = _load_brief()
    lower = body.lower()
    assert "oral proficiency interview" in lower or "opi" in lower
    assert "blinded" in lower
    assert "`yo`" in body or "yoruba" in lower
    assert "`zu`" in body or "isizulu" in lower or "isi zulu" in lower


def test_brief_timeline_sample_rater_partner() -> None:
    _, body = _load_brief()
    lower = body.lower()
    assert "twelve months" in lower or "12 months" in lower
    assert "power analysis" in lower or "sample size" in lower
    assert "rater" in lower and "training" in lower
    assert "ext-20" in lower
    assert "tope" in lower


def test_brief_states_no_results_yet() -> None:
    _, body = _load_brief()
    lower = body.lower()
    assert "no efficacy statistics" in lower or "no study has been run" in lower
    assert "none" in lower


def test_brief_contains_no_invented_efficacy_statistics() -> None:
    text = _BRIEF.read_text(encoding="utf-8")
    for pattern in _FORBIDDEN_EFFICACY_STATS:
        match = pattern.search(text)
        assert match is None, f"invented-looking stat: {match.group(0) if match else ''}"


def test_brief_aligns_with_adr_023() -> None:
    adr = _ADR.read_text(encoding="utf-8").lower()
    assert "yoruba" in adr and "`zu`" in adr
    meta, body = _load_brief()
    assert "ADR-023" in body
    assert meta.get("adr") == "ADR-023"
