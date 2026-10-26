"""Spec tests for UI string and phrase-pack pipeline lint (P4-087)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[3]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_engine.legacy.ui_strings import (  # noqa: E402
    CARD_ID,
    MANIFEST_BASENAME,
    REVIEW_BASENAME,
    build_lint_stage,
    collect_ui_strings,
    is_arb_metadata_key,
    lint_ui_string,
    parse_arb_file,
    run_ui_strings,
    UiStringSource,
)


def _arb(tmp_path: Path, lang: str, entries: dict[str, str]) -> Path:
    l10n = tmp_path / "lib" / "l10n"
    l10n.mkdir(parents=True)
    path = l10n / f"app_{lang}.arb"
    payload = {"@@locale": lang, **entries}
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return path


def _pipeline_input(tmp_path: Path) -> Path:
    root = tmp_path.parent / "curriculum" / "pipeline" / "input"
    root.mkdir(parents=True, exist_ok=True)
    return root


def _phrase_pack(tmp_path: Path, lang: str, phrases: dict[str, str]) -> Path:
    packs = _pipeline_input(tmp_path) / "phrase_packs"
    packs.mkdir(parents=True, exist_ok=True)
    path = packs / f"{lang}.json"
    path.write_text(
        json.dumps({"languageCode": lang, "phrases": phrases, "words": {}}, ensure_ascii=False),
        encoding="utf-8",
    )
    return path


def test_P4_087_arb_metadata_keys_skipped() -> None:
    assert is_arb_metadata_key("@welcomeMessage")
    assert not is_arb_metadata_key("welcomeMessage")


def test_P4_087_AC1_dry_run_lists_without_writing_review(tmp_path: Path) -> None:
    _arb(tmp_path, "sw", {"greeting": "Habari"})
    pipeline = _pipeline_input(tmp_path)
    packs = pipeline / "phrase_packs"
    review = pipeline / REVIEW_BASENAME
    result = run_ui_strings(
        tmp_path,
        dry_run=True,
        l10n=tmp_path / "lib" / "l10n",
        phrase_dir=packs,
    )
    assert result.stats.strings_total >= 1
    assert not review.exists()


def test_P4_087_AC2_lint_failure_queues_review_arb_unchanged(tmp_path: Path) -> None:
    arb_path = _arb(tmp_path, "pcm", {"hello": "see ENGLISH_SPELLING now"})
    before = arb_path.read_text(encoding="utf-8")
    kits = _REPO_ROOT / "tools" / "content_engine" / "kits"
    source = parse_arb_file(arb_path, "pcm")[0]
    status, route = lint_ui_string(source, kits)
    assert status == "fail"
    assert route == "Reject"
    result = run_ui_strings(
        tmp_path,
        dry_run=False,
        l10n=tmp_path / "lib" / "l10n",
        phrase_dir=_pipeline_input(tmp_path) / "phrase_packs",
    )
    assert result.stats.lint_fail >= 1
    assert arb_path.read_text(encoding="utf-8") == before
    review_path = _pipeline_input(tmp_path) / REVIEW_BASENAME
    assert review_path.is_file()
    row = json.loads(review_path.read_text(encoding="utf-8").splitlines()[0])
    assert row["card"] == CARD_ID
    assert row["arb_mutable"] is False


def test_P4_087_integration_idempotent_manifest(tmp_path: Path) -> None:
    _arb(tmp_path, "ig", {"appTitle": "LingAfriq"})
    packs = _pipeline_input(tmp_path) / "phrase_packs"
    first = run_ui_strings(
        tmp_path,
        dry_run=False,
        l10n=tmp_path / "lib" / "l10n",
        phrase_dir=packs,
    )
    manifest = _pipeline_input(tmp_path) / MANIFEST_BASENAME
    assert manifest.is_file()
    text_a = manifest.read_text(encoding="utf-8")
    second = run_ui_strings(
        tmp_path,
        dry_run=False,
        l10n=tmp_path / "lib" / "l10n",
        phrase_dir=packs,
    )
    text_b = manifest.read_text(encoding="utf-8")
    assert first.stats == second.stats
    assert text_a == text_b


def test_P4_087_phrase_pack_collected(tmp_path: Path) -> None:
    _phrase_pack(tmp_path, "ha", {"water": "Ruwa"})
    sources = collect_ui_strings(
        tmp_path,
        l10n=tmp_path / "lib" / "l10n",
        phrase_dir=_pipeline_input(tmp_path) / "phrase_packs",
    )
    assert any(s.source_kind == "phrase_phrases" and s.key == "water" for s in sources)


def test_P4_087_build_lint_stage_has_unicode_payload() -> None:
    source = UiStringSource("arb", "x", "yo", "yo", "k", "Bawo")
    stage = build_lint_stage(source, {"character_set": ["a"]})
    assert stage["language"] == "yo"
    assert "unicode" in stage["lint_payloads"]
