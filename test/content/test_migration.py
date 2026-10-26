"""Legacy bundle → v2 pack migration (P4-107)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content_pipeline.migrate_legacy_bundles import (  # noqa: E402
    CARD_ID,
    build_lexeme_from_vocab,
    legacy_ai_assisted,
    migrate_document,
    run_migration,
    validation_report,
    write_v2_packs,
)
from tools.content_pipeline.pack_builder import LEGACY_BUNDLE_DIRS, verify_built_pack  # noqa: E402
from tools.content_pipeline.pack_signing import verify_pack_signature  # noqa: E402

_FIXTURE_SEED = "22" * 32


def _legacy_source(pointer: str = "units[0]/vocab[0]") -> object:
    from tools.content_pipeline.migrate_legacy_bundles import LegacySource

    return LegacySource("curriculum_bundle", "fixture/swahili_A1.json", pointer, "vocab")


def test_P4_107_AC1_placeholder_vocab_rejected_not_dropped() -> None:
    source = _legacy_source()
    outcome = build_lexeme_from_vocab(
        source,
        kit_lang="sw",
        word="word1a",
        meaning="example meaning",
        cefr="A1",
        ai_assisted=True,
    )
    from tools.content_pipeline.migrate_legacy_bundles import MigrationReject

    assert isinstance(outcome, MigrationReject)
    assert outcome.reason == "LEGACY_PLACEHOLDER"


def test_P4_107_AC2_migrated_lexeme_is_beta_with_ai_flag() -> None:
    source = _legacy_source()
    outcome = build_lexeme_from_vocab(
        source,
        kit_lang="sw",
        word="asante",
        meaning="thank you",
        cefr="A1",
        ai_assisted=True,
    )
    from tools.content_pipeline.migrate_legacy_bundles import MigrationReject

    assert not isinstance(outcome, MigrationReject)
    assert outcome["label"] == "beta"
    prov = outcome["provenance"]
    assert prov["ai_assisted"] is True
    assert prov.get("model_id")
    assert outcome["label"] not in {"expert_reviewed", "native_verified"}


def test_P4_107_AC3_validation_report_counts_by_rule(tmp_path: Path) -> None:
    bad = {
        "id": "yo.lex.oko.legacy",
        "language": "yo",
        "lemma": "oko",
        "label": "beta",
        "provenance": {
            "author": "t",
            "created_at": "2026-10-26T00:00:00Z",
            "ai_assisted": False,
            "sources": [
                {
                    "name": "f",
                    "licence": "CC0",
                    "uri_or_citation": "f",
                    "retrieved_at": "2026-10-26",
                }
            ],
        },
        "claims": [{"kind": "linguistic", "source_ref": "f"}],
        "confidence": 0.5,
        "risk_tags": [],
        "audio": [],
    }
    (tmp_path / "lexeme.json").write_text(json.dumps(bad), encoding="utf-8")

    report_path = tmp_path / "report.json"
    counts = validation_report([tmp_path], report_path)
    assert "MISSING_TONE_MARKS" in counts
    payload = json.loads(report_path.read_text(encoding="utf-8"))
    assert payload["total_findings"] >= 1
    assert "objects_with_findings" in payload


def test_P4_107_migrate_fixture_bundle_accounting(tmp_path: Path) -> None:
    bundle = tmp_path / "curriculum_bundle"
    curriculum = bundle / "curriculum" / "swahili"
    curriculum.mkdir(parents=True)
    document = {
        "meta": {
            "language": "Swahili",
            "code": "swahili",
            "level": "A1",
            "format": "modular-full-academic-sample",
            "generated_at": "2025-01-01T00:00:00Z",
        },
        "units": [
            {
                "vocab": [
                    {"word": "word1a", "meaning": "example meaning", "pos": "noun"},
                    {"word": "asante", "meaning": "thank you", "pos": "interjection"},
                ]
            }
        ],
    }
    (curriculum / "swahili_A1.json").write_text(json.dumps(document), encoding="utf-8")

    seen: set[str] = set()
    migrated, rejects = migrate_document(
        "curriculum_bundle",
        curriculum / "swahili_A1.json",
        document,
        seen_ids=seen,
    )
    assert len(migrated) == 1
    assert len(rejects) == 1
    assert migrated[0]["id"].startswith("sw.lex.")


def test_P4_107_app_loads_v2_pack_manifest(tmp_path: Path) -> None:
    objects = [
        {
            "id": "sw.lex.asante.legacy",
            "language": "sw",
            "lemma": "asante",
            "orthography": {"standard": "asante", "ascii_fallback": "asante", "script": "Latn"},
            "senses": [
                {
                    "gloss_en": "thank you",
                    "gloss_fr": "thank you",
                    "domain": "general",
                    "register": "neutral",
                }
            ],
            "cefr": "A1",
            "frequency_rank": 50_000,
            "label": "beta",
            "provenance": {
                "author": "legacy-bundle-migration",
                "created_at": "2026-10-26T00:00:00Z",
                "ai_assisted": True,
                "model_id": "legacy-curriculum-generator",
                "prompt_id": f"{CARD_ID}-migration",
                "sources": [
                    {
                        "name": "fixture",
                        "licence": "internal-legacy-unverified",
                        "uri_or_citation": "legacy:fixture",
                        "retrieved_at": "2026-10-26",
                    }
                ],
            },
            "claims": [{"kind": "linguistic", "source_ref": "legacy:fixture"}],
            "confidence": 0.35,
            "risk_tags": [],
            "audio": [],
        }
    ]
    out = tmp_path / "v2"
    packs = write_v2_packs(
        objects,
        out,
        signing_seed_hex=_FIXTURE_SEED,
        built_at="2026-10-26T12:00:00Z",
    )
    assert packs
    manifest_path = packs[0] / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    assert manifest["format"] == "lingafriq.content_pack.v2"
    rel_files = {str(p.relative_to(packs[0])): p.read_bytes() for p in packs[0].rglob("*") if p.is_file()}
    from tools.content_pipeline.pack_builder import BuiltPack

    pack = BuiltPack(
        manifest=manifest,
        signature=rel_files["signature.txt"].decode("ascii"),
        public_key=rel_files["public_key.txt"].decode("ascii"),
        files=rel_files,
    )
    assert verify_built_pack(pack) is None
    assert verify_pack_signature(pack.manifest, pack.signature, pack.public_key) is None


def test_P4_107_AC4_export_tool_has_no_legacy_bundle_paths() -> None:
    export_src = (_REPO_ROOT / "tools" / "export_backend_content_packs.py").read_text(encoding="utf-8")
    for name in LEGACY_BUNDLE_DIRS:
        assert name not in export_src
    assert "lingafriq.content_pack.v2" in export_src


def test_legacy_sample_meta_flags_ai_assisted() -> None:
    meta = {"format": "modular-full-academic-sample", "generated_at": "2025-01-01T00:00:00Z"}
    assert legacy_ai_assisted(meta) is True


@pytest.mark.skipif(
    not (_REPO_ROOT / "curriculum_bundle").is_dir(),
    reason="full legacy bundles not present",
)
def test_run_migration_on_repo_bundles(tmp_path: Path) -> None:
    result = run_migration(root=_REPO_ROOT, output_dir=tmp_path / "out", signing_seed_hex=_FIXTURE_SEED)
    total = len(result.migrated) + len(result.rejects)
    assert total > 0
    assert (tmp_path / "out" / "migration_rejects.jsonl").is_file()
