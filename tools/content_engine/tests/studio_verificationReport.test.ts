// charter: v2
// Spec tests for per-item verification report (P4-074). Mode A.

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
  reportPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "verificationReport.tsx"),
  reportApi: path.join(BACKEND_SRC, "routes", "verificationReport.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

const FIXTURE_ITEM = "fixture-verification-item";

function fixtureItem(partial: { back_translation?: object | null; features?: object } = {}) {
  return {
    item_id: FIXTURE_ITEM,
    source_tier: "licensed_dictionary_or_pd",
    features: {
      lexicon_coverage: 0.95,
      tone_agreement: 0.9,
      cross_model_naturalness: 0.9,
      backtranslation_similarity: 0.88,
      linter_results: 1.0,
      citation_entailment: 0.9,
      ...partial.features,
    },
    model_opinions: [
      { model_id: "fixture-generator", verdict: "agree", note: "fixture-note-gen" },
      { model_id: "fixture-verifier", verdict: "flag", note: "fixture-note-ver" },
    ],
    back_translation: partial.back_translation === undefined
      ? { text: "fixture-bt-text", similarity: 0.88, status: "pass" as const }
      : partial.back_translation,
    linter_results: [{ linter_id: "fixture-lint", status: "pass" as const, message: "fixture-ok" }],
    citations: [
      {
        claim_id: "fixture-claim-1",
        source_id: "fixture-source-1",
        passage: "fixture-passage-highlight",
        entailment: "pass" as const,
      },
    ],
  };
}

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

test("test_P4_074_AC1_report_shows_opinions_bt_linters_citations_confidence", async () => {
  const api = await loadReal(REAL.reportApi);
  const resetVerificationReportStore = api.resetVerificationReportStore as () => void;
  const upsertVerificationItem = api.upsertVerificationItem as (record: object) => void;
  const getVerificationReport = api.getVerificationReport as (id: string) => {
    ok: boolean;
    data?: {
      model_opinions: { model_id: string }[];
      back_translation: { text: string };
      linter_results: unknown[];
      citations: { passage: string; entailment: string }[];
      confidence: { breakdown: Record<string, unknown>; score: number | null };
    };
  };
  resetVerificationReportStore();
  upsertVerificationItem(fixtureItem());

  const report = getVerificationReport(FIXTURE_ITEM);
  assert.equal(report.ok, true);
  assert.equal(report.data?.model_opinions.length, 2);
  assert.ok(report.data?.back_translation.text.includes("fixture-bt"));
  assert.equal(report.data?.citations[0]?.entailment, "pass");
  assert.ok(report.data?.citations[0]?.passage.includes("fixture-passage"));
  assert.ok(typeof report.data?.confidence.score === "number");
  assert.ok(report.data?.confidence.breakdown.lexicon_coverage);

  const page = await loadReal(REAL.reportPage);
  const surface = (page.verificationReportSurface as (input: object) => { state: string })(
    { loading: false, error: null, report: report.data },
  );
  assert.equal(surface.state, "ready");
  const src = await readFile(REAL.reportPage, "utf8");
  assert.ok(src.includes("Per-item verification report"));
  assert.ok(src.includes("Confidence breakdown"));
});

test("test_P4_074_AC2_missing_stage_shows_unsure_not_pass", async () => {
  const api = await loadReal(REAL.reportApi);
  const resetVerificationReportStore = api.resetVerificationReportStore as () => void;
  const upsertVerificationItem = api.upsertVerificationItem as (record: object) => void;
  const getVerificationReport = api.getVerificationReport as (id: string) => {
    ok: boolean;
    data?: {
      back_translation: null;
      confidence: { score: number | null; breakdown: Record<string, { status: string }> };
    };
  };
  const stageDisplayStatus = api.stageDisplayStatus as (
    present: boolean,
    status: string | null,
  ) => string;
  resetVerificationReportStore();

  assert.equal(stageDisplayStatus(false, "pass"), "unsure");
  assert.equal(stageDisplayStatus(true, null), "unsure");

  upsertVerificationItem({
    item_id: FIXTURE_ITEM,
    source_tier: "licensed_dictionary_or_pd",
    features: { lexicon_coverage: 0.9 },
    model_opinions: [],
    back_translation: null,
    linter_results: [],
    citations: [],
  });
  const report = getVerificationReport(FIXTURE_ITEM);
  assert.equal(report.ok, true);
  assert.equal(report.data?.back_translation, null);
  assert.equal(report.data?.confidence.score, null);
  assert.equal(report.data?.confidence.breakdown.tone_agreement?.status, "unsure");

  const page = await loadReal(REAL.reportPage);
  assert.equal((page.displayStageStatus as (s: string) => string)(null as unknown as string), "report.unsure");
});

test("test_P4_074_AC3_export_contains_only_stored_item", async () => {
  const api = await loadReal(REAL.reportApi);
  const resetVerificationReportStore = api.resetVerificationReportStore as () => void;
  const upsertVerificationItem = api.upsertVerificationItem as (record: object) => void;
  const exportVerificationItem = api.exportVerificationItem as (id: string) => {
    ok: boolean;
    data?: Record<string, unknown>;
  };
  const getVerificationReport = api.getVerificationReport as (id: string) => { ok: boolean; data?: object };
  resetVerificationReportStore();
  upsertVerificationItem(fixtureItem());

  const exported = exportVerificationItem(FIXTURE_ITEM);
  assert.equal(exported.ok, true);
  assert.equal(exported.data?.item_id, FIXTURE_ITEM);
  assert.equal("confidence" in (exported.data ?? {}), false);

  const view = getVerificationReport(FIXTURE_ITEM);
  assert.equal(view.ok, true);
  assert.ok((view.data as { confidence?: unknown }).confidence);
});

test("test_P4_074_register_api_contract", async () => {
  const api = await loadReal(REAL.reportApi);
  const verificationReportRouter = api.verificationReportRouter ?? api.default;
  const auth = await loadReal(REAL.studioAuth);
  const studioAuth = (auth.studioAuth ?? auth.default) as (
    req: object,
    res: object,
    next: (err?: unknown) => void,
  ) => unknown;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (verificationReportRouter as { handle?: unknown }).handle, "function");
  assert.equal((await loadReal(REAL.reportPage)).VERIFICATION_REPORT_API, "https://fixture.invalid/studio/verification");
});
