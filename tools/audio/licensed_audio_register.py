"""Register licensed human audio pools for yo, ig, ha (P5-063, CURRICULUM §7)."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Mapping, Sequence

from tools.content_engine.licences.register_schema import (
    load_register_csv,
    register_index,
)

CARD_ID = "P5-063"
SCHEMA_VERSION = "1.0.0"
OUTPUT_REL = "assets/data/audio/licensed_human.json"
STAGE1_TONAL: tuple[str, ...] = ("yo", "ig", "ha")

_TONE_DRILL_USE = "tone_drills"
_OWN_SENTENCES_SCOPE = "own_sentences_only"
_FSI_TAPE_PROVIDER = "fsi_tapes"
_CV_PROVIDER = "common_voice"
_FLEURS_PROVIDER = "fleurs"

_FSI_LICENCE_BY_LANG: dict[str, str] = {
    "yo": "fsi-yoruba",
    "ig": "fsi-igbo",
    "ha": "fsi-hausa",
}

_CV_LICENCE_BY_LANG: dict[str, str] = {
    "yo": "common-voice-yo",
    "ig": "common-voice-ig",
    "ha": "common-voice-ha",
}

_FLEURS_LICENCE = "fleurs"


class LicensedAudioError(Exception):
    """Licensed human audio registry failure."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class LicenceUnregistered(LicensedAudioError):
    """Pool references a licence id that is not in the shipped register."""


@dataclass(frozen=True)
class AudioPool:
    pool_id: str
    language: str
    provider: str
    licence_id: str
    licence: str
    quality: str
    allowed_use: tuple[str, ...]
    text_scope: str
    register_url: str
    notes: str

    def to_dict(self) -> dict[str, Any]:
        return {
            "pool_id": self.pool_id,
            "language": self.language,
            "provider": self.provider,
            "licence_id": self.licence_id,
            "licence": self.licence,
            "quality": self.quality,
            "allowed_use": list(self.allowed_use),
            "text_scope": self.text_scope,
            "register_url": self.register_url,
            "notes": self.notes,
        }


def repo_root(start: Path | None = None) -> Path:
    here = (start or Path(__file__)).resolve()
    for parent in (here, *here.parents):
        if (parent / "pubspec.yaml").is_file():
            return parent
    raise FileNotFoundError("mobile app root (pubspec.yaml) not found")


def default_register_csv(root: Path | None = None) -> Path:
    return repo_root(root) / "tools/content_engine/licences/register.csv"


def assert_registered_licence(
    licence_id: str,
    register_rows: Sequence[Mapping[str, str]],
) -> Mapping[str, str]:
    lid = licence_id.strip()
    if not lid:
        raise LicenceUnregistered("LicenceUnregistered", "empty licence_id")
    row = register_index(register_rows).get(lid)
    if row is None:
        raise LicenceUnregistered(
            "LicenceUnregistered",
            f"licence_id not in licence register: {lid}",
        )
    return row


def _row_licence_label(row: Mapping[str, str]) -> str:
    return str(row.get("licence", "")).strip()


def validate_pool_dict(
    entry: Mapping[str, Any],
    register_rows: Sequence[Mapping[str, str]],
) -> None:
    licence_id = entry.get("licence_id")
    if not isinstance(licence_id, str) or not licence_id.strip():
        raise LicenceUnregistered("LicenceUnregistered", "missing licence_id on pool entry")
    row = assert_registered_licence(licence_id, register_rows)
    provider = entry.get("provider")
    text_scope = entry.get("text_scope")
    if provider == _FSI_TAPE_PROVIDER:
        if text_scope != "fsi_course_recordings":
            raise LicensedAudioError(
                "FSI_SCOPE_INVALID",
                f"FSI pool {entry.get('pool_id')!r} must use fsi_course_recordings scope",
            )
        allowed = entry.get("allowed_use")
        if not isinstance(allowed, list) or _TONE_DRILL_USE not in allowed:
            raise LicensedAudioError(
                "FSI_USE_INVALID",
                f"FSI pool {entry.get('pool_id')!r} must allow tone_drills",
            )
        if _row_licence_label(row) != "public-domain":
            raise LicensedAudioError(
                "FSI_LICENCE_INVALID",
                f"FSI pool {entry.get('pool_id')!r} must be public-domain in register",
            )
        if entry.get("quality") != "dated":
            raise LicensedAudioError(
                "FSI_QUALITY_INVALID",
                f"FSI pool {entry.get('pool_id')!r} must record dated quality",
            )
    elif provider in (_CV_PROVIDER, _FLEURS_PROVIDER):
        if text_scope != _OWN_SENTENCES_SCOPE:
            raise LicensedAudioError(
                "CORPUS_SCOPE_INVALID",
                f"{provider} pool {entry.get('pool_id')!r} must use own_sentences_only",
            )
    else:
        raise LicensedAudioError(
            "PROVIDER_INVALID",
            f"unknown provider {provider!r} on pool {entry.get('pool_id')!r}",
        )


def _fsi_pool(language: str, register_rows: Sequence[Mapping[str, str]]) -> AudioPool:
    licence_id = _FSI_LICENCE_BY_LANG[language]
    row = assert_registered_licence(licence_id, register_rows)
    return AudioPool(
        pool_id=f"{licence_id}-tapes",
        language=language,
        provider=_FSI_TAPE_PROVIDER,
        licence_id=licence_id,
        licence=_row_licence_label(row),
        quality="dated",
        allowed_use=(_TONE_DRILL_USE,),
        text_scope="fsi_course_recordings",
        register_url=str(row.get("url", "")).strip(),
        notes="US FSI Basic Course tape recordings; CURRICULUM §7 tone-drill interim human audio.",
    )


def _cv_pool(language: str, register_rows: Sequence[Mapping[str, str]]) -> AudioPool:
    licence_id = _CV_LICENCE_BY_LANG[language]
    row = assert_registered_licence(licence_id, register_rows)
    return AudioPool(
        pool_id=f"{licence_id}-clips",
        language=language,
        provider=_CV_PROVIDER,
        licence_id=licence_id,
        licence=_row_licence_label(row),
        quality="community",
        allowed_use=("learner_audio",),
        text_scope=_OWN_SENTENCES_SCOPE,
        register_url=str(row.get("url", "")).strip(),
        notes="Mozilla Common Voice clips may only back the exact sentence they were recorded for.",
    )


def _fleurs_pool(language: str, register_rows: Sequence[Mapping[str, str]]) -> AudioPool:
    row = assert_registered_licence(_FLEURS_LICENCE, register_rows)
    return AudioPool(
        pool_id=f"fleurs-{language}",
        language=language,
        provider=_FLEURS_PROVIDER,
        licence_id=_FLEURS_LICENCE,
        licence=_row_licence_label(row),
        quality="parallel_corpus",
        allowed_use=("learner_audio",),
        text_scope=_OWN_SENTENCES_SCOPE,
        register_url=str(row.get("url", "")).strip(),
        notes="FLEURS audio may only back the FLEURS transcript sentence it ships with.",
    )


def canonical_pools(
    register_rows: Sequence[Mapping[str, str]],
    languages: Sequence[str] = STAGE1_TONAL,
) -> list[AudioPool]:
    pools: list[AudioPool] = []
    for lang in languages:
        code = lang.strip().lower()
        if code not in STAGE1_TONAL:
            raise LicensedAudioError(
                "LANGUAGE_UNSUPPORTED",
                f"licensed human audio registry covers yo/ig/ha only, got {code!r}",
            )
        pools.extend(
            [
                _fsi_pool(code, register_rows),
                _cv_pool(code, register_rows),
                _fleurs_pool(code, register_rows),
            ]
        )
    return pools


def build_document(
    register_rows: Sequence[Mapping[str, str]],
    *,
    languages: Sequence[str] = STAGE1_TONAL,
) -> dict[str, Any]:
    pools = canonical_pools(register_rows, languages=languages)
    for pool in pools:
        validate_pool_dict(pool.to_dict(), register_rows)
    by_lang: dict[str, list[dict[str, Any]]] = {lang: [] for lang in STAGE1_TONAL}
    for pool in pools:
        by_lang[pool.language].append(pool.to_dict())
    return {
        "card_id": CARD_ID,
        "schema_version": SCHEMA_VERSION,
        "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "curriculum_anchor": "CURRICULUM.md#§7:L704-L729",
        "languages": by_lang,
    }


def write_registry(
    path: Path,
    register_rows: Sequence[Mapping[str, str]],
    *,
    languages: Sequence[str] = STAGE1_TONAL,
) -> dict[str, Any]:
    doc = build_document(register_rows, languages=languages)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return doc


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Build licensed human audio registry (P5-063).")
    parser.add_argument(
        "--register",
        type=Path,
        default=None,
        help="Path to licence register.csv",
    )
    parser.add_argument(
        "--out",
        type=Path,
        default=None,
        help=f"Output JSON path (default: {OUTPUT_REL})",
    )
    args = parser.parse_args(list(argv) if argv is not None else None)
    base = repo_root()
    register_path = args.register or default_register_csv(base)
    out_path = args.out or (base / OUTPUT_REL)
    rows = load_register_csv(register_path)
    doc = write_registry(out_path, rows)
    print(json.dumps({"card_id": CARD_ID, "pools": sum(len(v) for v in doc["languages"].values()), "out": str(out_path)}))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
