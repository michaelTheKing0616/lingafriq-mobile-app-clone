// charter: v2
// Spec tests for reviewer payments export (P4-079). Mode A.

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
  paymentsPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "paymentsExport.tsx"),
  paymentsApi: path.join(BACKEND_SRC, "routes", "paymentsExport.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

test("test_P4_079_AC1_date_range_export_rows_per_reviewer", async () => {
  const api = await loadReal(REAL.paymentsApi);
  const resetPaymentsExportStore = api.resetPaymentsExportStore as () => void;
  const recordReviewerCompletion = api.recordReviewerCompletion as (r: object) => void;
  const buildPaymentsExport = api.buildPaymentsExport as (s: string, e: string) => {
    rows: { reviewer_id: string; items_reviewed: number }[];
  };
  const buildPaymentsExportCsv = api.buildPaymentsExportCsv as (v: object) => string;

  resetPaymentsExportStore();
  recordReviewerCompletion({
    item_id: "item-a",
    reviewer_id: "rev-1",
    reviewed_at: "2026-10-05T12:00:00.000Z",
  });
  recordReviewerCompletion({
    item_id: "item-b",
    reviewer_id: "rev-1",
    reviewed_at: "2026-10-06T12:00:00.000Z",
  });
  recordReviewerCompletion({
    item_id: "item-c",
    reviewer_id: "rev-2",
    reviewed_at: "2026-10-07T12:00:00.000Z",
  });

  const view = buildPaymentsExport("2026-10-01T00:00:00.000Z", "2026-10-31T23:59:59.999Z");
  assert.equal(view.rows.length, 2);
  const rev1 = view.rows.find((r) => r.reviewer_id === "rev-1");
  const rev2 = view.rows.find((r) => r.reviewer_id === "rev-2");
  assert.ok(rev1);
  assert.ok(rev2);
  assert.equal(rev1.items_reviewed, 2);
  assert.equal(rev2.items_reviewed, 1);

  const csv = buildPaymentsExportCsv(view);
  assert.ok(csv.includes("reviewer_id,items_reviewed"));
  assert.ok(csv.includes("rev-1,2"));
});

test("test_P4_079_AC2_double_review_counts_once_for_final_reviewer", async () => {
  const api = await loadReal(REAL.paymentsApi);
  const resetPaymentsExportStore = api.resetPaymentsExportStore as () => void;
  const recordReviewerCompletion = api.recordReviewerCompletion as (r: object) => void;
  const buildPaymentsExport = api.buildPaymentsExport as (s: string, e: string) => {
    rows: { reviewer_id: string; items_reviewed: number }[];
  };
  const PAYMENTS_COUNT_RULE_HEADER = api.PAYMENTS_COUNT_RULE_HEADER as string;

  resetPaymentsExportStore();
  recordReviewerCompletion({
    item_id: "item-dup",
    reviewer_id: "rev-first",
    reviewed_at: "2026-10-08T10:00:00.000Z",
  });
  recordReviewerCompletion({
    item_id: "item-dup",
    reviewer_id: "rev-final",
    reviewed_at: "2026-10-09T10:00:00.000Z",
  });

  const view = buildPaymentsExport("2026-10-01T00:00:00.000Z", "2026-10-31T23:59:59.999Z");
  const first = view.rows.find((r) => r.reviewer_id === "rev-first");
  const final = view.rows.find((r) => r.reviewer_id === "rev-final");
  assert.equal(first, undefined);
  assert.ok(final);
  assert.equal(final.items_reviewed, 1);

  const buildPaymentsExportCsv = api.buildPaymentsExportCsv as (v: object) => string;
  const csv = buildPaymentsExportCsv(view);
  assert.ok(csv.startsWith(PAYMENTS_COUNT_RULE_HEADER));
});

test("test_P4_079_admin_route_contract_and_a11y", async () => {
  const api = await loadReal(REAL.paymentsApi);
  const auth = await loadReal(REAL.studioAuth);
  const paymentsExportRouter = api.paymentsExportRouter ?? api.default;
  const studioAuth = (auth.studioAuth ?? auth.default) as unknown;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (paymentsExportRouter as { handle?: unknown }).handle, "function");

  const src = await readFile(REAL.paymentsPage, "utf8");
  assert.ok(src.includes("aria-live"));
  assert.ok(src.includes("payments.title"));
  assert.ok(src.includes("payments.empty"));
  assert.ok(src.includes("tabIndex={0}"));
  assert.ok(src.includes("Download CSV"));

  const paymentsExportSurface = api.paymentsExportSurface as (input: object) => { state: string };
  assert.equal(paymentsExportSurface({ loading: false, error: null, view: null }).state, "empty");
  assert.equal(
    paymentsExportSurface({
      loading: false,
      error: null,
      view: { start: "a", end: "b", rows: [{ reviewer_id: "r", items_reviewed: 1 }] },
    }).state,
    "ready",
  );
});
