// charter: v2
// Spec tests for keyboard-first review queues (P4-075). Mode A.

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
  reviewPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "reviewQueues.tsx"),
  reviewApi: path.join(BACKEND_SRC, "routes", "reviewQueues.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

const FIXTURE_ITEM = "fixture-review-item";
const FIXTURE_REVIEWER = "fixture-reviewer";

function fixtureQueueItem(partial: {
  queue?: "high_risk" | "sample" | "flagged";
  high_risk_tags?: string[];
  review_required?: boolean;
  approved?: boolean;
}) {
  return {
    item_id: FIXTURE_ITEM,
    queue: partial.queue ?? "sample",
    summary: "fixture-summary",
    high_risk_tags: partial.high_risk_tags ?? [],
    flagged: false,
    review_required: partial.review_required ?? false,
    approved: partial.approved ?? false,
    quality_label: null,
    reviewer_id: null,
    published_at: null,
  };
}

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

test("test_P4_075_AC1_shortcut_map_one_key_per_action", async () => {
  const api = await loadReal(REAL.reviewApi);
  const shortcuts = api.REVIEW_ACTION_SHORTCUTS as Record<string, string>;
  assert.equal(shortcuts.approve, "a");
  assert.equal(shortcuts.fix, "f");
  assert.equal(shortcuts.reject, "r");
  assert.equal(api.resolveShortcutKey("A"), "approve");

  const page = await loadReal(REAL.reviewPage);
  const kb = page.REVIEW_KEYBOARD_SHORTCUTS as Record<string, string>;
  assert.deepEqual(kb, shortcuts);
  assert.equal((page.shortcutForAction as (a: string) => string)("approve"), "a");
  const div = { tagName: "DIV", isContentEditable: false };
  assert.equal(
    (page.actionFromKeyboardEvent as (e: KeyboardEvent) => string | null)(
      { key: "a", metaKey: false, ctrlKey: false, altKey: false, target: div } as KeyboardEvent,
    ),
    "approve",
  );
});

test("test_P4_075_AC2_approve_publishes_with_label_and_reviewer", async () => {
  const api = await loadReal(REAL.reviewApi);
  const resetReviewQueuesStore = api.resetReviewQueuesStore as () => void;
  const upsertReviewQueueItem = api.upsertReviewQueueItem as (record: object) => void;
  const applyReviewAction = api.applyReviewAction as (input: object) => {
    ok: boolean;
    data?: { item: { quality_label: string; reviewer_id: string }; removed: boolean };
  };
  resetReviewQueuesStore();
  upsertReviewQueueItem(fixtureQueueItem({ queue: "sample" }));

  const result = applyReviewAction({
    item_id: FIXTURE_ITEM,
    action: "approve",
    reviewer_id: FIXTURE_REVIEWER,
    quality_label: "Reviewed",
  });
  assert.equal(result.ok, true);
  assert.equal(result.data?.removed, true);
  assert.equal(result.data?.item.quality_label, "Reviewed");
  assert.equal(result.data?.item.reviewer_id, FIXTURE_REVIEWER);
});

test("test_P4_075_AC2_review_required_when_not_approved", async () => {
  const api = await loadReal(REAL.reviewApi);
  const resetReviewQueuesStore = api.resetReviewQueuesStore as () => void;
  const upsertReviewQueueItem = api.upsertReviewQueueItem as (record: object) => void;
  const publishReviewedItem = api.publishReviewedItem as (
    item: object,
    reviewerId: string,
    label: string,
  ) => { ok: boolean; code?: string };
  resetReviewQueuesStore();
  const item = fixtureQueueItem({ review_required: true, approved: false });
  upsertReviewQueueItem(item);

  const blocked = publishReviewedItem(item, FIXTURE_REVIEWER, "Beta");
  assert.equal(blocked.ok, false);
  assert.equal(blocked.code, "REVIEW_REQUIRED");
});

test("test_P4_075_AC3_error_keeps_item_in_queue", async () => {
  const api = await loadReal(REAL.reviewApi);
  const resetReviewQueuesStore = api.resetReviewQueuesStore as () => void;
  const upsertReviewQueueItem = api.upsertReviewQueueItem as (record: object) => void;
  const applyReviewAction = api.applyReviewAction as (input: object) => { ok: boolean };
  const getReviewQueueItem = api.getReviewQueueItem as (id: string) => unknown;
  resetReviewQueuesStore();
  upsertReviewQueueItem(fixtureQueueItem({ queue: "flagged" }));

  const failed = applyReviewAction({
    item_id: FIXTURE_ITEM,
    action: "approve",
    reviewer_id: FIXTURE_REVIEWER,
    simulate_error: true,
  });
  assert.equal(failed.ok, false);
  assert.ok(getReviewQueueItem(FIXTURE_ITEM));

  const page = await loadReal(REAL.reviewPage);
  const surface = (page.reviewQueuesSurface as (input: object) => { state: string })(
    { loading: false, error: null, items: [fixtureQueueItem({})] },
  );
  assert.equal(surface.state, "ready");
  const src = await readFile(REAL.reviewPage, "utf8");
  assert.ok(src.includes("aria-live"));
  assert.ok(src.includes(REVIEW_COPY_TITLE(src)));
});

function REVIEW_COPY_TITLE(src: string): string {
  assert.ok(src.includes("review.title"));
  return "Keyboard-first review queues";
}

test("test_P4_075_queue_api_lists_by_kind", async () => {
  const api = await loadReal(REAL.reviewApi);
  const resetReviewQueuesStore = api.resetReviewQueuesStore as () => void;
  const upsertReviewQueueItem = api.upsertReviewQueueItem as (record: object) => void;
  const listReviewQueueItems = api.listReviewQueueItems as (queue?: string) => { item_id: string }[];
  resetReviewQueuesStore();
  upsertReviewQueueItem(fixtureQueueItem({ queue: "high_risk", high_risk_tags: ["fixture-tag"] }));
  upsertReviewQueueItem({ ...fixtureQueueItem({ queue: "sample" }), item_id: "fixture-other" });

  assert.equal(listReviewQueueItems("high_risk").length, 1);
  assert.equal(listReviewQueueItems().length, 2);

  const auth = await loadReal(REAL.studioAuth);
  const reviewQueuesRouter = api.reviewQueuesRouter ?? api.default;
  const studioAuth = (auth.studioAuth ?? auth.default) as unknown;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (reviewQueuesRouter as { handle?: unknown }).handle, "function");
});
