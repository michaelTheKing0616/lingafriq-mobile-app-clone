#!/usr/bin/env python3
"""Write a CycloneDX SBOM from a pubspec.lock. charter: v2"""

import json
import sys
from pathlib import Path


def packages(text: str) -> list[tuple[str, str]]:
    found: list[tuple[str, str]] = []
    name = None
    version = None
    in_packages = False
    for line in text.splitlines():
        if line.startswith("packages:"):
            in_packages = True
            continue
        if not in_packages:
            continue
        if line.startswith("  ") and not line.startswith("    ") and line.rstrip().endswith(":"):
            if name and version:
                found.append((name, version))
            name = line.strip()[:-1]
            version = None
            continue
        stripped = line.strip()
        if stripped.startswith("version:"):
            version = stripped.split(":", 1)[1].strip().strip('"')
    if name and version:
        found.append((name, version))
    return found


def app_version(pubspec: str) -> tuple[str, str]:
    name = "lingafriq"
    version = "0.0.0"
    for line in pubspec.splitlines():
        if line.startswith("name:"):
            name = line.split(":", 1)[1].strip()
        elif line.startswith("version:"):
            version = line.split(":", 1)[1].strip().split("+", 1)[0]
    return name, version


def bom(lock_text: str, pubspec_text: str) -> dict:
    name, version = app_version(pubspec_text)
    components = [
        {
            "type": "library",
            "name": package,
            "version": package_version,
            "purl": f"pkg:pub/{package}@{package_version}",
        }
        for package, package_version in packages(lock_text)
    ]
    return {
        "bomFormat": "CycloneDX",
        "specVersion": "1.5",
        "version": 1,
        "metadata": {
            "component": {"type": "application", "name": name, "version": version}
        },
        "components": components,
    }


def main() -> None:
    lock = Path(sys.argv[1] if len(sys.argv) > 1 else "pubspec.lock")
    out = Path(sys.argv[2] if len(sys.argv) > 2 else "app.cdx.json")
    pubspec = lock.with_name("pubspec.yaml")
    document = bom(lock.read_text(), pubspec.read_text() if pubspec.exists() else "")
    if not document["components"]:
        raise SystemExit("pubspec.lock produced an empty SBOM")
    out.write_text(json.dumps(document, indent=2) + "\n")
    print(f"wrote {len(document['components'])} components to {out}")


if __name__ == "__main__":
    main()
