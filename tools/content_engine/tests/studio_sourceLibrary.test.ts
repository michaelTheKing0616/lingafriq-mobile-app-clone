// charter: v2
// Source library and licence register UI (P4-071).
// Loads the real admin page and the real backend route.

import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { existsSync, readFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { registerHooks } from "node:module";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { test } from "node:test";

const LINGAFRIQ = path.resolve(import.meta.dirname, "../../../..");
const ADMIN_PAGE = path.join(
  LINGAFRIQ,
  "lingafriq-admin",
  "src",
  "pages",
  "CurriculumStudio",
  "sourceLibrary.tsx",
);
const ROUTE_FILE = path.join(LINGAFRIQ, "node-backend", "src", "routes", "sourceLibrary.routes.ts");
const RBAC_FILE = path.join(LINGAFRIQ, "node-backend", "src", "middleware", "rbac.middleware.ts");
const require = createRequire(pathToFileURL(path.join(LINGAFRIQ, "node-backend", "package.json")).href);
const ts = require("typescript") as {
  transpileModule: (
    source: string,
    options: { compilerOptions: Record<string, number>; fileName: string },
  ) => { outputText: string };
  ModuleKind: { ESNext: number };
  ScriptTarget: { ES2022: number };
  JsxEmit: { ReactJSX: number };
};

registerHooks({
  resolve(specifier, context, nextResolve) {
    const parent = context.parentURL ?? "";
    if (specifier.startsWith(".") && parent.length > 0) {
      const dir = path.dirname(fileURLToPath(parent));
      const base = specifier.endsWith(".js") ? specifier.slice(0, -3) : specifier;
      const candidates = [
        path.resolve(dir, `${base}.ts`),
        path.resolve(dir, `${base}.tsx`),
        path.resolve(dir, base, "index.ts"),
        path.resolve(dir, base, "index.tsx"),
      ];
      const found = candidates.find((candidate) => existsSync(candidate));
      if (found) return nextResolve(pathToFileURL(found).href, context);
    }
    return nextResolve(specifier, context);
  },
  load(url, context, nextLoad) {
    const clean = url.split("?")[0];
    if (clean.endsWith(".css")) {
      return { format: "module", shortCircuit: true, source: "export default {}" };
    }
    if (clean.endsWith(".ts") || clean.endsWith(".tsx")) {
      const source = readFileSync(fileURLToPath(clean), "utf8").replaceAll(
        "import.meta.env",
        "({ VITE_API_BASE_URL: 'https://fixture.invalid' })",
      );
      const javascript = ts.transpileModule(source, {
        compilerOptions: {
          module: ts.ModuleKind.ESNext,
          target: ts.ScriptTarget.ES2022,
          jsx: ts.JsxEmit.ReactJSX,
          inlineSourceMap: true,
          inlineSources: true,
        },
        fileName: clean,
      }).outputText;
      return { format: "module", shortCircuit: true, source: javascript };
    }
    return nextLoad(url, context);
  },
});

type SourceForm = {
  source_id: string;
  url: string;
  licence: string;
  version_or_date: string;
  attribution_text: string;
  owner_signoff: string;
  display: boolean | null;
  evidence: boolean | null;
  training: boolean | null;
};

type SaveResult = {
  ok: boolean;
  status?: number;
  code?: string;
  field?: string;
  record?: { copyKey: string; selectable: boolean; usesLocked: boolean; display: boolean; evidence: boolean; training: boolean; registerSaved: boolean };
};

const adminUser = { id: "507f1f77bcf86cd799439011", role: "content-admin" };

async function primeStudioRoleCache(): Promise<void> {
  const middleware = (await import(pathToFileURL(RBAC_FILE).href)) as {
    bumpStaffRoleCache: (userId: string, next: { userId: string; role: "owner"; languages: string[]; version: number }) => void;
  };
  middleware.bumpStaffRoleCache(adminUser.id, {
    userId: adminUser.id,
    role: "owner",
    languages: [],
    version: 1,
  });
}

function signedSource(overrides: Partial<SourceForm> = {}): SourceForm {
  return {
    source_id: "src-hausa-1",
    url: "https://example.invalid/hausa",
    licence: "CC BY 4.0",
    version_or_date: "2026-10-25",
    attribution_text: "Hausa corpus, Ada",
    owner_signoff: "Ada 2026-10-25",
    display: false,
    evidence: false,
    training: false,
    ...overrides,
  };
}

async function loadPage(): Promise<Record<string, unknown>> {
  return import(pathToFileURL(ADMIN_PAGE).href) as Promise<Record<string, unknown>>;
}

async function loadRoute(): Promise<Record<string, unknown>> {
  return import(pathToFileURL(ROUTE_FILE).href) as Promise<Record<string, unknown>>;
}

function invoke(
  router: { handle: (req: object, res: object, next: (err?: unknown) => void) => void },
  method: string,
  url: string,
  body: unknown,
): Promise<{ status: number; json: Record<string, unknown> }> {
  return new Promise((resolve, reject) => {
    const result = { status: 200, json: {} as Record<string, unknown> };
    const res = {
      status(code: number) {
        result.status = code;
        return this;
      },
      json(payload: Record<string, unknown>) {
        result.json = payload;
        resolve(result);
        return this;
      },
      end() {
        resolve(result);
      },
      setHeader() {
        return this;
      },
    };
    const req = {
      user: adminUser,
      userId: adminUser.id,
      method,
      url,
      originalUrl: url,
      path: url,
      headers: {},
      body,
      params: {},
      query: {},
    };
    try {
      router.handle(req, res, (err?: unknown) => {
        if (err) reject(err);
        else resolve(result);
      });
    } catch (error) {
      reject(error);
    }
  });
}

test("test_P4_071_AC1_required_fields_before_save", async () => {
  await primeStudioRoleCache();
  const route = await loadRoute();
  const saveSource = route.saveSource as (input: SourceForm) => SaveResult;
  const reset = route.resetSourceLibraryStore as () => void;
  const list = route.listSources as () => unknown[];
  const page = await loadPage();
  const assess = page.assessSourceForm as (input: SourceForm) => { ok: boolean; code?: string; field?: string };
  reset();

  const fields = [
    "source_id",
    "url",
    "licence",
    "version_or_date",
    "attribution_text",
    "owner_signoff",
    "display",
    "evidence",
    "training",
  ] as const;
  for (const field of fields) {
    reset();
    const input = signedSource();
    if (field === "display" || field === "evidence" || field === "training") input[field] = null;
    else input[field] = "  ";
    const saved = saveSource(input);
    const form = assess(input);
    assert.equal(saved.ok, false, field);
    assert.equal(saved.code, "LICENCE_FIELD_MISSING");
    assert.equal(saved.field, field);
    assert.equal(form.ok, false);
    assert.equal(form.code, "LICENCE_FIELD_MISSING");
    assert.equal(form.field, field);
    assert.equal(list().length, 0);
  }

  const router = route.default as { handle: (req: object, res: object, next: (err?: unknown) => void) => void };
  const rejected = await invoke(router, "POST", "/sources", signedSource({ url: "" }));
  assert.equal(rejected.status, 400);
  assert.equal(rejected.json.code, "LICENCE_FIELD_MISSING");

  const saved = saveSource(signedSource());
  assert.equal(saved.ok, true);
  assert.equal(saved.record?.registerSaved, true);
  assert.equal(list().length, 1);

  const displayed = saveSource({
    ...signedSource({
      source_id: "src-display",
      display: true,
      evidence: true,
      training: true,
    }),
    counsel_status: "confirmed",
  });
  assert.equal(displayed.ok, true);
  assert.equal(displayed.record?.display, true);
  assert.equal(displayed.record?.registerSaved, true);
});

test("test_P4_071_AC2_excluded_licence_blocks_use", async () => {
  const route = await loadRoute();
  const saveSource = route.saveSource as (input: SourceForm) => SaveResult;
  const reset = route.resetSourceLibraryStore as () => void;
  const list = route.listSources as () => SaveResult["record"][];
  const page = await loadPage();
  const assess = page.assessSourceForm as (input: SourceForm) => {
    ok: boolean;
    code?: string;
    usesLocked?: boolean;
    copyKey?: string;
    selectable?: boolean;
  };
  reset();

  const blocked = signedSource({
    source_id: "src-nc",
    licence: "CC BY-NC 4.0",
    display: true,
    evidence: false,
    training: false,
  });
  const formBlocked = assess(blocked);
  const savedBlocked = saveSource(blocked);
  assert.equal(formBlocked.ok, false);
  assert.equal(formBlocked.code, "EXCLUDED_USE_BLOCKED");
  assert.equal(savedBlocked.ok, false);
  assert.equal(savedBlocked.status, 409);
  assert.equal(savedBlocked.code, "EXCLUDED_USE_BLOCKED");
  assert.equal(list().length, 0);

  const allowed = signedSource({
    source_id: "src-nc",
    licence: "CC BY-NC 4.0",
    display: false,
    evidence: false,
    training: false,
  });
  const formAllowed = assess(allowed);
  const savedAllowed = saveSource(allowed);
  assert.equal(formAllowed.usesLocked, true);
  assert.equal(formAllowed.copyKey, "sources.excluded");
  assert.equal(formAllowed.selectable, false);
  assert.equal(savedAllowed.ok, true);
  assert.equal(savedAllowed.record?.copyKey, "sources.excluded");
  assert.equal(savedAllowed.record?.usesLocked, true);
  assert.equal(savedAllowed.record?.display, false);
  assert.equal(savedAllowed.record?.evidence, false);
  assert.equal(savedAllowed.record?.training, false);
  assert.equal(savedAllowed.record?.selectable, false);
  const select = route.selectSourceForGeneration as (id: string) => SaveResult;
  const blockedSelect = select("src-nc");
  assert.equal(blockedSelect.ok, false);
  assert.equal(blockedSelect.code, "EXCLUDED_USE_BLOCKED");

  const pageSource = await readFile(ADMIN_PAGE, "utf8");
  assert.match(pageSource, /disabled=\{usesLocked\}/);
  assert.match(pageSource, /data-copy=\{SOURCE_COPY\.excluded\}/);
});

test("test_P4_071_AC3_pending_signoff_not_selectable", async () => {
  await primeStudioRoleCache();
  const route = await loadRoute();
  const saveSource = route.saveSource as (input: SourceForm) => SaveResult;
  const select = route.selectSourceForGeneration as (id: string) => SaveResult;
  const reset = route.resetSourceLibraryStore as () => void;
  const page = await loadPage();
  const assess = page.assessSourceForm as (input: SourceForm) => { copyKey?: string; selectable?: boolean };
  const generationSelection = page.generationSelection as (source: {
    selectable: boolean;
    status: string;
  }) => { allowed: boolean; code: string | null };
  const surface = page.sourceLibrarySurface as (input: {
    loadState: "loading" | "ready" | "error";
    count: number;
  }) => { state: string; copyKey: string };
  reset();

  const pending = signedSource({ source_id: "src-pending", owner_signoff: "pending" });
  const form = assess(pending);
  const saved = saveSource(pending);
  assert.equal(form.copyKey, "sources.pending");
  assert.equal(form.selectable, false);
  assert.equal(saved.ok, true);
  assert.equal(saved.record?.copyKey, "sources.pending");
  assert.equal(saved.record?.registerSaved, false);
  assert.equal(saved.record?.selectable, false);

  const selection = generationSelection({ selectable: false, status: "pending" });
  assert.equal(selection.allowed, false);
  assert.equal(selection.code, "SIGN_OFF_PENDING");
  const rejected = select("src-pending");
  assert.equal(rejected.ok, false);
  assert.equal(rejected.status, 409);
  assert.equal(rejected.code, "SIGN_OFF_PENDING");

  const router = route.default as { handle: (req: object, res: object, next: (err?: unknown) => void) => void };
  const listed = await invoke(router, "GET", "/sources", undefined);
  assert.equal(listed.status, 200);
  const sources = listed.json.sources as Array<{ copyKey: string; selectable: boolean }>;
  assert.equal(sources.length, 1);
  assert.equal(sources[0].copyKey, "sources.pending");
  assert.equal(sources[0].selectable, false);

  assert.equal(surface({ loadState: "loading", count: 0 }).state, "loading");
  assert.equal(surface({ loadState: "error", count: 0 }).state, "error");
  assert.equal(surface({ loadState: "ready", count: 0 }).state, "empty");
  assert.equal(surface({ loadState: "ready", count: 1 }).state, "ready");
  assert.equal(surface({ loadState: "ready", count: 0 }).copyKey, "sources.title");

  const selected = await invoke(router, "POST", "/sources/src-pending/select", undefined);
  assert.equal(selected.status, 409);
  assert.equal(selected.json.code, "SIGN_OFF_PENDING");

  const submit = page.submitSourceForm as (
    fetchImpl: (input: string, init?: { method?: string; body?: string }) => Promise<{ ok: boolean; status: number; json: () => Promise<unknown> }>,
    base: string,
    token: string | null,
    form: SourceForm,
  ) => Promise<{ ok: boolean; code?: string }>;
  const missing = await submit(async () => {
    throw new Error("fetch must not run when a field is missing");
  }, "https://fixture.invalid/studio", null, signedSource({ attribution_text: "" }));
  assert.equal(missing.ok, false);
  assert.equal(missing.code, "LICENCE_FIELD_MISSING");

  const choose = page.requestSourceSelection as (
    fetchImpl: (input: string) => Promise<unknown>,
    base: string,
    token: string | null,
    source: { source_id: string; selectable: boolean; status: "pending"; copyKey: "sources.pending"; usesLocked: boolean; licence: string; display: boolean; evidence: boolean; training: boolean },
  ) => Promise<{ ok: boolean; code?: string }>;
  const held = await choose(async () => {
    throw new Error("fetch must not run for a pending source");
  }, "https://fixture.invalid/studio", null, {
    source_id: "src-pending",
    licence: "CC BY 4.0",
    status: "pending",
    copyKey: "sources.pending",
    selectable: false,
    usesLocked: false,
    display: false,
    evidence: false,
    training: false,
  });
  assert.equal(held.ok, false);
  assert.equal(held.code, "SIGN_OFF_PENDING");

  const requireAdmin = createRequire(pathToFileURL(path.join(LINGAFRIQ, "lingafriq-admin", "package.json")).href);
  const React = requireAdmin("react") as { createElement: (type: unknown) => unknown };
  const server = requireAdmin("react-dom/server") as { renderToStaticMarkup: (node: unknown) => string };
  const html = server.renderToStaticMarkup(React.createElement(page.default));
  assert.match(html, /sources\.title/);
  assert.match(html, /for="owner_signoff"/);
  assert.match(html, /sources\.owner_signoff/);
  assert.match(html, /data-state="loading"/);

  const pageSource = await readFile(ADMIN_PAGE, "utf8");
  assert.match(pageSource, /htmlFor=\{field\.id\}/);
  assert.match(pageSource, /:focus-visible/);
  for (const field of page.SOURCE_FIELDS as Array<{ id: string; label: string }>) {
    assert.match(pageSource, new RegExp(field.label.replace(".", "\\.")));
  }
});
