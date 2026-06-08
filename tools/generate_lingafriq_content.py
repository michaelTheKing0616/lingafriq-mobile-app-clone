#!/usr/bin/env python3

"""

Generates LingAfriq authentic content assets from curated source data.

Outputs:

  - assets/data/game_content.json

  - assets/data/lingafriq_authentic_curriculum_a1.json

  - assets/data/lingafriq_authentic_curriculum_a1_c1.json
  - assets/data/lingafriq_authentic_curriculum_a1_a2_b1.json (legacy copy)

  - assets/data/audio_manifest.json

  - Merges launch-language words into assets/data/word_repo_game_seed.json

"""

from __future__ import annotations



import json

import shutil

import sys

from pathlib import Path



ROOT = Path(__file__).resolve().parents[1]

TOOLS = Path(__file__).resolve().parent

sys.path.insert(0, str(TOOLS))



ASSETS = ROOT / "assets" / "data"

CONTENT_WRITING = ROOT / "LingAfriq Content Writing"



from content_data import (  # noqa: E402

    CURRICULUM_LANGUAGES,

    LAUNCH_LANGUAGES,

    build_curriculum_a1,

    build_curriculum_full,

    build_game_content,

    build_word_repo_entries,

)

from content_data.audio_manifest import build_audio_manifest  # noqa: E402





def write_json(path: Path, data: dict | list) -> None:

    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", encoding="utf-8") as f:

        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Wrote {path} ({path.stat().st_size // 1024} KB)")





def merge_word_repo(new_entries: dict[str, list]) -> None:

    repo_path = ASSETS / "word_repo_game_seed.json"

    with repo_path.open(encoding="utf-8") as f:

        repo = json.load(f)

    languages = repo.setdefault("languages", {})

    for lang_key, entries in new_entries.items():

        existing = languages.get(lang_key, [])

        seen = {(e.get("text", "").lower(), e.get("gloss", "").lower()) for e in existing}

        merged = list(existing)

        for entry in entries:

            key = (entry.get("text", "").lower(), entry.get("gloss", "").lower())

            if key not in seen:

                merged.append(entry)

                seen.add(key)

        languages[lang_key] = merged

    langs = list(languages.keys())

    repo["meta"] = {

        **repo.get("meta", {}),

        "languages": len(langs),

        "lingafriq_authentic_merge": True,

        "launch_languages": LAUNCH_LANGUAGES,

        "curriculum_languages": CURRICULUM_LANGUAGES,

    }

    write_json(repo_path, repo)





def copy_content_writing_assets() -> None:

    """Bundle persona missions, Polie snippets, and magazine seed for the Flutter app."""

    pairs = [

        (CONTENT_WRITING / "persona_missions.json", ASSETS / "persona_missions.json"),

        (CONTENT_WRITING / "polie_prompt_snippets.json", ASSETS / "polie_prompt_snippets.json"),

        (CONTENT_WRITING / "magazine_articles_seed.json", ASSETS / "magazine_articles_seed.json"),

        (TOOLS / "content_data" / "review_checklist.json", ASSETS / "review_checklist.json"),

    ]

    for src, dst in pairs:

        if src.exists():

            shutil.copy2(src, dst)

            print(f"Copied {src.name} -> {dst}")


def copy_cms_manifests_to_assets() -> None:

    """Bundle CMS manifests for offline lesson download."""

    import subprocess

    out_dir = ROOT / "output" / "cms_manifests"

    curriculum_path = ASSETS / "lingafriq_authentic_curriculum_a1_c1.json"

    if curriculum_path.exists():

        subprocess.run(

            [

                sys.executable,

                str(TOOLS / "sync_curriculum_to_cms.py"),

                "--input",

                str(curriculum_path),

                "--output",

                str(out_dir),

                "--dry-run",

            ],

            check=True,

            cwd=str(ROOT),

        )

    dest_root = ASSETS / "cms_manifests"

    if out_dir.exists():

        if dest_root.exists():

            shutil.rmtree(dest_root)

        shutil.copytree(out_dir, dest_root)

        print(f"Copied CMS manifests -> {dest_root}")





def main() -> None:

    game_content = build_game_content()

    write_json(ASSETS / "game_content.json", game_content)



    curriculum_a1 = build_curriculum_a1()

    write_json(ASSETS / "lingafriq_authentic_curriculum_a1.json", curriculum_a1)



    curriculum_full = build_curriculum_full()

    write_json(ASSETS / "lingafriq_authentic_curriculum_a1_c1.json", curriculum_full)

    write_json(ASSETS / "lingafriq_authentic_curriculum_a1_c2.json", curriculum_full)

    write_json(ASSETS / "lingafriq_authentic_curriculum_a1_a2_b1.json", curriculum_full)

    write_json(

        CONTENT_WRITING / "generated" / "lingafriq_authentic_curriculum_a1_c1.json",

        curriculum_full,

    )



    audio_manifest = build_audio_manifest(game_content, curriculum_full)

    write_json(ASSETS / "audio_manifest.json", audio_manifest)



    word_entries = build_word_repo_entries()

    merge_word_repo(word_entries)



    copy_content_writing_assets()

    copy_cms_manifests_to_assets()



    summary = {

        "languages": CURRICULUM_LANGUAGES,

        "words": len(game_content.get("words", [])),

        "proverbs": len(game_content.get("proverbs", [])),

        "scenarios": len(game_content.get("scenarios", [])),

        "grammar_drills": len(game_content.get("grammar_drills", [])),

        "liar_liar_rounds": len(game_content.get("liar_liar_rounds", [])),

        "audio_entries": len(audio_manifest.get("entries", [])),

        "curriculum_languages": list(curriculum_full.get("languages", {}).keys()),

    }

    write_json(CONTENT_WRITING / "generated" / "content_manifest.json", summary)

    print("Done.", summary)





if __name__ == "__main__":

    main()

