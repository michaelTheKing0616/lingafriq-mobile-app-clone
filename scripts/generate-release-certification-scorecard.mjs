import fs from "node:fs";
import path from "node:path";

const DEFAULT_WS_GATES_PATH = "release-gates/ws1-ws12-gates.json";
const DEFAULT_CRITICAL_JOURNEYS_PATH = "release-gates/mobile-critical-journey-checklist.json";
const DEFAULT_DEVICE_MATRIX_PATH = "release-gates/mobile-device-matrix-checklist.json";
const DEFAULT_OUTPUT_PATH = "release-gates/release-certification-scorecard.json";
const ALLOWED_STATUSES = new Set(["pass", "pending", "fail"]);
const FAIL_STATUSES = new Set(["fail", "failed", "blocked"]);

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function fail(message) {
  console.error(`\n[mobile-scorecard] ${message}`);
  process.exit(1);
}

function readJson(inputPath, label) {
  const resolvedPath = path.resolve(process.cwd(), inputPath);
  if (!fs.existsSync(resolvedPath)) {
    fail(`${label} file not found: ${resolvedPath}`);
  }

  try {
    return JSON.parse(fs.readFileSync(resolvedPath, "utf8"));
  } catch (error) {
    fail(`${label} is not valid JSON: ${error.message}`);
  }
}

function bucketStatus(status, bucket) {
  const normalizedStatus = String(status || "").trim().toLowerCase();
  const mappedStatus =
    normalizedStatus === "enabled" ? "pass" : normalizedStatus === "planned" ? "pending" : normalizedStatus;
  if (!ALLOWED_STATUSES.has(mappedStatus)) {
    bucket.invalid += 1;
    return;
  }
  if (mappedStatus === "pass") {
    bucket.pass += 1;
  } else if (mappedStatus === "pending") {
    bucket.pending += 1;
  } else if (FAIL_STATUSES.has(mappedStatus)) {
    bucket.fail += 1;
  }
}

function createCounter() {
  return { pass: 0, pending: 0, fail: 0, invalid: 0, total: 0 };
}

function finalizeCounter(counter) {
  counter.total = counter.pass + counter.pending + counter.fail + counter.invalid;
  return counter;
}

const wsGatesPath = process.argv[2] || DEFAULT_WS_GATES_PATH;
const criticalJourneysPath = process.argv[3] || DEFAULT_CRITICAL_JOURNEYS_PATH;
const deviceMatrixPath = process.argv[4] || DEFAULT_DEVICE_MATRIX_PATH;
const outputPath = process.argv[5] || DEFAULT_OUTPUT_PATH;

const wsGates = readJson(wsGatesPath, "WS gates");
const criticalJourneys = readJson(criticalJourneysPath, "Critical journeys");
const deviceMatrix = readJson(deviceMatrixPath, "Device matrix");

const wsSummary = createCounter();
for (const gateConfig of Object.values(wsGates?.gates || {})) {
  bucketStatus(gateConfig?.status, wsSummary);
}
finalizeCounter(wsSummary);

const journeySummary = createCounter();
for (const journeyConfig of Object.values(criticalJourneys?.criticalJourneys || {})) {
  const perfBudgets = journeyConfig?.performanceBudgets || {};
  for (const budgetConfig of Object.values(perfBudgets)) {
    bucketStatus(budgetConfig?.status, journeySummary);
  }
  bucketStatus(journeyConfig?.offlineReadiness?.status, journeySummary);
  bucketStatus(journeyConfig?.errorStateReadiness?.status, journeySummary);
}
finalizeCounter(journeySummary);

const deviceSummary = createCounter();
for (const deviceConfig of Object.values(deviceMatrix?.devices || {})) {
  bucketStatus(deviceConfig?.status, deviceSummary);
  for (const testConfig of Object.values(deviceConfig?.tests || {})) {
    bucketStatus(testConfig?.status, deviceSummary);
  }
}
finalizeCounter(deviceSummary);

const allCounters = [wsSummary, journeySummary, deviceSummary];
const totals = allCounters.reduce(
  (acc, counter) => {
    acc.pass += counter.pass;
    acc.pending += counter.pending;
    acc.fail += counter.fail;
    acc.invalid += counter.invalid;
    acc.total += counter.total;
    return acc;
  },
  { pass: 0, pending: 0, fail: 0, invalid: 0, total: 0 },
);

const readinessScorePercent = totals.total > 0 ? Math.round((totals.pass / totals.total) * 100) : 0;
const overallStatus = totals.fail > 0 || totals.invalid > 0 ? "fail" : "pending";

const scorecard = {
  scorecardName: "mobile-release-certification",
  schemaVersion: 1,
  releaseTrain: wsGates?.releaseTrain || "WS1-WS12",
  overallStatus,
  readinessScorePercent,
  statusCounts: totals,
  sections: {
    wsGates: wsSummary,
    criticalJourneys: journeySummary,
    deviceMatrix: deviceSummary,
  },
  sourceArtifacts: {
    wsGatesPath,
    criticalJourneysPath,
    deviceMatrixPath,
  },
  scoringPolicy: {
    scoreDefinition: "readinessScorePercent = round(pass / total * 100)",
    overallStatusRule: "fail if any fail/invalid status exists, otherwise pending until explicit release sign-off",
  },
};

if (totals.invalid > 0) {
  fail("Scorecard generation blocked due to invalid status values in source artifacts.");
}

const resolvedOutputPath = path.resolve(process.cwd(), outputPath);
fs.writeFileSync(resolvedOutputPath, `${JSON.stringify(scorecard, null, 2)}\n`, "utf8");

console.log(
  `[mobile-scorecard] Generated ${outputPath} (score=${readinessScorePercent}%, pass=${totals.pass}, pending=${totals.pending}, fail=${totals.fail})`,
);
