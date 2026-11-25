"""Lanfrica source discovery worksheet with FSI / Peace Corps cross-check (P13-002)."""

from __future__ import annotations

import argparse
import json
import os
import re
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Callable, Literal, Mapping, Sequence

CARD_ID = "P13-002"

CrossCheckAnswer = Literal["yes", "no", "not_checked"]
VerificationLabel = Literal["discovered_unverified"]

_FSI_LANGUAGE_CODES: frozenset[str] = frozenset({"yo", "ig", "ha", "sw"})
_PEACE_CORPS_LANGUAGE_CODES: frozenset[str] = frozenset({"yo", "ha", "sw", "zu"})

_ALIAS: dict[str, str] = {
    "yoruba": "yo",
    "igbo": "ig",
    "hausa": "ha",
    "swahili": "sw",
    "kiswahili": "sw",
    "zulu": "zu",
    "xhosa": "xh",
}


class LanfricaDiscoveryError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


@dataclass(frozen=True)
class LanfricaResource:
    title: str
    link: str
    licence: str
    resource_type: str
    verification: VerificationLabel = "discovered_unverified"
    fsi_language_listed: CrossCheckAnswer = "not_checked"
    peace_corps_language_listed: CrossCheckAnswer = "not_checked"


def normalize_language_id(language_id: str) -> str:
    raw = language_id.strip().lower()
    if not re.fullmatch(r"[a-z]{2,3}(-[a-z]{4})?", raw):
        raise LanfricaDiscoveryError("LANGUAGE_ID_INVALID", "language_id must be a BCP-47-style id")
    base = raw.split("-", 1)[0]
    return _ALIAS.get(base, base)


def cross_check_fsi(language_id: str) -> CrossCheckAnswer:
    code = normalize_language_id(language_id)
    return "yes" if code in _FSI_LANGUAGE_CODES else "no"


def cross_check_peace_corps(language_id: str) -> CrossCheckAnswer:
    code = normalize_language_id(language_id)
    return "yes" if code in _PEACE_CORPS_LANGUAGE_CODES else "no"


def parse_lanfrica_payload(payload: Mapping[str, Any]) -> list[dict[str, str]]:
    results = payload.get("results")
    if not isinstance(results, list):
        raise LanfricaDiscoveryError("LANFRICA_RESPONSE_INVALID", "payload.results must be a list")
    parsed: list[dict[str, str]] = []
    for index, item in enumerate(results):
        if not isinstance(item, Mapping):
            raise LanfricaDiscoveryError(
                "LANFRICA_RESPONSE_INVALID",
                f"results[{index}] must be an object",
            )
        title = str(item.get("title", "")).strip()
        link = str(item.get("url", item.get("link", ""))).strip()
        licence = str(item.get("licence", "")).strip()
        resource_type = str(item.get("resource_type", item.get("type", ""))).strip()
        if not title or not link or not licence or not resource_type:
            raise LanfricaDiscoveryError(
                "LANFRICA_RESPONSE_INVALID",
                f"results[{index}] requires title, url, licence, resource_type",
            )
        parsed.append(
            {
                "title": title,
                "link": link,
                "licence": licence,
                "resource_type": resource_type,
            }
        )
    return parsed


def build_resources(
    language_id: str,
    raw_results: Sequence[Mapping[str, str]],
) -> list[LanfricaResource]:
    fsi = cross_check_fsi(language_id)
    peace = cross_check_peace_corps(language_id)
    return [
        LanfricaResource(
            title=row["title"],
            link=row["link"],
            licence=row["licence"],
            resource_type=row["resource_type"],
            fsi_language_listed=fsi,
            peace_corps_language_listed=peace,
        )
        for row in raw_results
    ]


def build_worksheet(
    language_id: str,
    display_name: str,
    resources: Sequence[LanfricaResource],
) -> dict[str, Any]:
    lang = normalize_language_id(language_id)
    name = display_name.strip()
    if not name:
        raise LanfricaDiscoveryError("DISPLAY_NAME_MISSING", "display_name is required")
    return {
        "card_id": CARD_ID,
        "language_id": lang,
        "display_name": name,
        "discovery_only": True,
        "lanfrica_status": "discovered_unverified",
        "cross_check": {
            "fsi_language_listed": cross_check_fsi(lang),
            "peace_corps_language_listed": cross_check_peace_corps(lang),
        },
        "sources": [asdict(resource) for resource in resources],
    }


def default_http_fetch(language_id: str) -> Mapping[str, Any]:
    template = os.environ.get("LANFRICA_DISCOVERY_URL", "").strip()
    if not template:
        raise LanfricaDiscoveryError(
            "LANFRICA_URL_NOT_CONFIGURED",
            "Set LANFRICA_DISCOVERY_URL (may include {language_id}) before live discovery",
        )
    url = template.format(language_id=normalize_language_id(language_id))
    request = urllib.request.Request(url, headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            body = response.read().decode("utf-8")
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as exc:
        raise LanfricaDiscoveryError("LANFRICA_UNREACHABLE", f"Lanfrica fetch failed: {exc}") from exc
    try:
        data = json.loads(body)
    except json.JSONDecodeError as exc:
        raise LanfricaDiscoveryError("LANFRICA_RESPONSE_INVALID", "response is not JSON") from exc
    if not isinstance(data, dict):
        raise LanfricaDiscoveryError("LANFRICA_RESPONSE_INVALID", "response root must be an object")
    return data


def generate_worksheet(
    language_id: str,
    display_name: str,
    *,
    fetcher: Callable[[str], Mapping[str, Any]] | None = None,
) -> dict[str, Any]:
    fetch = fetcher or default_http_fetch
    payload = fetch(language_id)
    rows = parse_lanfrica_payload(payload)
    resources = build_resources(language_id, rows)
    return build_worksheet(language_id, display_name, resources)


def write_worksheet(path: Path, worksheet: Mapping[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(worksheet, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Lanfrica discovery worksheet (P13-002)")
    sub = parser.add_subparsers(dest="command", required=True)

    gen = sub.add_parser("worksheet", help="Generate a discovery worksheet for a candidate language")
    gen.add_argument("language_id")
    gen.add_argument("display_name")
    gen.add_argument("-o", "--output", type=Path, required=True)
    gen.add_argument(
        "--fixture",
        type=Path,
        help="Recorded Lanfrica JSON (results array); skips live HTTP",
    )

    args = parser.parse_args(argv)

    def _fetcher(language: str) -> Mapping[str, Any]:
        if args.fixture is None:
            return default_http_fetch(language)
        if not args.fixture.is_file():
            raise LanfricaDiscoveryError("FIXTURE_MISSING", f"fixture not found: {args.fixture}")
        data = json.loads(args.fixture.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise LanfricaDiscoveryError("FIXTURE_INVALID", "fixture root must be an object")
        return data

    worksheet = generate_worksheet(args.language_id, args.display_name, fetcher=_fetcher)
    write_worksheet(args.output, worksheet)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
