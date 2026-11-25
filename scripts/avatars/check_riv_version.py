#!/usr/bin/env python3
"""P11-036: Pin lingafriq_cast.riv export format + editor version via CHANGELOG."""
from __future__ import annotations

import argparse
import hashlib
import re
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHANGELOG = ROOT / "assets" / "rive" / "avatars" / "CHANGELOG.md"
PIN_BLOCK_RE = re.compile(r"```riv-pin\s*\n(.*?)\n```", re.DOTALL)
KV_RE = re.compile(r"^([a-z0-9_]+):\s*(.+)\s*$")


def parse_pin_block(text: str) -> dict[str, str]:
    m = PIN_BLOCK_RE.search(text)
    if not m:
        raise ValueError("CHANGELOG.md: missing ```riv-pin``` block")
    out: dict[str, str] = {}
    for line in m.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        km = KV_RE.match(line)
        if not km:
            raise ValueError(f"CHANGELOG.md: invalid riv-pin line: {line}")
        out[km.group(1)] = km.group(2)
    return out


def read_export_format(riv_path: Path) -> tuple[int, int]:
    data = riv_path.read_bytes()
    if len(data) < 6:
        raise ValueError(f"{riv_path}: file too short for RIVE header")
    if data[:4] != b"RIVE":
        raise ValueError(f"{riv_path}: missing RIVE magic")
    return data[4], data[5]


def verify(pin: dict[str, str]) -> list[str]:
    errors: list[str] = []
    required = (
        "source_riv",
        "rive_editor",
        "export_format_major",
        "export_format_minor",
        "content_sha256",
        "content_bytes",
    )
    for key in required:
        if not pin.get(key):
            errors.append(f"riv-pin missing {key}")

    if errors:
        return errors

    riv_rel = pin["source_riv"]
    riv_path = ROOT / riv_rel
    if not riv_path.is_file():
        return [f"missing source riv: {riv_rel}"]

    body = riv_path.read_bytes()
    size = len(body)
    expected_size = int(pin["content_bytes"])
    if size != expected_size:
        errors.append(f"{riv_rel}: byte size {size} != pinned {expected_size}")

    digest = hashlib.sha256(body).hexdigest()
    if digest != pin["content_sha256"].lower():
        errors.append(f"{riv_rel}: sha256 mismatch (re-export or update CHANGELOG)")

    try:
        major, minor = read_export_format(riv_path)
    except ValueError as exc:
        return [str(exc)]

    exp_major = int(pin["export_format_major"])
    exp_minor = int(pin["export_format_minor"])
    if major != exp_major or minor != exp_minor:
        errors.append(
            f"{riv_rel}: export format {major}.{minor} != pinned {exp_major}.{exp_minor}"
        )

    if not pin["rive_editor"].strip():
        errors.append("rive_editor must name the Rive editor / CLI version used for export")

    return errors


def run_gate() -> list[str]:
    if not CHANGELOG.is_file():
        return ["assets/rive/avatars/CHANGELOG.md missing"]
    try:
        pin = parse_pin_block(CHANGELOG.read_text(encoding="utf-8"))
    except ValueError as exc:
        return [str(exc)]
    return verify(pin)


def _pin_for_bytes(rel: str, body: bytes, major: int, minor: int, editor: str) -> dict[str, str]:
    return {
        "source_riv": rel,
        "rive_editor": editor,
        "export_format_major": str(major),
        "export_format_minor": str(minor),
        "content_sha256": hashlib.sha256(body).hexdigest(),
        "content_bytes": str(len(body)),
    }


def _verify_pin_at_root(root: Path, pin: dict[str, str]) -> list[str]:
    riv_path = root / pin["source_riv"]
    if not riv_path.is_file():
        return [f"missing {pin['source_riv']}"]
    body = riv_path.read_bytes()
    errors: list[str] = []
    if len(body) != int(pin["content_bytes"]):
        errors.append("size")
    if hashlib.sha256(body).hexdigest() != pin["content_sha256"]:
        errors.append("hash")
    file_major, file_minor = read_export_format(riv_path)
    if file_major != int(pin["export_format_major"]) or file_minor != int(
        pin["export_format_minor"]
    ):
        errors.append("format")
    return errors


def self_test() -> list[str]:
    errors: list[str] = []
    if run_gate():
        errors.append("live gate failed during self-test")

    with tempfile.TemporaryDirectory() as td:
        root = Path(td)
        body = b"RIVE\x07\x09"
        riv = root / "cast.riv"
        riv.write_bytes(body)
        pin = _pin_for_bytes("cast.riv", body, 7, 3, "Test")
        if not _verify_pin_at_root(root, pin):
            errors.append("self-test: expected format mismatch failure")

        body_ok = b"RIVE\x07\x03"
        riv.write_bytes(body_ok)
        pin_ok = _pin_for_bytes("cast.riv", body_ok, 7, 3, "Test")
        if _verify_pin_at_root(root, pin_ok):
            errors.append("self-test: matching format should pass")

    if read_export_format(ROOT / "assets/rive/lingafriq_cast.riv") != (7, 3):
        errors.append("self-test: production riv header not 7.3")

    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gate", action="store_true", help="verify pinned riv export")
    parser.add_argument("--self-test", action="store_true", help="run built-in tests")
    args = parser.parse_args()

    if args.self_test:
        failures = self_test()
        if failures:
            for f in failures:
                print(f"SELF_TEST_FAIL: {f}", file=sys.stderr)
            return 1
        print("check_riv_version: self-test ok")
        return 0

    failures = run_gate()
    if failures:
        for f in failures:
            print(f"RIV_VERSION_FAIL: {f}", file=sys.stderr)
        return 1
    print("check_riv_version: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
