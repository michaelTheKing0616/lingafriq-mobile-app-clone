// charter: v2
// Spec tests for Studio effort verification (P4-080). Mode A.

import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { test } from "node:test";
import {
  CURRICULUM_STUDIO_ESTIMATE,
  STUDIO_MVP_CARD_IDS,
  engineerWeeksForSize,
  parseCardSizeFromYaml,
  parseCardStatusFromYaml,
  sumEngineerWeeks,
  verifyStudioEffort,
  type CardSize,
  type StudioCardEffortRow,
} from "../studio/studioEffortEstimate.ts";

const CARDS_DIR = path.resolve(
  import.meta.dirname,
  "../../../docs/build/cards/P4",
);

async function loadStudioRows(): Promise<StudioCardEffortRow[]> {
  const rows: StudioCardEffortRow[] = [];
  for (const id of STUDIO_MVP_CARD_IDS) {
    const yaml = await readFile(path.join(CARDS_DIR, `${id}.yaml`), "utf8");
    const size = parseCardSizeFromYaml(yaml);
    const status = parseCardStatusFromYaml(yaml);
    assert.ok(size, `${id} must declare size S|M|L`);
    assert.ok(status, `${id} must declare status`);
    rows.push({
      id,
      size,
      weeks: engineerWeeksForSize(size),
      status,
    });
  }
  return rows;
}

test("test_P4_080_AC1_planned_weeks_inside_curriculum_band", async () => {
  const rows = await loadStudioRows();
  const planned = sumEngineerWeeks(rows);
  assert.ok(
    planned >= CURRICULUM_STUDIO_ESTIMATE.minWeeks &&
      planned <= CURRICULUM_STUDIO_ESTIMATE.maxWeeks,
    `planned ${planned} must fall in ${CURRICULUM_STUDIO_ESTIMATE.minWeeks}–${CURRICULUM_STUDIO_ESTIMATE.maxWeeks}`,
  );
});

test("test_P4_080_AC1_pre_g4_report_pending_actuals", async () => {
  const rows = await loadStudioRows();
  const report = verifyStudioEffort({ rows, g4Passed: false, asOf: "2026-10-25" });
  assert.equal(report.plannedEngineerWeeks, 11.5);
  assert.equal(report.verdict, "pending_g4_actuals");
  assert.equal(report.g4Passed, false);
  assert.ok(report.note.includes("G4 has not passed"));
});

test("test_P4_080_AC1_post_g4_verified_when_actuals_in_band", () => {
  const rows: StudioCardEffortRow[] = STUDIO_MVP_CARD_IDS.map((id) => ({
    id,
    size: "M" as CardSize,
    weeks: 1,
    status: "Done",
  }));
  const report = verifyStudioEffort({
    rows,
    g4Passed: true,
    actualEngineerWeeks: 12,
    asOf: "2026-10-25",
  });
  assert.equal(report.verdict, "verified");
  assert.equal(report.actualEngineerWeeks, 12);
});

test("test_P4_080_AC1_post_g4_revised_when_actuals_outside_band", () => {
  const rows: StudioCardEffortRow[] = [
    { id: "P4-069", size: "M", weeks: 1, status: "Done" },
  ];
  const report = verifyStudioEffort({
    rows,
    g4Passed: true,
    actualEngineerWeeks: 20,
    asOf: "2026-10-25",
  });
  assert.equal(report.verdict, "revised");
});
