#!/usr/bin/env python3
"""Copy bundled CMS manifests into node-backend-safe-push/data/content-packs/."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "data" / "cms_manifests"
BACKEND_PACKS = ROOT.parent / "node-backend-safe-push" / "data" / "content-packs"


def main() -> None:
    if not ASSETS.exists():
        print(f"Missing {ASSETS}. Run: python tools/generate_lingafriq_content.py")
        sys.exit(1)
    BACKEND_PACKS.mkdir(parents=True, exist_ok=True)
    written = 0
    for manifest_path in sorted(ASSETS.glob("*/manifest.json")):
        lang_id = manifest_path.parent.name
        with manifest_path.open(encoding="utf-8") as f:
            wrapper = json.load(f)
        inner = wrapper.get("manifest", wrapper)
        if not isinstance(inner, dict):
            print(f"Skip {manifest_path}: invalid manifest shape")
            continue
        dest = BACKEND_PACKS / f"{lang_id}.json"
        dest.write_text(json.dumps(inner, ensure_ascii=False, indent=2), encoding="utf-8")
        lessons = len(inner.get("lessons", []))
        print(f"Wrote {dest.name} ({lessons} lessons)")
        written += 1
    if written == 0:
        print("No manifests exported.")
        sys.exit(1)
    print(f"Exported {written} content packs -> {BACKEND_PACKS}")


if __name__ == "__main__":
    main()
