"""P5-005 audio manifest rebuild, AU-001 lint, NFC keying, dedup."""

from __future__ import annotations

import hashlib
import json
import sys
import unicodedata
from pathlib import Path

import pytest

_REPO_ROOT = Path(__file__).resolve().parents[2]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from tools.content.audio_manifest_build import (  # noqa: E402
    CARD_ID,
    RULE_AU001,
    assert_pubspec_audio_declaration,
    deduplicate_audio_files,
    entry_id,
    lint_au001_batch,
    lint_curriculum_audio_ref,
    manifest_key,
    manifest_lookup_keys,
    pubspec_declares_audio,
    rebuild_manifest_document,
    rebuild_manifest_entry,
    run_rebuild,
)
from tools.content_engine.legacy.structure import audio_content_hash  # noqa: E402

_KO_WITH_TONE = "k\u1ecd\u0301"  # kọ́ (combining acute)
_KO_PLAIN = "k\u1ecd"  # kọ


def test_P5_005_nfc_nfd_distinct_manifest_keys() -> None:
    nfc_text = unicodedata.normalize("NFC", "Ẹ káàbọ̀")
    nfd_text = unicodedata.normalize("NFD", "Ẹ káàbọ̀")
    assert manifest_key("yoruba", nfc_text) == manifest_key("yoruba", nfd_text)
    assert manifest_key("yoruba", _KO_WITH_TONE) != manifest_key("yoruba", _KO_PLAIN)


def test_P5_005_entry_uses_content_hash_paths_not_diacritic_slug() -> None:
    entry = rebuild_manifest_entry(
        {
            "id": "legacy",
            "language": "yoruba",
            "text": "Mo ń kọ́ èdè Yorùbá",
            "slow": {"asset_path": "assets/audio/yoruba/slow/yoruba-mo-ń-kọ-èdè-yorùbá.mp3", "tts_rate": 0.52},
            "native": {
                "asset_path": "assets/audio/yoruba/native/yoruba-mo-ń-kọ-èdè-yorùbá.mp3",
                "tts_rate": 0.95,
            },
        }
    )
    ch = audio_content_hash("Mo ń kọ́ èdè Yorùbá")
    assert entry["content_hash"] == ch
    assert entry["slow"]["asset_path"].endswith(f"{ch}.mp3")
    assert "kọ" not in entry["slow"]["asset_path"] or ch in entry["slow"]["asset_path"]
    assert entry["id"] == entry_id("yoruba", "Mo ń kọ́ èdè Yorùbá")


def test_P5_005_au001_fails_missing_audio_reference() -> None:
    item = {"payload": {"id": "lesson-1", "text": "Ẹ kú àárọ̀", "lang": "yo", "audio": []}}
    keys = manifest_lookup_keys(
        [rebuild_manifest_entry({"language": "yoruba", "text": "Ẹ kú àárọ̀"})]
    )
    finding = lint_curriculum_audio_ref(item, keys)
    assert finding is not None
    assert finding.rule_id == RULE_AU001


def test_P5_005_au001_passes_tts_file_hash() -> None:
    text = "Ẹ kú àárọ̀"
    manifest_entry = rebuild_manifest_entry({"language": "yoruba", "text": text})
    keys = manifest_lookup_keys([manifest_entry])
    item = {
        "payload": {
            "id": "lesson-2",
            "text": text,
            "lang": "yo",
            "audio": [{"kind": "tts", "file": f"{audio_content_hash(text)}.mp3"}],
        }
    }
    assert lint_curriculum_audio_ref(item, keys) is None


def test_P5_005_deduplicate_identical_mp3_copies(tmp_path: Path) -> None:
    data = b"fake-mp3-payload-for-dedup"
    digest = hashlib.sha256(data).hexdigest()
    a = tmp_path / f"{digest[:8]}_a.mp3"
    b = tmp_path / f"{digest[:8]}_b.mp3"
    c = tmp_path / "unique.mp3"
    a.write_bytes(data)
    b.write_bytes(data)
    c.write_bytes(b"other")
    report = deduplicate_audio_files(tmp_path)
    assert report.duplicate_files == 1
    assert report.bytes_reclaimed == len(data)
    assert a.exists() or b.exists()
    assert not (a.exists() and b.exists())


def test_P5_005_pubspec_declares_assets_audio() -> None:
    pubspec = _REPO_ROOT / "pubspec.yaml"
    assert pubspec_declares_audio(pubspec)


def test_P5_005_rebuild_manifest_dedupes_nfc_collisions() -> None:
    doc = {
        "meta": {"version": "1.0.0"},
        "entries": [
            {"language": "yoruba", "text": unicodedata.normalize("NFD", "Ó dára"), "source": "curriculum_vocab"},
            {"language": "yoruba", "text": unicodedata.normalize("NFC", "Ó dára"), "source": "curriculum_vocab"},
        ],
    }
    rebuilt, stats = rebuild_manifest_document(doc)
    assert stats.entries_out == 1
    assert rebuilt["meta"]["entry_count"] == 1


def test_P5_005_card_id_constant() -> None:
    assert CARD_ID == "P5-005"


def test_P5_005_lint_batch_collects_findings() -> None:
    keys: set[str] = set()
    items = [{"payload": {"id": "x", "audio": []}}, {"payload": {"id": "y", "audio": [{"kind": "tts", "file": "nope.mp3"}]}}]
    findings = lint_au001_batch(items, keys)
    assert len(findings) == 2
    assert all(f.rule_id == RULE_AU001 for f in findings)


def test_P5_005_run_rebuild_dry_run(tmp_path: Path) -> None:
    manifest = tmp_path / "audio_manifest.json"
    manifest.write_text(
        json.dumps(
            {
                "meta": {"version": "1.0.0"},
                "entries": [{"language": "yoruba", "text": "Ó dára", "source": "game_vocab"}],
            }
        ),
        encoding="utf-8",
    )
    pubspec = tmp_path / "pubspec.yaml"
    pubspec.write_text("flutter:\n  assets:\n    - assets/audio/\n")
    # repo_root walks parents; place manifest under fake root
    tools = tmp_path / "tools" / "content"
    tools.mkdir(parents=True)
    (tools / "audio_manifest_build.py").write_text("# stub\n")
    stats, _, _ = run_rebuild(tmp_path, dry_run=True, manifest_path=manifest)
    assert stats.entries_out == 1
    assert json.loads(manifest.read_text())["meta"]["version"] == "1.0.0"


def test_P5_005_assert_pubspec_raises_when_missing(tmp_path: Path) -> None:
    pubspec = tmp_path / "pubspec.yaml"
    pubspec.write_text("flutter:\n  assets:\n    - assets/data/foo.json\n")
    with pytest.raises(RuntimeError, match="AssetUndeclaredError"):
        assert_pubspec_audio_declaration(pubspec)
