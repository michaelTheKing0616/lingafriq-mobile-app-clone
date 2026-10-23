"""Licence register row schema and validation (CURRICULUM §2.1)."""

from __future__ import annotations

import csv
import re
from pathlib import Path
from typing import Iterable, Mapping, MutableMapping, Sequence

REGISTER_CSV_COLUMNS: tuple[str, ...] = (
    "source_id",
    "url",
    "licence",
    "version_or_date",
    "display",
    "evidence",
    "training",
    "attribution_text",
    "owner_signoff",
)

REGISTER_OPTIONAL_COLUMNS: tuple[str, ...] = (
    "pd_status",
    "modernise_vocabulary",
    "share_alike",
    "religious_register",
    "excluded_uses",
    "languages",
    "permitted_uses",
    "recorded_hours",
    "hours_status",
    "dataset_version",
    "igbo_cc_by_titles",
)

_IGBO_CC_BY_TITLES_RE = re.compile(r"^\d+$")

_COMMON_VOICE_SOURCE_ID: dict[str, str] = {
    "yo": "common-voice-yo",
    "ha": "common-voice-ha",
    "ig": "common-voice-ig",
    "sw": "common-voice-sw",
    "zu": "common-voice-zu",
    "xh": "common-voice-xh",
}

_LEIPZIG_NC_USES: frozenset[str] = frozenset(
    {
        "web service",
        "web-service",
        "web services",
        "application",
        "applications",
    }
)

_LEIPZIG_ALLOWED_USES: frozenset[str] = frozenset({"download", "frequency"})

FSI_NO_COURSE_NOTE = "No FSI Zulu or Xhosa course found"

_ZULU_NON_FSI_GRAMMAR = "Poulos & Msimang [purchase]"
_XHOSA_NON_FSI_GRAMMAR = "a standard Xhosa reference grammar [linguist to choose]"

_FSI_LANGUAGE_SOURCE_ID: dict[str, str] = {
    "yo": "fsi-yoruba",
    "yoruba": "fsi-yoruba",
    "ig": "fsi-igbo",
    "igbo": "fsi-igbo",
    "ha": "fsi-hausa",
    "hausa": "fsi-hausa",
    "sw": "fsi-swahili",
    "swahili": "fsi-swahili",
}

_REQUIRED_FIELDS: tuple[str, ...] = (
    "url",
    "licence",
    "version_or_date",
    "display",
    "evidence",
    "training",
    "attribution_text",
    "owner_signoff",
)

_USE_FIELDS: tuple[str, ...] = ("display", "evidence", "training")

_ITEM_KINDS: frozenset[str] = frozenset({"lexicon", "corpus", "audio"})

_NONCOMMERCIAL_LICENCE_RE = re.compile(
    r"by-nc|by-sa|non-commercial", re.IGNORECASE
)


class LicenceRegisterError(Exception):
    """Validation failure for the licence register."""

    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


def _field_absent(row: Mapping[str, str], field: str) -> bool:
    if field not in row:
        return True
    if field in _USE_FIELDS or field == "owner_signoff":
        return False
    value = row[field]
    if value is None:
        return True
    if isinstance(value, str) and value.strip() == "":
        return True
    return False


def _parse_use_flag(field: str, raw: str) -> bool:
    if raw not in ("true", "false"):
        raise LicenceRegisterError(
            "LICENCE_USE_INVALID",
            f"Use flag {field} must be 'true' or 'false', got {raw!r}",
        )
    return raw == "true"


def _licence_restricts_display_training(licence: str) -> bool:
    return _NONCOMMERCIAL_LICENCE_RE.search(licence) is not None


def _validate_optional_columns(row: Mapping[str, str]) -> None:
    pd_status = row.get("pd_status", "").strip()
    if pd_status and pd_status not in ("confirmed", "unconfirmed"):
        raise LicenceRegisterError(
            "LICENCE_PD_STATUS_INVALID",
            f"pd_status must be 'confirmed' or 'unconfirmed', got {pd_status!r}",
        )
    modernise = row.get("modernise_vocabulary", "").strip()
    if modernise and modernise not in ("true", "false"):
        raise LicenceRegisterError(
            "LICENCE_MODERNISE_INVALID",
            f"modernise_vocabulary must be 'true' or 'false', got {modernise!r}",
        )
    share_alike = row.get("share_alike", "").strip()
    if share_alike and share_alike not in ("true", "false"):
        raise LicenceRegisterError(
            "LICENCE_SHARE_ALIKE_INVALID",
            f"share_alike must be 'true' or 'false', got {share_alike!r}",
        )
    religious_register = row.get("religious_register", "").strip()
    if religious_register and religious_register not in ("true", "false"):
        raise LicenceRegisterError(
            "LICENCE_RELIGIOUS_REGISTER_INVALID",
            f"religious_register must be 'true' or 'false', got {religious_register!r}",
        )
    hours_status = row.get("hours_status", "").strip()
    if hours_status and hours_status not in ("recorded", "verify"):
        raise LicenceRegisterError(
            "LICENCE_HOURS_STATUS_INVALID",
            f"hours_status must be 'recorded' or 'verify', got {hours_status!r}",
        )
    igbo_count = row.get("igbo_cc_by_titles", "").strip()
    if igbo_count and igbo_count not in ("none", "unverified"):
        if not _IGBO_CC_BY_TITLES_RE.fullmatch(igbo_count):
            raise LicenceRegisterError(
                "IGBO_COUNT_INVALID",
                "igbo_cc_by_titles must be empty, 'none', 'unverified', "
                f"or digits only, got {igbo_count!r}",
            )


def apply_pd_status_constraints(row: MutableMapping[str, str]) -> None:
    """Force display and training off when public-domain status is unconfirmed."""
    if row.get("pd_status", "").strip() == "unconfirmed":
        row["display"] = "false"
        row["training"] = "false"


def non_fsi_grammar(language: str) -> str | None:
    """Curriculum language-kit grammar locator when no FSI course exists."""
    code = language.strip().lower()
    if code in ("zu", "zulu"):
        return _ZULU_NON_FSI_GRAMMAR
    if code in ("xh", "xhosa"):
        return _XHOSA_NON_FSI_GRAMMAR
    return None


def common_voice_hours(
    language: str,
    rows: Sequence[Mapping[str, str]],
) -> dict[str, float | str | None]:
    """Recorded hours, status, and dataset version for a Common Voice language."""
    code = language.strip().lower()
    source_id = _COMMON_VOICE_SOURCE_ID.get(code)
    if source_id is None:
        raise ValueError(f"Unknown Common Voice language code: {language!r}")
    row = register_index(rows).get(source_id)
    if row is None:
        raise LicenceRegisterError(
            "LICENCE_UNREGISTERED",
            f"source_id not in licence register: {source_id}",
        )
    raw_hours = row.get("recorded_hours", "").strip()
    hours: float | None
    if raw_hours == "":
        hours = None
    else:
        hours = float(raw_hours)
    status = row.get("hours_status", "").strip()
    raw_version = row.get("dataset_version", "").strip()
    version: float | None = float(raw_version) if raw_version else None
    return {"hours": hours, "status": status, "version": version}


def fsi_course(
    language: str,
    register_rows: Sequence[Mapping[str, str]],
) -> Mapping[str, str] | None:
    """Return the FSI register row for a language code, or None if none exists."""
    code = language.strip().lower()
    if code in ("zu", "xh", "zulu", "xhosa"):
        return None
    source_id = _FSI_LANGUAGE_SOURCE_ID.get(code)
    if source_id is None:
        return None
    return register_index(register_rows).get(source_id)


def require_modernised(
    row: Mapping[str, str],
    item: Mapping[str, str],
) -> None:
    """Require lexicon items to be marked modernised when the source demands it."""
    if row.get("modernise_vocabulary", "").strip() != "true":
        return
    if "modernised" in item:
        raw = item["modernised"]
    elif "modernized" in item:
        raw = item["modernized"]
    else:
        return
    if isinstance(raw, str):
        raw = raw.strip().lower()
    if raw in ("false", False):
        raise LicenceRegisterError(
            "MODERNISE_REQUIRED",
            "Vocabulary must be modernised for source "
            f"{row.get('source_id', '')!r} (1960s-language register)",
        )


def validate_row(row: Mapping[str, str]) -> None:
    """Validate a single register row; raise LicenceRegisterError on failure."""
    _validate_optional_columns(row)
    licence = row.get("licence", "")
    for field in _REQUIRED_FIELDS:
        if field == "attribution_text" and licence == "CC0":
            continue
        if _field_absent(row, field):
            raise LicenceRegisterError(
                "LICENCE_FIELD_MISSING",
                f"Required field missing or empty: {field}",
            )

    uses: dict[str, bool] = {}
    for field in _USE_FIELDS:
        raw = row[field]
        if raw is None or (isinstance(raw, str) and raw.strip() == ""):
            raise LicenceRegisterError(
                "LICENCE_USE_INVALID",
                f"Use flag {field} must be 'true' or 'false', got {raw!r}",
            )
        uses[field] = _parse_use_flag(field, raw)

    signoff = row["owner_signoff"]
    if signoff.strip() == "" and (uses["display"] or uses["training"]):
        raise LicenceRegisterError(
            "LICENCE_UNSIGNED",
            "owner_signoff is empty while display or training is true",
        )

    if (uses["display"] or uses["training"]) and _licence_restricts_display_training(
        licence
    ):
        raise LicenceRegisterError(
            "LICENCE_NONCOMMERCIAL",
            "Licence does not permit display or training: "
            f"{licence!r} (BY-NC, BY-SA, or non-commercial)",
        )


def validate_rows(rows: Iterable[Mapping[str, str]]) -> None:
    for row in rows:
        validate_row(row)


def assert_no_biblica_mark(text: str) -> None:
    """Reject derivative strings that retain the Biblica trademark."""
    if "biblica" in text.casefold():
        raise LicenceRegisterError(
            "BIBLICA_MARK_PRESENT",
            "Derivative text must not contain the Biblica trademark",
        )


def _check_religious_register_use(row: Mapping[str, str], item: Mapping[str, str]) -> None:
    if row.get("religious_register", "").strip() != "true":
        return
    kind = item["kind"]
    if kind in ("lexicon", "audio"):
        raise LicenceRegisterError(
            "BIBLE_USE_FORBIDDEN",
            f"Source {row.get('source_id', '')!r} is religious-register; "
            f"{kind} use is forbidden (corpus and frequency evidence only)",
        )
    if kind == "corpus":
        evidence_use = item.get("evidence_use", "").strip().lower()
        if evidence_use in ("", "corpus", "frequency"):
            return
        raise LicenceRegisterError(
            "BIBLE_USE_FORBIDDEN",
            f"Source {row.get('source_id', '')!r} is religious-register; "
            "corpus items allow only corpus or frequency evidence_use",
        )
    raise LicenceRegisterError(
        "BIBLE_USE_FORBIDDEN",
        f"Source {row.get('source_id', '')!r} is religious-register; "
        "corpus and frequency evidence only",
    )


def register_index(
    register_rows: Sequence[Mapping[str, str]] | Mapping[str, Mapping[str, str]],
) -> dict[str, Mapping[str, str]]:
    if isinstance(register_rows, Mapping):
        if register_rows and not isinstance(next(iter(register_rows.values())), Mapping):
            raise TypeError("register_rows mapping values must be row mappings")
        return dict(register_rows)
    index: dict[str, Mapping[str, str]] = {}
    for row in register_rows:
        source_id = row.get("source_id", "")
        if source_id:
            index[source_id] = row
    return index


def check_items(
    register_rows: Sequence[Mapping[str, str]] | Mapping[str, Mapping[str, str]],
    items: Sequence[Mapping[str, str]],
) -> None:
    """Ensure each content item cites a registered, valid source."""
    index = register_index(register_rows)
    for item in items:
        source_id = item["source_id"]
        kind = item["kind"]
        if kind not in _ITEM_KINDS:
            raise LicenceRegisterError(
                "LICENCE_ITEM_KIND_INVALID",
                f"Item kind must be lexicon, corpus, or audio, got {kind!r}",
            )
        if source_id not in index:
            raise LicenceRegisterError(
                "LICENCE_UNREGISTERED",
                f"source_id not in licence register: {source_id}",
            )
        row = index[source_id]
        validate_row(row)
        if source_id == "wiktionary-kaikki" and item.get("copy_into") == "proprietary_lexicon":
            raise LicenceRegisterError(
                "WIKTIONARY_LEXICON_COPY",
                "Wiktionary/Kaikki data must not be copied into the proprietary lexicon",
            )
        _check_religious_register_use(row, item)
        if kind == "lexicon":
            require_modernised(row, item)


def load_register_csv(path: Path | str) -> list[dict[str, str]]:
    path = Path(path)
    with path.open(newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        if reader.fieldnames is None:
            raise LicenceRegisterError(
                "LICENCE_FIELD_MISSING",
                "Register CSV has no header row",
            )
        header = list(reader.fieldnames)
        for column in REGISTER_CSV_COLUMNS:
            if column not in header:
                raise LicenceRegisterError(
                    "LICENCE_FIELD_MISSING",
                    f"Required column missing from register CSV: {column}",
                )
        rows: list[dict[str, str]] = []
        for raw in reader:
            row: dict[str, str] = {}
            for column in REGISTER_CSV_COLUMNS + REGISTER_OPTIONAL_COLUMNS:
                if column in raw and raw[column] is not None:
                    row[column] = raw[column]
            apply_pd_status_constraints(row)
            rows.append(row)
        return rows


def ensure_row_columns(row: MutableMapping[str, str]) -> None:
    """Ensure a row dict includes every column key (values may be empty)."""
    for column in REGISTER_CSV_COLUMNS:
        row.setdefault(column, "")


def leipzig_use(use: str) -> None:
    """Reject Leipzig uses excluded as CC BY-NC (web services and applications)."""
    normalized = use.strip().casefold()
    if normalized in _LEIPZIG_ALLOWED_USES:
        return None
    if normalized in _LEIPZIG_NC_USES:
        raise LicenceRegisterError(
            "LICENCE_NC_EXCLUDED",
            "Leipzig web services and applications are CC BY-NC and excluded",
        )
    return None


def ingest_story(story: dict) -> dict:
    """Accept only CC BY African Storybook entries with a named author."""
    licence = str(story.get("licence", ""))
    if _NONCOMMERCIAL_LICENCE_RE.search(licence):
        raise LicenceRegisterError(
            "LICENCE_NC_EXCLUDED",
            "Story licence is non-commercial or share-alike and excluded",
        )
    if not licence.strip().startswith("CC BY"):
        raise LicenceRegisterError(
            "LICENCE_NC_EXCLUDED",
            "Story licence must be CC BY",
        )
    author = story.get("author")
    if author is None or (isinstance(author, str) and author.strip() == ""):
        raise LicenceRegisterError(
            "STORY_AUTHOR_MISSING",
            "Story author is required for attribution",
        )
    return story
