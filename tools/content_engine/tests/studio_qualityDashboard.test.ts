// charter: v2
// Spec tests for quality dashboard (P4-078). Mode A.

import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { registerHooks } from "node:module";
import { test } from "node:test";

registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier.startsWith(".") && specifier.endsWith(".js") && context.parentURL) {
      const parentDir = path.dirname(fileURLToPath(context.parentURL));
      const tsPath = path.join(parentDir, specifier.replace(/\.js$/, ".ts"));
      if (existsSync(tsPath)) {
        return nextResolve(pathToFileURL(tsPath).href, context);
      }
    }
    return nextResolve(specifier, context);
  },
  load(url, context, nextLoad) {
    const pathOnly = url.split("?")[0];
    if (pathOnly.endsWith(".css")) {
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
  dashboardPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "qualityDashboard.tsx"),
  dashboardApi: path.join(BACKEND_SRC, "routes", "qualityDashboard.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

test("test_P4_078_AC1_error_rate_per_language_and_label_with_flags_and_stats", async () => {
  const api = await loadReal(REAL.dashboardApi);
  const resetQualityDashboardStore = api.resetQualityDashboardStore as () => void;
  const upsertSampleReview = api.upsertSampleReview as (record: object) => void;
  const upsertItemStatistic = api.upsertItemStatistic as (record: object) => void;
  const buildQualityDashboard = api.buildQualityDashboard as () => {
    languages: { language: string; labels: { quality_label: string; error_rate: number | null }[] }[];
    flags: { flagged_items: number };
    item_statistics: { tracked_items: number };
  };
  const prevMin = process.env.STUDIO_QUALITY_MIN_SAMPLES;
  process.env.STUDIO_QUALITY_MIN_SAMPLES = "2";

  resetQualityDashboardStore();
  upsertSampleReview({
    review_id: "r1",
    language: "sw",
    quality_label: "Beta",
    is_error: false,
    reviewed_at: "2026-10-01T00:00:00.000Z",
  });
  upsertSampleReview({
    review_id: "r2",
    language: "sw",
    quality_label: "Beta",
    is_error: true,
    reviewed_at: "2026-10-02T00:00:00.000Z",
  });
  upsertItemStatistic({
    item_id: "item-1",
    language: "sw",
    learner_flag_count: 1,
    flagged_for_revision: false,
    p_value: 0.7,
    discrimination: 1.1,
    response_count: 5,
  });

  const view = buildQualityDashboard();
  const sw = view.languages.find((l) => l.language === "sw");
  assert.ok(sw);
  const beta = sw.labels.find((b) => b.quality_label === "Beta");
  assert.ok(beta);
  assert.equal(beta.error_rate, 0.5);
  assert.equal(beta.insufficient_data, false);
  assert.equal(view.flags.flagged_items, 0);
  assert.equal(view.item_statistics.tracked_items, 1);

  if (prevMin === undefined) delete process.env.STUDIO_QUALITY_MIN_SAMPLES;
  else process.env.STUDIO_QUALITY_MIN_SAMPLES = prevMin;
});

test("test_P4_078_AC2_insufficient_data_when_below_minimum", async () => {
  const api = await loadReal(REAL.dashboardApi);
  const resetQualityDashboardStore = api.resetQualityDashboardStore as () => void;
  const upsertSampleReview = api.upsertSampleReview as (record: object) => void;
  const buildQualityDashboard = api.buildQualityDashboard as () => {
    languages: { labels: { insufficient_data: boolean; error_rate: number | null; sample_count: number }[] }[];
  };
  const prevMin = process.env.STUDIO_QUALITY_MIN_SAMPLES;
  process.env.STUDIO_QUALITY_MIN_SAMPLES = "5";

  resetQualityDashboardStore();
  upsertSampleReview({
    review_id: "r-only",
    language: "yo",
    quality_label: "Reviewed",
    is_error: false,
    reviewed_at: "2026-10-03T00:00:00.000Z",
  });

  const bucket = buildQualityDashboard().languages[0].labels.find((b) => b.quality_label === "Reviewed");
  assert.ok(bucket);
  assert.equal(bucket.sample_count, 1);
  assert.equal(bucket.insufficient_data, true);
  assert.equal(bucket.error_rate, null);

  const formatQualityErrorRate = api.formatQualityErrorRate as (b: object) => string;
  assert.equal(formatQualityErrorRate(bucket), "quality.insufficient");

  if (prevMin === undefined) delete process.env.STUDIO_QUALITY_MIN_SAMPLES;
  else process.env.STUDIO_QUALITY_MIN_SAMPLES = prevMin;
});

test("test_P4_078_admin_route_contract_and_a11y", async () => {
  const api = await loadReal(REAL.dashboardApi);
  const auth = await loadReal(REAL.studioAuth);
  const qualityDashboardRouter = api.qualityDashboardRouter ?? api.default;
  const studioAuth = (auth.studioAuth ?? auth.default) as unknown;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (qualityDashboardRouter as { handle?: unknown }).handle, "function");

  const src = await readFile(REAL.dashboardPage, "utf8");
  assert.ok(src.includes("aria-live"));
  assert.ok(src.includes("quality.title"));
  assert.ok(src.includes("quality.insufficient"));
  assert.ok(src.includes("tabIndex={0}"));

  const qualityDashboardSurface = api.qualityDashboardSurface as (input: object) => { state: string };
  assert.equal(qualityDashboardSurface({ loading: false, error: null, dashboard: null }).state, "empty");
  assert.equal(
    qualityDashboardSurface({
      loading: false,
      error: null,
      dashboard: { languages: [{ language: "sw", labels: [] }], min_sample_size: 30, flags: {}, item_statistics: {} },
    }).state,
    "ready",
  );
  assert.ok(src.includes("formatErrorRate"));
});
