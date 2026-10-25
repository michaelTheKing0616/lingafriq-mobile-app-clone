// charter: v2
// Spec tests for semver signed content packs (P4-076). Mode A.

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
  packsPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "contentPacks.tsx"),
  packsApi: path.join(BACKEND_SRC, "routes", "contentPacks.routes.ts"),
  signing: path.join(BACKEND_SRC, "services", "packSigning.service.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

const FIXTURE_KEY = "fixture-pack-signing-key";
const FIXTURE_ITEM = "fixture-pack-item";

const VALID_PAYLOAD = {
  id: "yo.lex.0123456789ab",
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

test("test_P4_076_AC1_build_semver_manifest_and_signature", async () => {
  const signing = await loadReal(REAL.signing);
  const api = await loadReal(REAL.packsApi);
  const resetContentPacksStore = api.resetContentPacksStore as () => void;
  const setPlaceholderLintRunner = api.setPlaceholderLintRunner as (runner: () => { ok: boolean }) => void;
  const resetPlaceholderLintRunner = api.resetPlaceholderLintRunner as () => void;
  const upsertPackCandidate = api.upsertPackCandidate as (record: object) => void;
  const buildPackFromStore = api.buildPackFromStore as (
    version: string,
    itemIds?: string[],
    signingKey?: string,
  ) => { ok: boolean; data?: { pack: { manifest: object; signature: string } } };

  resetContentPacksStore();
  setPlaceholderLintRunner(() => ({ ok: true }));
  upsertPackCandidate({
    item_id: FIXTURE_ITEM,
    quality_label: "Reviewed",
    payload: VALID_PAYLOAD,
    published_at: "2026-10-25T00:00:00.000Z",
  });

  const built = buildPackFromStore("1.2.3", undefined, FIXTURE_KEY);
  assert.equal(built.ok, true);
  const pack = built.data?.pack as {
    manifest: { version: string; items: { item_id: string; quality_label: string }[] };
    signature: string;
  };
  assert.equal(pack.manifest.version, "1.2.3");
  assert.equal(pack.manifest.items.length, 1);
  assert.equal(pack.manifest.items[0].quality_label, "Reviewed");
  assert.match(pack.signature, /^[a-f0-9]{64}$/);

  const verifyContentPack = signing.verifyContentPack as (
    pack: object,
    key?: string,
  ) => { ok: boolean };
  assert.equal(verifyContentPack(pack, FIXTURE_KEY).ok, true);
  resetPlaceholderLintRunner();
});

test("test_P4_076_AC2_missing_label_or_lint_fails_PACK_ITEM_INVALID", async () => {
  const api = await loadReal(REAL.packsApi);
  const resetContentPacksStore = api.resetContentPacksStore as () => void;
  const setPlaceholderLintRunner = api.setPlaceholderLintRunner as (runner: () => { ok: boolean }) => void;
  const resetPlaceholderLintRunner = api.resetPlaceholderLintRunner as () => void;
  const upsertPackCandidate = api.upsertPackCandidate as (record: object) => void;
  const buildPackFromStore = api.buildPackFromStore as (
    version: string,
  ) => { ok: boolean; code?: string };

  resetContentPacksStore();
  setPlaceholderLintRunner(() => ({ ok: true }));
  upsertPackCandidate({
    item_id: "fixture-no-label",
    quality_label: null,
    payload: VALID_PAYLOAD,
    published_at: null,
  });
  const noLabel = buildPackFromStore("1.0.0");
  assert.equal(noLabel.ok, false);
  assert.equal(noLabel.code, "PACK_ITEM_INVALID");

  resetContentPacksStore();
  setPlaceholderLintRunner(() => ({ ok: false }));
  upsertPackCandidate({
    item_id: FIXTURE_ITEM,
    quality_label: "Beta",
    payload: VALID_PAYLOAD,
    published_at: "2026-10-25T00:00:00.000Z",
  });
  const lintFail = buildPackFromStore("1.0.0");
  assert.equal(lintFail.ok, false);
  assert.equal(lintFail.code, "PACK_ITEM_INVALID");
  resetPlaceholderLintRunner();
});

test("test_P4_076_AC3_tampered_pack_PACK_SIGNATURE_INVALID", async () => {
  const signing = await loadReal(REAL.signing);
  const buildContentPack = signing.buildContentPack as (
    version: string,
    candidates: object[],
    options?: object,
  ) => { ok: boolean; pack?: { signature: string; manifest: object; items: object[] } };
  const verifyContentPack = signing.verifyContentPack as (
    pack: object,
    key?: string,
  ) => { ok: boolean; code?: string };

  const built = buildContentPack(
    "2.0.0",
    [{ item_id: FIXTURE_ITEM, quality_label: "Native-verified", payload: VALID_PAYLOAD }],
    { signingKey: FIXTURE_KEY, validateItem: () => true },
  );
  assert.equal(built.ok, true);
  const tampered = {
    ...built.pack,
    manifest: { ...(built.pack?.manifest as object), version: "2.0.1" },
  };
  const verified = verifyContentPack(tampered, FIXTURE_KEY);
  assert.equal(verified.ok, false);
  assert.equal(verified.code, "PACK_SIGNATURE_INVALID");
});

test("test_P4_076_admin_surface_and_router_exports", async () => {
  const page = await loadReal(REAL.packsPage);
  const surface = (page.contentPacksSurface as (input: object) => { state: string })(
    { loading: false, error: null, candidates: [], pack: null },
  );
  assert.equal(surface.state, "empty");
  const src = await readFile(REAL.packsPage, "utf8");
  assert.ok(src.includes("packs.title"));
  assert.ok(src.includes("aria-live"));

  const api = await loadReal(REAL.packsApi);
  const auth = await loadReal(REAL.studioAuth);
  const studioAuth = (auth.studioAuth ?? auth.default) as unknown;
  const router = api.contentPacksRouter ?? api.default;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (router as { handle?: unknown }).handle, "function");
});
