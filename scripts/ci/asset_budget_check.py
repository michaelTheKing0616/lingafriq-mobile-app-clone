#!/usr/bin/env python3
# charter: v2
"""P12-009: Fail CI when bundled images or Rive files exceed configured byte budgets.

Usage:
  python3 scripts/ci/asset_budget_check.py [--root .] [--config assets/images/asset_budget_config.json]
  python3 scripts/ci/asset_budget_check.py --self-test

Exit codes:
  0  all assets within budget
  1  one or more files over budget (listed on stderr)
  2  missing config or usage error
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

DEFAULT_CONFIG_REL = Path("assets/images/asset_budget_config.json")


def load_config(path: Path) -> dict[str, Any]:
    if not path.is_file():
        raise FileNotFoundError(f"ASSET_BUDGET_CONFIG_MISSING: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"ASSET_BUDGET_CONFIG_INVALID: {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ValueError(f"ASSET_BUDGET_CONFIG_INVALID: root must be object ({path})")
    for key in (
        "scan_roots",
        "rive_character_file_max_bytes",
        "rive_character_basenames",
        "extension_max_bytes",
    ):
        if key not in data:
            raise ValueError(f"ASSET_BUDGET_CONFIG_INVALID: missing key '{key}' in {path}")
    return data


def budget_for_file(rel_posix: str, size: int, name: str, config: dict[str, Any]) -> tuple[int, str]:
    overrides = config.get("path_overrides") or {}
    if rel_posix in overrides:
        row = overrides[rel_posix]
        cap = int(row["max_bytes"])
        return cap, "path_override"

    suffix = Path(name).suffix.lower()
    if suffix == ".riv":
        basenames = set(config.get("rive_character_basenames") or [])
        if name in basenames:
            cap = int(config["rive_character_file_max_bytes"])
            return cap, "rive_character"
        cap = int(config.get("rive_default_max_bytes", config["rive_character_file_max_bytes"]))
        return cap, "rive_default"

    ext_map = config.get("extension_max_bytes") or {}
    if suffix in ext_map:
        return int(ext_map[suffix]), f"extension{suffix}"

    if not suffix and "no_extension_max_bytes" in config:
        return int(config["no_extension_max_bytes"]), "no_extension"

    raise KeyError(
        f"ASSET_BUDGET_UNCONFIGURED: {rel_posix} ({size} bytes) has no extension rule or override",
    )


def collect_violations(root: Path, config: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    for rel_root in config["scan_roots"]:
        base = root / rel_root
        if not base.is_dir():
            errors.append(f"ASSET_BUDGET_SCAN_ROOT_MISSING: {rel_root}")
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            rel_posix = path.relative_to(root).as_posix()
            size = path.stat().st_size
            try:
                cap, rule = budget_for_file(rel_posix, size, path.name, config)
            except KeyError as exc:
                errors.append(str(exc))
                continue
            if size > cap:
                errors.append(
                    f"ASSET_BUDGET_EXCEEDED: {rel_posix} {size} bytes > {cap} ({rule})",
                )
    return errors


def run_self_test() -> list[str]:
    failures: list[str] = []
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        cfg_path = root / "assets" / "images" / "asset_budget_config.json"
        cfg_path.parent.mkdir(parents=True)
        tiny_cfg = {
            "scan_roots": ["assets/images"],
            "rive_character_file_max_bytes": 307200,
            "rive_character_basenames": ["lingafriq_cast.riv"],
            "rive_default_max_bytes": 307200,
            "extension_max_bytes": {".png": 10},
            "path_overrides": {},
        }
        cfg_path.write_text(json.dumps(tiny_cfg), encoding="utf-8")
        img = root / "assets" / "images" / "big.png"
        img.write_bytes(b"x" * 20)
        errs = collect_violations(root, load_config(cfg_path))
        if not any("ASSET_BUDGET_EXCEEDED" in e for e in errs):
            failures.append("self-test: expected budget exceeded on big.png")
        missing = root / "assets" / "images" / "noconfig.json"
        missing_cfg = root / "missing.json"
        try:
            load_config(missing_cfg)
        except FileNotFoundError:
            pass
        else:
            failures.append("self-test: missing config should raise FileNotFoundError")
    return failures


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Image and Rive asset byte budget gate (P12-009)")
    parser.add_argument("--root", type=Path, default=Path("."), help="Repository root")
    parser.add_argument(
        "--config",
        type=Path,
        default=None,
        help=f"Budget config JSON (default: <root>/{DEFAULT_CONFIG_REL})",
    )
    parser.add_argument("--self-test", action="store_true", help="Run built-in checks")
    args = parser.parse_args(argv)

    if args.self_test:
        failures = run_self_test()
        if failures:
            for line in failures:
                print(line, file=sys.stderr)
            return 1
        print("asset_budget_check self-test ok")
        return 0

    root = args.root.resolve()
    config_path = (args.config or (root / DEFAULT_CONFIG_REL)).resolve()
    try:
        config = load_config(config_path)
    except (FileNotFoundError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 2

    errors = collect_violations(root, config)
    if errors:
        for line in errors:
            print(line, file=sys.stderr)
        return 1
    print(f"asset_budget_check ok ({config_path.relative_to(root)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
