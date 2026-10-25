// charter: v2
// Spec tests for generation jobs UI (P4-073). Mode A.

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
  jobsPage: path.join(ADMIN_SRC, "pages", "CurriculumStudio", "generationJobs.tsx"),
  jobsApi: path.join(BACKEND_SRC, "routes", "generationJobs.routes.ts"),
  studioAuth: path.join(BACKEND_SRC, "middleware", "studioAuth.ts"),
};

const FIXTURE_COMMIT = "fixture-prompt-commit-abc123";
const FIXTURE_TEMPLATE = "fixture/prompt_template.md";

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

function cleanGitRunner(): (args: string[], cwd: string) => { status: number; stdout: string } {
  return (args) => {
    if (args[0] === "status") {
      return { status: 0, stdout: "" };
    }
    if (args[0] === "rev-parse") {
      return { status: 0, stdout: FIXTURE_COMMIT };
    }
    return { status: 1, stdout: "" };
  };
}

function dirtyGitRunner(): (args: string[], cwd: string) => { status: number; stdout: string } {
  return (args) => {
    if (args[0] === "status") {
      return { status: 0, stdout: " M fixture/prompt_template.md" };
    }
    if (args[0] === "rev-parse") {
      return { status: 0, stdout: FIXTURE_COMMIT };
    }
    return { status: 1, stdout: "" };
  };
}

test("test_P4_073_AC1_job_records_prompt_version_and_models", async () => {
  const api = await loadReal(REAL.jobsApi);
  const resetGenerationJobsStore = api.resetGenerationJobsStore as () => void;
  const createGenerationJob = api.createGenerationJob as (input: object) => {
    ok: boolean;
    data?: {
      prompt_template_git_commit: string;
      models: { generator: string; verifier: string };
      stages: { stage: string; status: string }[];
    };
  };
  resetGenerationJobsStore();

  const priorGen = process.env.CONTENT_ENGINE_GENERATION_MODEL;
  const priorVer = process.env.CONTENT_ENGINE_VERIFICATION_MODEL;
  process.env.CONTENT_ENGINE_GENERATION_MODEL = "fixture-generator-model";
  process.env.CONTENT_ENGINE_VERIFICATION_MODEL = "fixture-verifier-model";

  const created = createGenerationJob({
    target_type: "can_do",
    target_id: "fixture-can-do-1",
    repoRoot: "/fixture/repo",
    templateRelPath: FIXTURE_TEMPLATE,
    git: cleanGitRunner(),
  });
  assert.equal(created.ok, true);
  assert.equal(created.data?.prompt_template_git_commit, FIXTURE_COMMIT);
  assert.equal(created.data?.models.generator, "fixture-generator-model");
  assert.equal(created.data?.models.verifier, "fixture-verifier-model");
  assert.equal(created.data?.stages[0]?.status, "running");

  const page = await loadReal(REAL.jobsPage);
  const surface = (page.generationJobsSurface as (input: object) => { state: string })(
    { loading: false, error: null, job: created.data },
  );
  assert.equal(surface.state, "ready");
  const src = await readFile(REAL.jobsPage, "utf8");
  assert.ok(src.includes("jobs.promptVersion"));
  assert.ok(src.includes("Generation job stages"));

  if (priorGen === undefined) delete process.env.CONTENT_ENGINE_GENERATION_MODEL;
  else process.env.CONTENT_ENGINE_GENERATION_MODEL = priorGen;
  if (priorVer === undefined) delete process.env.CONTENT_ENGINE_VERIFICATION_MODEL;
  else process.env.CONTENT_ENGINE_VERIFICATION_MODEL = priorVer;
});

test("test_P4_073_AC2_uncommitted_prompt_fails_PROMPT_NOT_VERSIONED", async () => {
  const api = await loadReal(REAL.jobsApi);
  const resetGenerationJobsStore = api.resetGenerationJobsStore as () => void;
  const createGenerationJob = api.createGenerationJob as (input: object) => { ok: boolean; code?: string };
  resetGenerationJobsStore();

  process.env.CONTENT_ENGINE_GENERATION_MODEL = "fixture-generator-model";
  process.env.CONTENT_ENGINE_VERIFICATION_MODEL = "fixture-verifier-model";

  const blocked = createGenerationJob({
    target_type: "unit",
    target_id: "fixture-unit-1",
    repoRoot: "/fixture/repo",
    templateRelPath: FIXTURE_TEMPLATE,
    git: dirtyGitRunner(),
  });
  assert.equal(blocked.ok, false);
  assert.equal(blocked.code, "PROMPT_NOT_VERSIONED");
});

test("test_P4_073_AC3_running_job_shows_stage_status_and_typed_error", async () => {
  const api = await loadReal(REAL.jobsApi);
  const resetGenerationJobsStore = api.resetGenerationJobsStore as () => void;
  const createGenerationJob = api.createGenerationJob as (input: object) => { ok: boolean; data?: { job_id: string } };
  const setGenerationJobStage = api.setGenerationJobStage as (
    jobId: string,
    stage: string,
    patch: object,
  ) => { ok: boolean; data?: { stages: { stage: string; status: string; error?: { code: string } }[] } };
  const getGenerationJob = api.getGenerationJob as (id: string) => { ok: boolean; data?: object };
  resetGenerationJobsStore();

  process.env.CONTENT_ENGINE_GENERATION_MODEL = "fixture-generator-model";
  process.env.CONTENT_ENGINE_VERIFICATION_MODEL = "fixture-verifier-model";

  const created = createGenerationJob({
    target_type: "can_do",
    target_id: "fixture-can-do-2",
    repoRoot: "/fixture/repo",
    templateRelPath: FIXTURE_TEMPLATE,
    git: cleanGitRunner(),
  });
  assert.equal(created.ok, true);
  const jobId = created.data?.job_id ?? "";
  const failed = setGenerationJobStage(jobId, "generate", {
    status: "failed",
    error: { code: "CITATION_MISSING", message: "fixture citation required" },
  });
  assert.equal(failed.ok, true);
  const row = failed.data?.stages.find((stage) => stage.stage === "generate");
  assert.equal(row?.status, "failed");
  assert.equal(row?.error?.code, "CITATION_MISSING");

  const view = getGenerationJob(jobId);
  assert.equal(view.ok, true);

  const page = await loadReal(REAL.jobsPage);
  assert.equal(
    (page.stageStatusLabel as (s: { status: string; error?: { code: string } }) => string)({
      status: "failed",
      error: { code: "CITATION_MISSING" },
    }),
    "failed:CITATION_MISSING",
  );
  assert.equal(page.GENERATION_JOBS_API, "https://fixture.invalid/studio/generation-jobs");
});

test("test_P4_073_register_api_contract", async () => {
  const api = await loadReal(REAL.jobsApi);
  const generationJobsRouter = api.generationJobsRouter ?? api.default;
  const auth = await loadReal(REAL.studioAuth);
  const studioAuth = (auth.studioAuth ?? auth.default) as (
    req: object,
    res: object,
    next: (err?: unknown) => void,
  ) => unknown;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (generationJobsRouter as { handle?: unknown }).handle, "function");
});
