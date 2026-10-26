#!/usr/bin/env python3
"""Export signed v2 content pack manifests for node-backend-safe-push."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.content_pipeline.migrate_legacy_bundles import (  # noqa: E402
    _V2_PACKS_REL,
    assert_no_legacy_bundle_references,
)

BACKEND_PACKS = ROOT.parent / "node-backend-safe-push" / "data" / "content-packs"
V2_PACKS = ROOT / _V2_PACKS_REL


def main() -> None:
    assert_no_legacy_bundle_references(Path(__file__).read_text(encoding="utf-8"))
    if not V2_PACKS.is_dir():
        print(
            f"Missing {V2_PACKS}. Run: python tools/content_pipeline/migrate_legacy_bundles.py",
            file=sys.stderr,
        )
        sys.exit(1)
    BACKEND_PACKS.mkdir(parents=True, exist_ok=True)
    written = 0
    for manifest_path in sorted(V2_PACKS.glob("*/manifest.json")):
        lang_id = manifest_path.parent.name
        with manifest_path.open(encoding="utf-8") as handle:
            manifest = json.load(handle)
        if manifest.get("format") != "lingafriq.content_pack.v2":
            print(f"Skip {manifest_path}: not a v2 pack manifest")
            continue
        dest = BACKEND_PACKS / f"{lang_id}.json"
        dest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
        object_count = len(manifest.get("objects", []))
        print(f"Wrote {dest.name} ({object_count} objects)")
        written += 1
    if written == 0:
        print("No v2 pack manifests exported.")
        sys.exit(1)
    print(f"Exported {written} v2 content packs -> {BACKEND_PACKS}")


if __name__ == "__main__":
    main()
