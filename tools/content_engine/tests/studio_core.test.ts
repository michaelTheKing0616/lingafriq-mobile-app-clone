// charter: v2
// Spec tests for Curriculum Studio scaffold (P4-069). Mode A.
// Loads the real sibling modules. A mock of those modules is a fail.

import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { registerHooks } from "node:module";
import path from "node:path";
import { pathToFileURL } from "node:url";
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
  studioPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "index.tsx"),
  studioRoutes: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "routes.tsx"),
  app: path.join(ADMIN_SRC, "App.tsx"),
  studioApi: path.join(BACKEND_SRC, "routes", "studio.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

const EXISTING_APP_PATHS = ["/login", "/*"] as const;

type StudioSurface = {
  state: "loading" | "empty" | "error" | "ready" | "denied";
  copyKey: string;
};

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

function invokeStudioAuth(
  studioAuth: (req: object, res: object, next: (err?: unknown) => void) => unknown,
  user: object,
): Promise<{ status: number; nextCalled: boolean }> {
  return new Promise((resolve, reject) => {
    const result = { status: 200, nextCalled: false };
    const res = {
      status(code: number) {
        result.status = code;
        return this;
      },
      json() {
        resolve({ status: result.status, nextCalled: result.nextCalled });
        return this;
      },
      send() {
        resolve({ status: result.status, nextCalled: result.nextCalled });
        return this;
      },
      end() {
        resolve({ status: result.status, nextCalled: result.nextCalled });
      },
    };
    const next = (err?: unknown) => {
      if (err) {
        const status =
          err && typeof err === "object" && "status" in err
            ? Number((err as { status: number }).status)
            : 500;
        resolve({ status, nextCalled: false });
        return;
      }
      result.nextCalled = true;
      resolve({ status: result.status, nextCalled: true });
    };
    try {
      const req = {
        user,
        method: "GET",
        url: "/",
        originalUrl: "/studio",
        path: "/",
      };
      const pending = studioAuth(req, res, next);
      if (pending && typeof (pending as Promise<unknown>).then === "function") {
        (pending as Promise<unknown>).catch(reject);
      }
    } catch (error) {
      reject(error);
    }
  });
}

function invokeStudioRouter(
  router: { handle: (req: object, res: object, next: (err?: unknown) => void) => void },
  user: object,
): Promise<{ status: number }> {
  return new Promise((resolve, reject) => {
    const result = { status: 200 };
    const res = {
      statusCode: 200,
      status(code: number) {
        result.status = code;
        this.statusCode = code;
        return this;
      },
      json() {
        resolve({ status: result.status });
        return this;
      },
      send() {
        resolve({ status: result.status });
        return this;
      },
      end() {
        resolve({ status: result.status });
      },
      setHeader() {
        return this;
      },
    };
    const req = {
      user,
      method: "GET",
      url: "/",
      originalUrl: "/",
      path: "/",
      headers: {},
      query: {},
      params: {},
    };
    try {
      router.handle(req, res, (err?: unknown) => {
        if (err && typeof err === "object" && "status" in err) {
          resolve({ status: Number((err as { status: number }).status) });
          return;
        }
        if (err) {
          reject(err);
          return;
        }
        resolve({ status: result.status });
      });
    } catch (error) {
      reject(error);
    }
  });
}

test("test_P4_069_AC1_route_group_registered", async () => {
  const routesMod = await loadReal(REAL.studioRoutes);
  const group = routesMod.studioRouteGroup as {
    path?: string;
    children?: unknown[];
  };
  assert.equal(typeof group?.path, "string");
  assert.ok((group.path as string).startsWith("/"));
  assert.match(group.path as string, /studio/i);
  assert.ok(Array.isArray(group.children));
  assert.ok((group.children as unknown[]).length >= 1);
  assert.ok(
    !EXISTING_APP_PATHS.includes(group.path as (typeof EXISTING_APP_PATHS)[number]),
    "Studio must be a new route group",
  );

  const appSrc = await readFile(REAL.app, "utf8");
  for (const existing of EXISTING_APP_PATHS) {
    assert.ok(appSrc.includes(existing), `existing admin path ${existing} must stay`);
  }
  const studioMounted =
    appSrc.includes("studioRouteGroup") &&
    (appSrc.includes(`studioRouteGroup.path`) ||
      appSrc.includes(group.path as string) ||
      appSrc.includes(`${group.path}/*`));
  assert.ok(studioMounted, "App must mount the Curriculum Studio route group");
});

test("test_P4_069_AC2_denied_without_content_admin", async () => {
  const authMod = await loadReal(REAL.studioAuth);
  const studioAuth = (authMod.studioAuth ?? authMod.default) as (
    req: object,
    res: object,
    next: (err?: unknown) => void,
  ) => unknown;
  assert.equal(typeof studioAuth, "function");

  const denied = await invokeStudioAuth(studioAuth, {
    role: "staff",
    roles: ["staff"],
  });
  assert.equal(denied.status, 403);
  assert.equal(denied.nextCalled, false);

  const apiMod = await loadReal(REAL.studioApi);
  const router = (apiMod.default ?? apiMod.studioRouter) as {
    handle: (req: object, res: object, next: (err?: unknown) => void) => void;
  };
  assert.equal(typeof router?.handle, "function");
  const routed = await invokeStudioRouter(router, {
    role: "staff",
    roles: ["staff"],
  });
  assert.equal(routed.status, 403);

  const pageMod = await loadReal(REAL.studioPage);
  const studioSurface = pageMod.studioSurface as (input: {
    role: string;
    serviceStatus: "ok" | "unreachable" | "loading";
  }) => StudioSurface;
  const surface = studioSurface({ role: "staff", serviceStatus: "ok" });
  assert.equal(surface.state, "denied");
  assert.equal(surface.copyKey, "studio.denied");
});

test("test_P4_069_AC3_unreachable_service_error_state", async () => {
  const pageMod = await loadReal(REAL.studioPage);
  assert.equal(typeof pageMod.STUDIO_API_BASE, "string");
  assert.ok((pageMod.STUDIO_API_BASE as string).length > 0);

  // Labelled fixture only — job service is P4-070; this card needs an unreachable error state.
  const fixture = { label: "fixture", serviceStatus: "unreachable" as const };
  const studioSurface = pageMod.studioSurface as (input: {
    role: string;
    serviceStatus: "ok" | "unreachable" | "loading";
  }) => StudioSurface;
  const surface = studioSurface({
    role: "content-admin",
    serviceStatus: fixture.serviceStatus,
  });
  assert.equal(surface.state, "error");
  assert.equal(surface.copyKey, "studio.error");
});
