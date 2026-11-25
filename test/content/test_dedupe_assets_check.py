# charter: v2
"""Unit tests for scripts/ci/dedupe_assets_check.py (P12-001)."""

from __future__ import annotations

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "scripts/ci/dedupe_assets_check.py"


def _run(pubspec: Path, data_dir: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(SCRIPT),
            "--pubspec",
            str(pubspec),
            "--data-dir",
            str(data_dir),
        ],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        check=False,
    )


def test_live_pubspec_has_no_duplicate_curriculum_hashes() -> None:
    result = _run(REPO_ROOT / "pubspec.yaml", REPO_ROOT / "assets/data")
    assert result.returncode == 0, result.stderr + result.stdout


def test_duplicate_declaration_fails(tmp_path: Path) -> None:
    data = tmp_path / "assets/data"
    data.mkdir(parents=True)
    payload = b'{"languages":{}}\n'
    (data / "lingafriq_authentic_curriculum_a1_c1.json").write_bytes(payload)
    (data / "lingafriq_authentic_curriculum_a1_a2_b1.json").write_bytes(payload)
    pubspec = tmp_path / "pubspec.yaml"
    pubspec.write_text(
        "name: x\nflutter:\n  assets:\n"
        "    - assets/data/lingafriq_authentic_curriculum_a1_c1.json\n"
        "    - assets/data/lingafriq_authentic_curriculum_a1_a2_b1.json\n",
        encoding="utf-8",
    )
    result = _run(pubspec, data)
    assert result.returncode == 1
    assert "PUBSPEC_DUPLICATE_ASSET" in result.stderr


def test_single_member_per_hash_passes(tmp_path: Path) -> None:
    data = tmp_path / "assets/data"
    data.mkdir(parents=True)
    a = b'{"a":1}\n'
    b = b'{"b":2}\n'
    (data / "lingafriq_authentic_curriculum_a1.json").write_bytes(a)
    (data / "lingafriq_authentic_curriculum_a1_c2.json").write_bytes(b)
    pubspec = tmp_path / "pubspec.yaml"
    pubspec.write_text(
        "name: x\nflutter:\n  assets:\n"
        "    - assets/data/lingafriq_authentic_curriculum_a1.json\n"
        "    - assets/data/lingafriq_authentic_curriculum_a1_c2.json\n",
        encoding="utf-8",
    )
    result = _run(pubspec, data)
    assert result.returncode == 0, result.stderr
