Polie SuperGames Package (Full Build)
====================================
This package contains production-ready blueprints and scripts for an advanced African-language games suite.
Contents include:
- prompts/: Cursor-ready prompts and generation templates
- src/: enforce_diacritics (enhanced), roleplay generator, MFA orchestration pseudo-code, eval harness
- demos/: full Tone Trainer (HTML+JS), WordMatchAudio.jsx (React), DrumShadow, PhraseSniper
- data/: phrasebooks, generated roleplay JSONL
- infra/: requirements/docker
- jira/: backlog and test cases
- tests/: basic unit tests

How to use:
1) Inspect prompts/ and import into your Cursor agent config.
2) Integrate src/enforce_diacritics.py as a post-process for all generated text.
3) Serve demos/ as static assets or adapt into your frontend app.
4) Run src/generate_targeted_roleplays.py to regenerate roleplays or use the included JSONL.
