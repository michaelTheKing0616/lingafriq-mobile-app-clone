"""Load a language kit from disk and gate generation on it."""

from __future__ import annotations

from collections.abc import Callable
from pathlib import Path
from typing import Any, TypeVar

import yaml

from tools.content_engine.kits.kit_schema import KitError, validate_kit

T = TypeVar("T")


def load_kit(language: str, kit_dir: Path | str) -> dict[str, Any]:
    """Read and validate kit_dir / f\"{language}.yaml\".

    Inputs: language code and directory of kit YAML files.
    Outputs: the validated kit mapping.
    Side effects: reads that one file. Does not substitute another path.
    Raises KitError KIT_NOT_FOUND when the file is absent.
    """
    path = Path(kit_dir) / f"{language}.yaml"
    if not path.is_file():
        raise KitError(
            "KIT_NOT_FOUND",
            f"Language kit not found for {language!r}: {path}",
        )
    with path.open(encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    return validate_kit(data)


def start_pipeline(
    language: str,
    kit_dir: Path | str,
    generate: Callable[[dict[str, Any]], T],
) -> T:
    """Load the kit, then run generate(kit).

    Inputs: language, kit directory, generate callable.
    Outputs: generate's return value.
    Side effects: load_kit I/O; generate is called only after a valid kit.
    If load_kit raises, generate is not called and the same error propagates.
    """
    kit = load_kit(language, kit_dir)
    return generate(kit)
