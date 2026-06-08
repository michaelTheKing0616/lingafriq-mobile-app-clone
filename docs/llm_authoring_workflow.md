# LLM authoring workflow

End-to-end pipeline for curriculum lessons and game content at scale.

## 1. Draft

```bash
cd mobile-app-safe-push-michael

# Curriculum lesson
python -m tools.llm_authoring.curriculum_drafter \
  --lang yoruba --level B1 --unit 2 --lesson 3 \
  --out tools/llm_authoring/drafts

# Game vocab + proverbs
python -m tools.llm_authoring.games_content_drafter \
  --lang yoruba --level A2 --count-vocab 50 --count-proverbs 8 \
  --out tools/llm_authoring/drafts/games
```

Requires `CLAUDE_API_KEY` / `ANTHROPIC_API_KEY`. Game drafter **does not** write placeholder content when keys are missing.

## 2. Automated checks

```bash
python -m tools.llm_authoring.review_checks tools/llm_authoring/drafts/yoruba/B1/yoruba-B1-u2-l3.json --strict
dart run tool/validate_content_schemas.dart
```

CI runs the same checks on authoring PRs (`.github/workflows/llm_authoring.yml`).

## 3. Native review

1. Import draft into Mongo queue: `POST /api/queue` on the reviewer app
2. Reviewer edits JSON, previews TTS, approves
3. Approval writes `review_status: approved` back to the draft file

```bash
cd tools/llm_authoring/native_reviewer_app
cp .env.example .env.local
npm install && npm run dev
```

## 4. Publish

```bash
python tools/llm_authoring/publish_bundle.py \
  --drafts tools/llm_authoring/drafts \
  --bump-game-version 2.1.0

python tools/sync_curriculum_to_cms.py
python tools/export_backend_content_packs.py
```

## 5. Ship

- Bump `ContentSchemaVersions.curriculumBundleVersion` when assets change
- Run full Flutter CI + manual smoke on Authentic Path + Games hub
- Follow `docs/RELEASE_v4_CHECKLIST.md`
