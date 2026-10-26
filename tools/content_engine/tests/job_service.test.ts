// charter: v2
// Spec tests for content engine job service (P4-070). Mode A.

import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { test } from "node:test";

const LINGAFRIQ = path.resolve(import.meta.dirname, "../../../..");
const BACKEND_DIST = path.join(LINGAFRIQ, "node-backend", "dist");

const REAL = {
  routes: path.join(BACKEND_DIST, "routes", "contentJobs.routes.js"),
  service: path.join(BACKEND_DIST, "services", "contentEngineJob.service.js"),
  worker: path.join(BACKEND_DIST, "workers", "contentEngine.worker.js"),
  studioAuth: path.join(BACKEND_DIST, "middleware", "studioAuth.js"),
};

async function loadReal(file: string): Promise<Record<string, unknown>> {
  return import(pathToFileURL(file).href) as Promise<Record<string, unknown>>;
}

test("test_P4_070_AC1_persisted_job_survives_restart", async () => {
  const service = await loadReal(REAL.service);
  const FileContentJobStore = service.FileContentJobStore as new (p: string) => {
    save: (job: object) => Promise<void>;
    get: (id: string) => Promise<object | null>;
  };
  const enqueueContentPipelineJob = service.enqueueContentPipelineJob as (
    input: object,
    store: object,
  ) => Promise<{ ok: boolean; data?: { job_id: string } }>;
  const resumePersistedJobs = service.resumePersistedJobs as (store: object) => Promise<number>;
  const runContentPipelineJob = service.runContentPipelineJob as (
    id: string,
    runner: object,
    store: object,
  ) => Promise<{ ok: boolean; data?: { status: string } }>;
  const noopPipelineStageRunner = service.noopPipelineStageRunner as object;

  const dir = await mkdtemp(path.join(os.tmpdir(), "p4-070-jobs-"));
  const storePath = path.join(dir, "jobs.json");
  const store = new FileContentJobStore(storePath);

  const created = await enqueueContentPipelineJob(
    { item_id: "fixture-item-1", language: "yo" },
    store,
  );
  assert.equal(created.ok, true);
  const jobId = created.data?.job_id ?? "";

  const store2 = new FileContentJobStore(storePath);
  const reloaded = await store2.get(jobId);
  assert.ok(reloaded);
  assert.equal((reloaded as { status: string }).status, "queued");

  await resumePersistedJobs(store2);
  const finished = await runContentPipelineJob(jobId, noopPipelineStageRunner, store2);
  assert.equal(finished.ok, true);
  assert.equal(finished.data?.status, "succeeded");

  await rm(dir, { recursive: true, force: true });
});

test("test_P4_070_AC2_stage_failure_records_error_not_success", async () => {
  const service = await loadReal(REAL.service);
  const MemoryContentJobStore = service.MemoryContentJobStore as new () => {
    clear: () => void;
  };
  const enqueueContentPipelineJob = service.enqueueContentPipelineJob as (
    input: object,
    store: object,
  ) => Promise<{ ok: boolean; data?: { job_id: string } }>;
  const runContentPipelineJob = service.runContentPipelineJob as (
    id: string,
    runner: object,
    store: object,
  ) => Promise<{
    ok: boolean;
    data?: { status: string; stages: { stage: string; status: string; error?: { code: string } }[] };
  }>;
  const noopPipelineStageRunner = service.noopPipelineStageRunner as object;
  const jobSucceeded = service.jobSucceeded as (job: { status: string }) => boolean;

  const store = new MemoryContentJobStore();
  const created = await enqueueContentPipelineJob(
    {
      item_id: "fixture-item-2",
      language: "ig",
      payload: { __test_fail_stage: "score" },
    },
    store,
  );
  const jobId = created.data?.job_id ?? "";
  const result = await runContentPipelineJob(jobId, noopPipelineStageRunner, store);
  assert.equal(result.data?.status, "failed");
  const score = result.data?.stages.find((row) => row.stage === "score");
  assert.equal(score?.status, "failed");
  assert.equal(score?.error?.code, "STAGE_FIXTURE_FAIL");
  assert.equal(jobSucceeded({ status: result.data?.status ?? "" }), false);
});

test("test_P4_070_AC3_concurrency_cap_queues_extra_jobs", async () => {
  const service = await loadReal(REAL.service);
  const MemoryContentJobStore = service.MemoryContentJobStore as new () => object;
  const enqueueContentPipelineJob = service.enqueueContentPipelineJob as (
    input: object,
    store: object,
  ) => Promise<{ ok: boolean; data?: { job_id: string; status: string } }>;
  const pickNextQueuedJob = service.pickNextQueuedJob as (
    store: object,
    cap: number,
  ) => Promise<{ job_id: string } | null>;
  const runContentPipelineJob = service.runContentPipelineJob as (
    id: string,
    runner: object,
    store: object,
  ) => Promise<unknown>;

  const prev = process.env.CONTENT_ENGINE_JOB_CONCURRENCY;
  process.env.CONTENT_ENGINE_JOB_CONCURRENCY = "1";
  const store = new MemoryContentJobStore();
  const noopPipelineStageRunner = service.noopPipelineStageRunner as object;

  const first = await enqueueContentPipelineJob({ item_id: "a", language: "ha" }, store);
  const second = await enqueueContentPipelineJob({ item_id: "b", language: "ha" }, store);
  assert.equal(first.data?.status, "queued");
  assert.equal(second.data?.status, "queued");

  const next1 = await pickNextQueuedJob(store, 1);
  assert.equal(next1?.job_id, first.data?.job_id);
  await runContentPipelineJob(next1!.job_id, noopPipelineStageRunner, store);

  const next2 = await pickNextQueuedJob(store, 1);
  assert.equal(next2?.job_id, second.data?.job_id);

  process.env.CONTENT_ENGINE_JOB_CONCURRENCY = prev;
});

test("test_P4_070_security_studio_auth_on_routes", async () => {
  const api = await loadReal(REAL.routes);
  const contentJobsRouter = api.contentJobsRouter ?? api.default;
  const auth = await loadReal(REAL.studioAuth);
  const studioAuth = (auth.studioAuth ?? auth.default) as (
    req: object,
    res: { status: (n: number) => { json: (b: object) => void } },
    next: () => void,
  ) => void;
  assert.equal(typeof studioAuth, "function");
  assert.equal(typeof (contentJobsRouter as { handle?: unknown }).handle, "function");

  let status = 0;
  studioAuth(
    { user: { role: "staff" } },
    {
      status: (code: number) => {
        status = code;
        return { json: () => undefined };
      },
    },
    () => {
      status = 200;
    },
  );
  assert.equal(status, 403);
});

test("test_P4_070_worker_resumes_interrupted_running_job", async () => {
  const service = await loadReal(REAL.service);
  const worker = await loadReal(REAL.worker);
  const MemoryContentJobStore = service.MemoryContentJobStore as new () => {
    save: (job: object) => Promise<void>;
    list: () => Promise<object[]>;
  };
  const createContentJobRecord = service.createContentJobRecord as (input: object) => {
    job_id: string;
    status: string;
    stages: { stage: string; status: string }[];
  };
  const resumePersistedJobs = service.resumePersistedJobs as (store: object) => Promise<number>;
  const setContentJobStore = service.setContentJobStore as (store: object) => void;
  const runContentEngineWorkerOnce = worker.runContentEngineWorkerOnce as (
    runner: object,
  ) => Promise<number>;

  const store = new MemoryContentJobStore();
  setContentJobStore(store);
  const interrupted = createContentJobRecord({ item_id: "c", language: "sw" });
  interrupted.status = "running";
  interrupted.stages[0].status = "running";
  await store.save(interrupted);
  const resumed = await resumePersistedJobs(store);
  assert.equal(resumed, 1);
  const jobs = await store.list();
  const row = jobs.find((j) => (j as { job_id: string }).job_id === interrupted.job_id) as {
    status: string;
  };
  assert.equal(row.status, "queued");

  const noopPipelineStageRunner = service.noopPipelineStageRunner as object;
  const processed = await runContentEngineWorkerOnce(noopPipelineStageRunner);
  assert.ok(processed >= 1);
});
