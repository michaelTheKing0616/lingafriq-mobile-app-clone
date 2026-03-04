import fs from "node:fs";
import path from "node:path";

const REQUIRED_GATES = Array.from({ length: 12 }, (_, index) => `WS${index + 1}`);
const REQUIRED_GATE_FIELDS = ["status", "owner", "evidence", "notes", "verifiedAt"];
const FAIL_STATUSES = new Set(["fail", "failed", "blocked"]);
const ALLOWED_STATUSES = new Set(["pass", "pending", "fail"]);

const inputPath = process.argv[2] || "release-gates/ws1-ws12-gates.json";
const resolvedPath = path.resolve(process.cwd(), inputPath);

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function fail(message) {
  console.error(`\n[release-gates] ${message}`);
  process.exit(1);
}

if (!fs.existsSync(resolvedPath)) {
  fail(`Checklist file not found: ${resolvedPath}`);
}

let parsed;
try {
  parsed = JSON.parse(fs.readFileSync(resolvedPath, "utf8"));
} catch (error) {
  fail(`Checklist is not valid JSON: ${error.message}`);
}

const errors = [];
const gates = parsed?.gates;

if (!gates || typeof gates !== "object" || Array.isArray(gates)) {
  errors.push("Root field `gates` must exist and be an object.");
} else {
  for (const gateName of REQUIRED_GATES) {
    const gate = gates[gateName];
    if (!gate || typeof gate !== "object" || Array.isArray(gate)) {
      errors.push(`${gateName} is missing or not an object.`);
      continue;
    }

    for (const field of REQUIRED_GATE_FIELDS) {
      if (!(field in gate)) {
        errors.push(`${gateName}.${field} is required.`);
      }
    }

    if (!isNonEmptyString(gate.status)) {
      errors.push(`${gateName}.status must be a non-empty string.`);
    } else {
      const normalizedStatus = gate.status.trim().toLowerCase();
      if (!ALLOWED_STATUSES.has(normalizedStatus)) {
        errors.push(`${gateName}.status must be one of: pass, pending, fail.`);
      }
      if (FAIL_STATUSES.has(normalizedStatus)) {
        errors.push(`${gateName} is marked as fail (${gate.status}).`);
      }
    }

    if (!isNonEmptyString(gate.owner)) {
      errors.push(`${gateName}.owner must be a non-empty string.`);
    }

    if (!Array.isArray(gate.evidence) || gate.evidence.length === 0) {
      errors.push(`${gateName}.evidence must be a non-empty array.`);
    } else {
      const hasInvalidEvidence = gate.evidence.some((item) => !isNonEmptyString(item));
      if (hasInvalidEvidence) {
        errors.push(`${gateName}.evidence must contain only non-empty strings.`);
      }
    }

    if (!isNonEmptyString(gate.notes)) {
      errors.push(`${gateName}.notes must be a non-empty string.`);
    }

    if (!isNonEmptyString(gate.verifiedAt)) {
      errors.push(`${gateName}.verifiedAt must be a non-empty string.`);
    }
  }
}

if (errors.length > 0) {
  console.error("\n[release-gates] Validation failed:");
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

const summary = REQUIRED_GATES.reduce(
  (acc, gateName) => {
    const status = String(gates[gateName].status).toLowerCase();
    if (status === "pass") {
      acc.pass += 1;
    } else if (status === "pending") {
      acc.pending += 1;
    }
    return acc;
  },
  { pass: 0, pending: 0 },
);

console.log(
  `[release-gates] Validation passed (${summary.pass} pass, ${summary.pending} pending, 0 fail): ${inputPath}`,
);
