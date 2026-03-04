import fs from "node:fs";
import path from "node:path";

const DEFAULT_INPUT_PATH = "release-gates/mobile-device-matrix-checklist.json";
const ALLOWED_STATUSES = new Set(["pass", "pending", "fail"]);
const FAIL_STATUSES = new Set(["fail", "failed", "blocked"]);

function isRecord(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function isNonEmptyString(value) {
  return typeof value === "string" && value.trim().length > 0;
}

function fail(message) {
  console.error(`\n[device-matrix] ${message}`);
  process.exit(1);
}

const inputPath = process.argv[2] || DEFAULT_INPUT_PATH;
const resolvedPath = path.resolve(process.cwd(), inputPath);

if (!fs.existsSync(resolvedPath)) {
  fail(`Checklist file not found: ${resolvedPath}`);
}

let checklist;
try {
  checklist = JSON.parse(fs.readFileSync(resolvedPath, "utf8"));
} catch (error) {
  fail(`Checklist is not valid JSON: ${error.message}`);
}

const errors = [];
const requiredPassCriteria = checklist?.requiredPassCriteria;
const devices = checklist?.devices;
const requiredTests = Array.isArray(requiredPassCriteria?.requiredTestsPerDevice)
  ? requiredPassCriteria.requiredTestsPerDevice.map((testName) => String(testName).trim()).filter(Boolean)
  : [];
const minPassingDevices = Number(requiredPassCriteria?.minimumPassingDevices);

if (!isRecord(requiredPassCriteria)) {
  errors.push("Root field `requiredPassCriteria` must be an object.");
}

if (!Number.isInteger(minPassingDevices) || minPassingDevices < 1) {
  errors.push("requiredPassCriteria.minimumPassingDevices must be an integer >= 1.");
}

if (requiredTests.length === 0) {
  errors.push("requiredPassCriteria.requiredTestsPerDevice must be a non-empty array.");
}

if (!isRecord(devices) || Object.keys(devices).length === 0) {
  errors.push("Root field `devices` must be a non-empty object.");
}

let passDevices = 0;
let pendingDevices = 0;
let failDevices = 0;
let totalTests = 0;
let passTests = 0;
let pendingTests = 0;
let failTests = 0;

for (const [deviceName, deviceConfig] of Object.entries(devices || {})) {
  if (!isRecord(deviceConfig)) {
    errors.push(`devices.${deviceName} must be an object.`);
    continue;
  }

  for (const field of ["platform", "osVersion", "formFactor", "status", "lastVerifiedAt"]) {
    if (!isNonEmptyString(deviceConfig[field])) {
      errors.push(`devices.${deviceName}.${field} must be a non-empty string.`);
    }
  }

  const normalizedDeviceStatus = String(deviceConfig.status || "").trim().toLowerCase();
  if (!ALLOWED_STATUSES.has(normalizedDeviceStatus)) {
    errors.push(`devices.${deviceName}.status must be one of: pass, pending, fail.`);
  }

  if (normalizedDeviceStatus === "pass") {
    passDevices += 1;
  } else if (normalizedDeviceStatus === "pending") {
    pendingDevices += 1;
  } else if (FAIL_STATUSES.has(normalizedDeviceStatus)) {
    failDevices += 1;
  }

  if (!isRecord(deviceConfig.tests)) {
    errors.push(`devices.${deviceName}.tests must be an object.`);
    continue;
  }

  for (const testName of requiredTests) {
    const testConfig = deviceConfig.tests[testName];
    if (!isRecord(testConfig)) {
      errors.push(`devices.${deviceName}.tests.${testName} is required and must be an object.`);
      continue;
    }

    const normalizedTestStatus = String(testConfig.status || "").trim().toLowerCase();
    if (!ALLOWED_STATUSES.has(normalizedTestStatus)) {
      errors.push(`devices.${deviceName}.tests.${testName}.status must be one of: pass, pending, fail.`);
    }
    if (!isNonEmptyString(testConfig.evidence)) {
      errors.push(`devices.${deviceName}.tests.${testName}.evidence must be a non-empty string.`);
    }

    totalTests += 1;
    if (normalizedTestStatus === "pass") {
      passTests += 1;
    } else if (normalizedTestStatus === "pending") {
      pendingTests += 1;
    } else if (FAIL_STATUSES.has(normalizedTestStatus)) {
      failTests += 1;
    }
  }
}

if (Number.isInteger(minPassingDevices) && passDevices < minPassingDevices) {
  errors.push(
    `Pass criteria not met: ${passDevices} passing devices, required ${minPassingDevices}.`,
  );
}

if (requiredPassCriteria?.failIfAnyDeviceHasFail === true && failDevices > 0) {
  errors.push(`Pass criteria not met: ${failDevices} device(s) have status fail.`);
}

if (failTests > 0) {
  errors.push(`Test criteria not met: ${failTests} test execution(s) are marked fail.`);
}

if (errors.length > 0) {
  console.error("\n[device-matrix] Validation failed:");
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log(
  `[device-matrix] Validation passed (${passDevices} pass, ${pendingDevices} pending devices; ${passTests}/${totalTests} tests pass, ${pendingTests} pending): ${inputPath}`,
);
