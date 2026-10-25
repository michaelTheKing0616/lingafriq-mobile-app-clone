// charter: v2
// Spec tests for lexicon editor (P4-072). Mode A.

import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { registerHooks } from "node:module";
import { test } from "node:test";

registerHooks({
  load(url, context, nextLoad) {
    if (url.split("?")[0].endsWith(".css")) {
      return { format: "module", shortCircuit: true, source: "export default {}" };
    }
    const result = nextLoad(url, context);
    const source = typeof result?.source === "string" ? result.source : undefined;
    if (source?.includes("import.meta.env")) {
      return {
        ...result,
        source: `import.meta.env ??= { VITE_API_BASE_URL: "https://fixture.invalid" };\n${source}`,
      };
    }
    return result;
  },
});

const LINGAFRIQ = path.resolve(import.meta.dirname, "../../../..");
const ADMIN_SRC = path.join(LINGAFRIQ, "lingafriq-admin", "src");
const BACKEND_SRC = path.join(LINGAFRIQ, "node-backend", "src");

const REAL = {
  lexiconPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "lexiconEditor.tsx"),
  lexiconApi: path.join(BACKEND_SRC, "routes", "lexiconEditor.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

const FIXTURE_TONE_A = "fixture-tone-a";
const FIXTURE_TONE_B = "fixture-tone-b";
const FIXTURE_IPA = "fixture-ipa";
const FIXTURE_POS = "fixture-pos";
const FIXTURE_NOUN = "fixture-noun-class";
const FIXTURE_PLURAL = "fixture-plural";

function sourceRow(sourceId: string, tone: string) {
  return {
    source_id: sourceId,
    tone_pattern: tone,
    ipa: FIXTURE_IPA,
    pos: FIXTURE_POS,
    noun_class: FIXTURE_NOUN,
    plural: FIXTURE_PLURAL,
  };
}

function fixtureLexeme(
  lexemeId: string,
  sources: ReturnType<typeof sourceRow>[],
  minimalPairs: { pair_id: string; tone_pattern: string }[],
) {
  const tone = sources[0]?.tone_pattern ?? FIXTURE_TONE_A;
  return {
    lexeme_id: lexemeId,
    form: "fixture-form",
    kit_language: "sw",
    tone_pattern: tone,
    ipa: FIXTURE_IPA,
    g2p: { ipa: FIXTURE_IPA },
    sources,
    minimal_pairs: minimalPairs.map((pair) => ({
      ...pair,
      g2p_preview: "",
    })),
    audit_log: [],
  };
}

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

test("test_P4_072_AC1_sources_side_by_side_with_status_and_g2p", async () => {
  const api = await loadReal(REAL.lexiconApi);
  const resetLexiconEditorStore = api.resetLexiconEditorStore as () => void;
  const upsertLexeme = api.upsertLexeme as (record: object) => void;
  const getLexemeView = api.getLexemeView as (id: string) => { ok: boolean; data?: object };
  resetLexiconEditorStore();

  upsertLexeme(
    fixtureLexeme(
      "fixture-anchored",
      [sourceRow("fixture-source-a", FIXTURE_TONE_A), sourceRow("fixture-source-b", FIXTURE_TONE_A)],
      [{ pair_id: "pair-a", tone_pattern: FIXTURE_TONE_A }],
    ),
  );
  upsertLexeme(fixtureLexeme("fixture-single", [sourceRow("fixture-source-a", FIXTURE_TONE_A)], []));

  const anchored = getLexemeView("fixture-anchored") as {
    ok: true;
    data: { status: string; g2p_preview: string; sources: unknown[] };
  };
  assert.equal(anchored.ok, true);
  assert.equal(anchored.data.status, "anchored");
  assert.equal(anchored.data.sources.length, 2);
  assert.ok(anchored.data.g2p_preview.includes(FIXTURE_IPA));

  const single = getLexemeView("fixture-single") as { ok: true; data: { status: string } };
  assert.equal(single.data.status, "single-source");

  const page = await loadReal(REAL.lexiconPage);
  const surface = (page.lexiconEditorSurface as (input: object) => { state: string })(
    { loading: false, error: null, lexeme: anchored.data },
  );
  assert.equal(surface.state, "ready");
  const src = await readFile(REAL.lexiconPage, "utf8");
  assert.ok(src.includes("Lexicon sources side by side"));
  assert.ok(src.includes("Tone pattern"));
  assert.ok(src.includes("G2P preview"));
});

test("test_P4_072_AC2_tone_save_updates_preview_pairs_and_audit", async () => {
  const api = await loadReal(REAL.lexiconApi);
  const resetLexiconEditorStore = api.resetLexiconEditorStore as () => void;
  const upsertLexeme = api.upsertLexeme as (record: object) => void;
  const saveLexemeTonePattern = api.saveLexemeTonePattern as (input: object) => {
    ok: boolean;
    data?: { view: { g2p_preview: string; minimal_pairs: { active?: boolean }[] }; audit: object };
  };
  const listLexemeAudit = api.listLexemeAudit as (id: string) => { ok: boolean; data?: unknown[] };
  resetLexiconEditorStore();

  const nextTone = "fixture-tone-next";
  upsertLexeme(
    fixtureLexeme(
      "fixture-save",
      [sourceRow("fixture-source-a", FIXTURE_TONE_A)],
      [
        { pair_id: "pair-old", tone_pattern: FIXTURE_TONE_A },
        { pair_id: "pair-new", tone_pattern: nextTone },
      ],
    ),
  );

  const saved = saveLexemeTonePattern({
    lexeme_id: "fixture-save",
    tone_pattern: nextTone,
    editor_id: "fixture-editor",
    kit_language: "sw",
  });
  assert.equal(saved.ok, true);
  assert.ok(saved.data?.view.g2p_preview.includes(nextTone));
  const active = saved.data?.view.minimal_pairs.find((pair) => pair.active === true);
  assert.equal(active?.tone_pattern, nextTone);

  const audit = listLexemeAudit("fixture-save");
  assert.equal(audit.ok, true);
  assert.equal(audit.data?.length, 1);
  assert.equal((audit.data?.[0] as { editor_id: string }).editor_id, "fixture-editor");
});

test("test_P4_072_AC3_kit_lint_blocks_save", async () => {
  const api = await loadReal(REAL.lexiconApi);
  const resetLexiconEditorStore = api.resetLexiconEditorStore as () => void;
  const upsertLexeme = api.upsertLexeme as (record: object) => void;
  const saveLexemeTonePattern = api.saveLexemeTonePattern as (input: object) => {
    ok: boolean;
    code?: string;
  };
  const lintTonePatternForKit = api.lintTonePatternForKit as (
    marking: string,
    tone: string,
  ) => { ok: boolean; code?: string };
  resetLexiconEditorStore();

  const pcmLexeme = fixtureLexeme("fixture-pcm", [sourceRow("fixture-source-a", FIXTURE_TONE_A)], []);
  pcmLexeme.kit_language = "pcm";
  upsertLexeme(pcmLexeme);

  const lint = lintTonePatternForKit("marked only in scientific use", FIXTURE_TONE_B);
  assert.equal(lint.ok, false);
  assert.equal(lint.code, "KIT_TONE_SCIENTIFIC_ONLY");

  const blocked = saveLexemeTonePattern({
    lexeme_id: "fixture-pcm",
    tone_pattern: FIXTURE_TONE_B,
    editor_id: "fixture-editor",
    kit_language: "pcm",
  });
  assert.equal(blocked.ok, false);
  assert.equal(blocked.code, "KIT_TONE_SCIENTIFIC_ONLY");

  const page = await loadReal(REAL.lexiconPage);
  assert.equal(page.LEXICON_EDITOR_API, "https://fixture.invalid/studio/lexicon");
  assert.equal((page.canSaveTonePattern as (t: string, e: string) => boolean)("x", "editor"), true);
});

test("test_P4_072_register_api_contract", async () => {
  const api = await loadReal(REAL.lexiconApi);
  const lexiconEditorRouter = api.lexiconEditorRouter ?? api.default;
  const auth = await loadReal(REAL.studioAuth);
  const studioAuth = (auth.studioAuth ?? auth.default) as (
    req: object,
    res: object,
    next: (err?: unknown) => void,
  ) => unknown;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (lexiconEditorRouter as { handle?: unknown }).handle, "function");
});
