// charter: v2
// Spec tests for source library and licence register UI (P4-071). Mode A.

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
  sourceLibraryPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "sourceLibrary.tsx"),
  sourceLibraryApi: path.join(BACKEND_SRC, "routes", "sourceLibrary.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

const VALID_ROW = {
  source_id: "fixture-commercial",
  url: "https://fixture.invalid/src",
  licence: "CC0",
  version_or_date: "2026-10-25",
  display: false,
  evidence: true,
  training: false,
  attribution_text: "Fixture attribution",
  owner_signoff: "fixture-owner",
};

test("test_P4_071_AC1_required_fields_before_save", async () => {
  const api = await loadReal(REAL.sourceLibraryApi);
  const missingSourceFields = api.missingSourceFields as (input: object) => string[];
  const saveSource = api.saveSource as (input: object) => { ok: boolean; field?: string };
  const resetSourceLibraryStore = api.resetSourceLibraryStore as () => void;
  resetSourceLibraryStore();

  const missing = missingSourceFields({});
  assert.ok(missing.includes("source_id"));
  assert.ok(missing.includes("attribution_text"));
  assert.ok(missing.includes("owner_signoff"));
  for (const field of ["display", "evidence", "training"]) {
    assert.ok(missing.includes(field));
  }

  const rejected = saveSource({ ...VALID_ROW, owner_signoff: "   " });
  assert.equal(rejected.ok, false);
  assert.equal((rejected as { field?: string }).field, "owner_signoff");

  const page = await loadReal(REAL.sourceLibraryPage);
  const missingSourceFormFields = page.missingSourceFormFields as (form: object) => string[];
  const canSaveSourceForm = page.canSaveSourceForm as (form: object) => boolean;
  const empty = page.emptySourceForm as () => Record<string, string | boolean>;
  const form = empty();
  assert.ok(missingSourceFormFields(form).length > 0);
  assert.equal(canSaveSourceForm(form), false);

  const src = await readFile(REAL.sourceLibraryPage, "utf8");
  for (const label of ["Source ID", "Attribution text", "Owner sign-off"]) {
    assert.ok(src.includes(label), `labelled control: ${label}`);
  }
});

test("test_P4_071_AC2_excluded_blocks_use", async () => {
  const api = await loadReal(REAL.sourceLibraryApi);
  const saveSource = api.saveSource as (input: object) => { ok: boolean; code?: string };
  const resetSourceLibraryStore = api.resetSourceLibraryStore as () => void;
  resetSourceLibraryStore();

  const blocked = saveSource({
    ...VALID_ROW,
    source_id: "fixture-nc",
    licence: "CC-BY-NC-4.0",
    display: true,
    evidence: false,
    training: false,
  });
  assert.equal(blocked.ok, false);
  assert.equal(blocked.code, "EXCLUDED_USE_BLOCKED");

  const saved = saveSource({
    ...VALID_ROW,
    source_id: "fixture-nc-saved",
    licence: "CC-BY-NC-4.0",
    display: false,
    evidence: false,
    training: false,
  }) as { ok: true; record: { status: string; usesLocked: boolean; display: boolean } };
  assert.equal(saved.ok, true);
  assert.equal(saved.record.status, "excluded");
  assert.equal(saved.record.usesLocked, true);
  assert.equal(saved.record.display, false);

  const page = await loadReal(REAL.sourceLibraryPage);
  const usesLockedForLicence = page.usesLockedForLicence as (licence: string) => boolean;
  const normalizedUses = page.normalizedUses as (form: {
    licence: string;
    display: boolean;
    evidence: boolean;
    training: boolean;
  }) => { display: boolean; evidence: boolean; training: boolean };
  assert.equal(usesLockedForLicence("CC-BY-NC-4.0"), true);
  const uses = normalizedUses({
    licence: "CC-BY-NC-4.0",
    display: true,
    evidence: true,
    training: true,
  });
  assert.deepEqual(uses, { display: false, evidence: false, training: false });
});

test("test_P4_071_AC3_pending_not_selectable", async () => {
  const api = await loadReal(REAL.sourceLibraryApi);
  const saveSource = api.saveSource as (input: object) => {
    ok: boolean;
    record?: { status: string; selectable: boolean; copyKey: string };
  };
  const selectSourceForGeneration = api.selectSourceForGeneration as (id: string) => {
    ok: boolean;
    code?: string;
  };
  const resetSourceLibraryStore = api.resetSourceLibraryStore as () => void;
  resetSourceLibraryStore();

  const pending = saveSource({
    ...VALID_ROW,
    source_id: "fixture-pending",
    owner_signoff: "pending",
  }) as { ok: true; record: { status: string; selectable: boolean; copyKey: string } };
  assert.equal(pending.ok, true);
  assert.equal(pending.record.status, "pending");
  assert.equal(pending.record.selectable, false);
  assert.equal(pending.record.copyKey, "sources.pending");

  const select = selectSourceForGeneration("fixture-pending");
  assert.equal(select.ok, false);
  assert.equal(select.code, "SIGN_OFF_PENDING");

  const page = await loadReal(REAL.sourceLibraryPage);
  const statusCopyKey = page.statusCopyKey as (record: {
    status: string;
    owner_signoff: string;
    usesLocked: boolean;
  }) => string;
  assert.equal(
    statusCopyKey({ status: "pending", owner_signoff: "pending", usesLocked: false }),
    "sources.pending",
  );
});

test("test_P4_071_register_api_contract", async () => {
  const api = await loadReal(REAL.sourceLibraryApi);
  const saveSource = api.saveSource as (input: object) => { ok: boolean };
  const listSources = api.listSources as () => unknown[];
  const resetSourceLibraryStore = api.resetSourceLibraryStore as () => void;
  const sourceLibraryRouter = api.sourceLibraryRouter ?? api.default;
  resetSourceLibraryStore();

  assert.ok(saveSource(VALID_ROW).ok);
  assert.equal(listSources().length, 1);

  const auth = await loadReal(REAL.studioAuth);
  const studioAuth = (auth.studioAuth ?? auth.default) as (
    req: object,
    res: object,
    next: (err?: unknown) => void,
  ) => unknown;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (sourceLibraryRouter as { handle?: unknown }).handle, "function");

  const page = await loadReal(REAL.sourceLibraryPage);
  assert.equal(page.SOURCE_LIBRARY_API, "https://fixture.invalid/studio/sources");
  const surface = (page.sourceListSurface as (input: object) => { state: string })(
    { loading: false, error: null, sources: [] },
  );
  assert.equal(surface.state, "empty");
});
