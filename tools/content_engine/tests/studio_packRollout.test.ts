// charter: v2
// Spec tests for staged pack rollout and rollback (P4-077). Mode A.

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
  rolloutPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "packRollout.tsx"),
  rolloutApi: path.join(BACKEND_SRC, "routes", "packRollout.routes.ts"),
  packsApi: path.join(BACKEND_SRC, "routes", "contentPacks.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

const FIXTURE_KEY = "fixture-pack-signing-key";
const FIXTURE_ITEM = "fixture-rollout-item";

const VALID_PAYLOAD = {
  id: "yo.lex.rolloutfixture",
  lang: "yo",
  type: "lexeme",
  cefr: "A1",
  can_do: ["greet someone"],
  text: "Hello.",
  provenance: { sources: [{ source_id: "src-1", licence: "CC BY 4.0" }] },
  claims: [],
  confidence: 0.5,
  risk_tags: [],
  status: "needs-review",
  label: "beta",
  audio: [],
  feature_hooks: {},
};

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

function seedPack(
  api: Record<string, unknown>,
  version: string,
  options?: { reset?: boolean },
): void {
  const resetContentPacksStore = api.resetContentPacksStore as () => void;
  const setPlaceholderLintRunner = api.setPlaceholderLintRunner as (runner: () => { ok: boolean }) => void;
  const upsertPackCandidate = api.upsertPackCandidate as (record: object) => void;
  const buildPackFromStore = api.buildPackFromStore as (
    v: string,
    ids?: string[],
    key?: string,
  ) => { ok: boolean };

  if (options?.reset !== false) {
    resetContentPacksStore();
    setPlaceholderLintRunner(() => ({ ok: true }));
    upsertPackCandidate({
      item_id: FIXTURE_ITEM,
      quality_label: "Reviewed",
      payload: VALID_PAYLOAD,
      published_at: "2026-10-25T00:00:00.000Z",
    });
  }
  const built = buildPackFromStore(version, undefined, FIXTURE_KEY);
  assert.equal(built.ok, true);
}

function promoteRolloutToLive(rolloutApi: Record<string, unknown>): void {
  const advancePackRollout = rolloutApi.advancePackRollout as () => { ok: boolean };
  const stages = rolloutApi.PACK_ROLLOUT_STAGE_PERCENTAGES as number[];
  for (let i = 0; i < stages.length; i += 1) {
    const step = advancePackRollout();
    assert.equal(step.ok, true);
  }
}

test("test_P4_077_AC1_staged_release_uses_config_percentages", async () => {
  const packsApi = await loadReal(REAL.packsApi);
  const rolloutApi = await loadReal(REAL.rolloutApi);
  const resetPackRolloutStore = rolloutApi.resetPackRolloutStore as () => void;
  const releasePackRollout = rolloutApi.releasePackRollout as (v: string) => { ok: boolean; data?: { state: { rollout_percent: number } } };
  const advancePackRollout = rolloutApi.advancePackRollout as () => { ok: boolean; data?: { state: { rollout_percent: number } } };
  const stages = rolloutApi.PACK_ROLLOUT_STAGE_PERCENTAGES as number[];

  resetPackRolloutStore();
  seedPack(packsApi, "1.0.0");
  const released = releasePackRollout("1.0.0");
  assert.equal(released.ok, true);
  assert.equal(released.data?.state.rollout_percent, stages[0]);

  const advanced = advancePackRollout();
  assert.equal(advanced.ok, true);
  assert.equal(advanced.data?.state.rollout_percent, stages[1]);
});

test("test_P4_077_AC2_rollback_restores_previous_and_audits", async () => {
  const packsApi = await loadReal(REAL.packsApi);
  const rolloutApi = await loadReal(REAL.rolloutApi);
  const resetPackRolloutStore = rolloutApi.resetPackRolloutStore as () => void;
  const releasePackRollout = rolloutApi.releasePackRollout as (v: string) => { ok: boolean };
  const rollbackPackRollout = rolloutApi.rollbackPackRollout as () => { ok: boolean; data?: { state: { live_version: string | null } } };
  const getPackRolloutState = rolloutApi.getPackRolloutState as () => { audit_log: { action: string }[] };
  const resolveClientPackVersion = rolloutApi.resolveClientPackVersion as (id: string) => string | null;

  resetPackRolloutStore();
  seedPack(packsApi, "1.0.0");
  assert.equal(releasePackRollout("1.0.0").ok, true);
  promoteRolloutToLive(rolloutApi);

  seedPack(packsApi, "1.1.0", { reset: false });
  assert.equal(releasePackRollout("1.1.0").ok, true);

  const rolled = rollbackPackRollout();
  assert.equal(rolled.ok, true);
  assert.equal(rolled.data?.state.live_version, "1.0.0");
  assert.equal(resolveClientPackVersion("user-a"), "1.0.0");
  const audit = getPackRolloutState().audit_log;
  assert.ok(audit.some((row) => row.action === "rollback"));
});

test("test_P4_077_AC3_rollback_failure_paused_and_error", async () => {
  const packsApi = await loadReal(REAL.packsApi);
  const rolloutApi = await loadReal(REAL.rolloutApi);
  const resetPackRolloutStore = rolloutApi.resetPackRolloutStore as () => void;
  const setPackRolloutRollbackFailure = rolloutApi.setPackRolloutRollbackFailure as (v: boolean) => void;
  const releasePackRollout = rolloutApi.releasePackRollout as (v: string) => { ok: boolean };
  const rollbackPackRollout = rolloutApi.rollbackPackRollout as () => { ok: boolean; code?: string };
  const getPackRolloutState = rolloutApi.getPackRolloutState as () => { paused: boolean; last_error: string | null };

  resetPackRolloutStore();
  seedPack(packsApi, "2.0.0");
  assert.equal(releasePackRollout("2.0.0").ok, true);
  setPackRolloutRollbackFailure(true);
  const failed = rollbackPackRollout();
  assert.equal(failed.ok, false);
  assert.equal(failed.code, "ROLLBACK_FAILED");
  const state = getPackRolloutState();
  assert.equal(state.paused, true);
  assert.equal(state.last_error, "ROLLBACK_FAILED");
});

test("test_P4_077_admin_surface_and_router_exports", async () => {
  const page = await loadReal(REAL.rolloutPage);
  const surface = (page.packRolloutSurface as (input: object) => { state: string })(
    { loading: false, error: null, rollout: { live_version: null, rolling_version: null, stage_index: -1, rollout_percent: 0, paused: false, last_error: null, stages: [1, 10, 50, 100] } },
  );
  assert.equal(surface.state, "ready");
  const src = await readFile(REAL.rolloutPage, "utf8");
  assert.ok(src.includes("rollout.title"));
  assert.ok(src.includes("aria-live"));
  assert.ok(src.includes("rollout.rollback"));

  const api = await loadReal(REAL.rolloutApi);
  const auth = await loadReal(REAL.studioAuth);
  const studioAuth = (auth.studioAuth ?? auth.default) as unknown;
  const router = api.packRolloutRouter ?? api.default;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (router as { handle?: unknown }).handle, "function");
});
