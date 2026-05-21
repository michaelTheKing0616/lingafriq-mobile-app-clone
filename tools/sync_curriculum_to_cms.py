#!/usr/bin/env python3
"""
Sync authentic curriculum JSON to backend content-pack / lesson CMS shape.

Reads: assets/data/lingafriq_authentic_curriculum_a1_a2_b1.json (or A1-only)
Writes: output/cms_manifests/{language_id}/manifest.json
Optional PUT: --upload with BACKEND_API_URL and BACKEND_API_TOKEN (admin JWT) env vars.

Manifest lessons match offline download expectations:
  { id, title, assets[], lesson: { sections: [Tutorial|Instant Quiz|Word Quiz] } }
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
from pathlib import Path
from typing import Any

try:
    import requests
except ImportError:
    requests = None  # type: ignore

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "data"
OUTPUT = ROOT / "output" / "cms_manifests"

# Backend language_id mapping (string keys used by /api/v2/content-packs/:language/manifest)
LANGUAGE_IDS: dict[str, str] = {
    "yoruba": "1",
    "hausa": "2",
    "igbo": "3",
    "swahili": "4",
    "zulu": "5",
    "xhosa": "6",
    "wolof": "7",
    "nigerian_pidgin": "8",
    "pidgin": "8",
    "afrikaans": "9",
    "amharic": "10",
    "twi": "11",
    "somali": "12",
    "lingala": "13",
    "shona": "14",
}

CDN_BASE = os.getenv("LINGAFRIQ_CDN_BASE", "https://cdn.lingafriq.com/audio/v2")


def _sha256_placeholder(content: str) -> str:
    return hashlib.sha256(content.encode("utf-8")).hexdigest()


def _audio_assets(lang: str, lesson_id: str, vocab: list[dict]) -> list[dict]:
    assets = []
    for v in vocab[:6]:
        word = v.get("word", "")
        if not word:
            continue
        slug = hashlib.sha256(f"{lang}:{word}".encode()).hexdigest()[:16]
        for kind, suffix in (("audio", "native"), ("audio", "slow")):
            url = f"{CDN_BASE}/{lang}/{suffix}/{slug}.mp3"
            assets.append({
                "kind": "audio",
                "variant": suffix,
                "url": url,
                "sha256": _sha256_placeholder(url),
                "label": word,
            })
    return assets


def _lesson_sections(lesson: dict) -> list[dict]:
    sections = []
    dialogue = lesson.get("dialogue", {})
    script = dialogue.get("script", [])
    tutorial_text = "\n".join(
        f"{line.get('speaker', '?')}: {line.get('text', '')} — {line.get('translation', '')}"
        for line in script
    )
    vocab_lines = "\n".join(
        f"• {v.get('word', '')} — {v.get('meaning', '')}" for v in lesson.get("vocab", [])
    )
    sections.append({
        "id": 1,
        "title": lesson.get("title", "Lesson"),
        "type": "Tutorial",
        "text": f"{lesson.get('objective', '')}\n\n{vocab_lines}\n\n{dialogue.get('scene', '')}\n\n{tutorial_text}",
        "score": 0,
    })
    quiz_items = []
    for ex in lesson.get("exercises", []):
        if ex.get("type") == "flashcards":
            for item in ex.get("items", [])[:3]:
                quiz_items.append({
                    "question": f"Recall: {item}",
                    "options": [item, "Not this phrase", "Different meaning", "Another phrase"],
                    "answer": item,
                })
    unit_quiz = lesson.get("_unit_quiz_items")
    if unit_quiz:
        quiz_items.extend(unit_quiz)
    if quiz_items:
        sections.append({
            "id": 2,
            "title": "Practice Quiz",
            "type": "Instant Quiz",
            "questions": quiz_items[:5],
            "score": 0,
        })
    word_q = []
    for v in lesson.get("vocab", [])[:4]:
        word_q.append({
            "word": v.get("word", ""),
            "meaning": v.get("meaning", ""),
            "options": [v.get("meaning", ""), "Different phrase", "Opposite meaning", "Unrelated"],
        })
    if word_q:
        sections.append({
            "id": 3,
            "title": "Word Quiz",
            "type": "Word Quiz",
            "word_questions": word_q,
            "score": 0,
        })
    return sections


def curriculum_to_manifest(
    curriculum: dict[str, Any],
    language_key: str,
    language_id: str,
    levels: list[str] | None = None,
) -> dict[str, Any]:
    levels = levels or ["A1", "A2", "B1", "B2", "C1"]
    lang_block = curriculum.get("languages", {}).get(language_key, {})
    lessons_out = []
    lang_slug = "pidgin" if language_key in ("nigerian_pidgin", "pidgin") else language_key

    for level in levels:
        units = lang_block.get(level, [])
        if not isinstance(units, list):
            continue
        for unit in units:
            unit_quiz_items = unit.get("unit_quiz", {}).get("items", [])
            for lesson in unit.get("lessons", []):
                lesson_copy = dict(lesson)
                lesson_copy["_unit_quiz_items"] = unit_quiz_items[:2]
                lid = lesson.get("id", f"{language_key}-{level}-lesson")
                sections = _lesson_sections(lesson_copy)
                vocab = lesson.get("vocab", [])
                lessons_out.append({
                    "id": lid,
                    "title": lesson.get("title", lid),
                    "level": level,
                    "unit": unit.get("unit"),
                    "assets": _audio_assets(lang_slug, lid, vocab),
                    "lesson": {
                        "id": lid,
                        "title": lesson.get("title", lid),
                        "objective": lesson.get("objective", ""),
                        "cultural_notes": lesson.get("cultural_notes", ""),
                        "sections": sections,
                    },
                })

    checksum = _sha256_placeholder(json.dumps(lessons_out, sort_keys=True))
    return {
        "manifest": {
            "language": language_id,
            "language_name": language_key,
            "schemaVersion": 1,
            "checksumSha256": checksum,
            "totalLessons": len(lessons_out),
            "levels": levels,
            "source": "lingafriq_authentic_curriculum",
            "lessons": lessons_out,
        }
    }


def write_manifests(curriculum_path: Path, out_dir: Path) -> list[Path]:
    with curriculum_path.open(encoding="utf-8") as f:
        curriculum = json.load(f)
    written = []
    for lang_key, lang_id in LANGUAGE_IDS.items():
        if lang_key == "pidgin":
            continue  # same as nigerian_pidgin
        manifest = curriculum_to_manifest(curriculum, lang_key, lang_id)
        if manifest["manifest"]["totalLessons"] == 0:
            continue
        dest = out_dir / lang_id / "manifest.json"
        dest.parent.mkdir(parents=True, exist_ok=True)
        with dest.open("w", encoding="utf-8") as f:
            json.dump(manifest, f, ensure_ascii=False, indent=2)
        written.append(dest)
        print(f"Wrote {dest} ({manifest['manifest']['totalLessons']} lessons)")
    return written


def upload_manifest(manifest_path: Path, api_url: str, token: str) -> bool:
    if requests is None:
        print("requests not installed; pip install requests")
        return False
    lang_id = manifest_path.parent.name
    with manifest_path.open(encoding="utf-8") as f:
        body = json.load(f)
    url = f"{api_url.rstrip('/')}/api/v2/content-packs/{lang_id}/manifest"
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    resp = requests.put(url, json=body, headers=headers, timeout=120)
    if resp.status_code in (200, 201, 204):
        print(f"Uploaded {lang_id}: {resp.status_code}")
        return True
    print(f"Upload failed {lang_id}: {resp.status_code} {resp.text[:300]}")
    return False


def main() -> None:
    parser = argparse.ArgumentParser(description="Sync curriculum to CMS manifests")
    parser.add_argument(
        "--input",
        default=str(ASSETS / "lingafriq_authentic_curriculum_a1_c1.json"),
        help="Curriculum JSON path",
    )
    parser.add_argument("--output", default=str(OUTPUT), help="Output directory")
    parser.add_argument("--upload", action="store_true", help="POST manifests to backend")
    parser.add_argument("--dry-run", action="store_true", help="Only write local manifests")
    args = parser.parse_args()

    curriculum_path = Path(args.input)
    if not curriculum_path.exists():
        print(f"Missing {curriculum_path}. Run tools/generate_lingafriq_content.py first.")
        sys.exit(1)

    paths = write_manifests(curriculum_path, Path(args.output))

    if args.upload and not args.dry_run:
        api_url = os.getenv("BACKEND_API_URL", "")
        token = os.getenv("BACKEND_API_TOKEN", "")
        if not api_url or not token:
            print("Set BACKEND_API_URL and BACKEND_API_TOKEN for --upload")
            sys.exit(1)
        for p in paths:
            upload_manifest(p, api_url, token)


if __name__ == "__main__":
    main()
