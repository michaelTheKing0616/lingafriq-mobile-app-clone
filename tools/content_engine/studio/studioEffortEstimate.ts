// charter: v2
// Card-sum engineer-week model for Curriculum Studio MVP (P4-080, CP-§9.1-10).

export type CardSize = "S" | "M" | "L";

/** Planning conversion: one M card ≈ one engineer-week at the 2×6 MVP staffing in CURRICULUM §9.1. */
export const SIZE_ENGINEER_WEEKS: Record<CardSize, number> = {
  S: 0.5,
  M: 1,
  L: 2,
};

export const CURRICULUM_STUDIO_ESTIMATE = {
  minWeeks: 10,
  maxWeeks: 14,
  anchorWeeks: 12,
  label: "10–14 engineer-weeks (2 engineers × 6 weeks)",
  source: "CURRICULUM.md#§9.1:L788-L789",
} as const;

/** Member cards for E-P4-STUDIO (P4-069…P4-080). */
export const STUDIO_MVP_CARD_IDS = [
  "P4-069",
  "P4-070",
  "P4-071",
  "P4-072",
  "P4-073",
  "P4-074",
  "P4-075",
  "P4-076",
  "P4-077",
  "P4-078",
  "P4-079",
  "P4-080",
] as const;

export type StudioCardEffortRow = {
  id: string;
  size: CardSize;
  weeks: number;
  status: string;
};

export type StudioEffortVerdict = "verified" | "revised" | "pending_g4_actuals";

export type StudioEffortReport = {
  asOf: string;
  curriculum: typeof CURRICULUM_STUDIO_ESTIMATE;
  rows: StudioCardEffortRow[];
  plannedEngineerWeeks: number;
  doneEngineerWeeks: number;
  g4Passed: boolean;
  actualEngineerWeeks: number | null;
  variancePctFromAnchor: number | null;
  verdict: StudioEffortVerdict;
  note: string;
};

const SIZE_RE = /^size:\s*(S|M|L)\s*$/m;
const STATUS_RE = /^status:\s*(\S+)\s*$/m;

export function parseCardSizeFromYaml(yaml: string): CardSize | null {
  const match = SIZE_RE.exec(yaml);
  if (!match) return null;
  return match[1] as CardSize;
}

export function parseCardStatusFromYaml(yaml: string): string | null {
  const match = STATUS_RE.exec(yaml);
  return match ? match[1] : null;
}

export function engineerWeeksForSize(size: CardSize): number {
  return SIZE_ENGINEER_WEEKS[size];
}

export function sumEngineerWeeks(rows: Pick<StudioCardEffortRow, "weeks">[]): number {
  return rows.reduce((acc, row) => acc + row.weeks, 0);
}

export function variancePctFromAnchor(plannedWeeks: number, anchorWeeks: number): number {
  if (anchorWeeks === 0) return 0;
  return Math.abs((plannedWeeks - anchorWeeks) / anchorWeeks) * 100;
}

export function verifyStudioEffort(input: {
  rows: StudioCardEffortRow[];
  g4Passed: boolean;
  actualEngineerWeeks?: number | null;
  asOf?: string;
}): StudioEffortReport {
  const plannedEngineerWeeks = sumEngineerWeeks(input.rows);
  const doneEngineerWeeks = sumEngineerWeeks(
    input.rows.filter((row) => row.status === "Done"),
  );
  const g4Passed = input.g4Passed;
  const actual =
    input.actualEngineerWeeks === undefined ? null : input.actualEngineerWeeks;

  const { minWeeks, maxWeeks, anchorWeeks } = CURRICULUM_STUDIO_ESTIMATE;
  const plannedInRange =
    plannedEngineerWeeks >= minWeeks && plannedEngineerWeeks <= maxWeeks;

  let verdict: StudioEffortVerdict;
  let variancePctFromAnchorValue: number | null = null;
  let note: string;

  if (!g4Passed) {
    verdict = plannedInRange ? "verified" : "revised";
    variancePctFromAnchorValue = variancePctFromAnchor(plannedEngineerWeeks, anchorWeeks);
    note = plannedInRange
      ? `Card decomposition totals ${plannedEngineerWeeks} engineer-weeks, inside ${CURRICULUM_STUDIO_ESTIMATE.label}. G4 has not passed; calendar actuals stay pending.`
      : `Card decomposition totals ${plannedEngineerWeeks} engineer-weeks, outside ${CURRICULUM_STUDIO_ESTIMATE.label}. Revise the curriculum estimate or rescope cards. G4 actuals stay pending.`;
    if (verdict === "verified") {
      verdict = "pending_g4_actuals";
    }
  } else if (actual === null || Number.isNaN(actual)) {
    verdict = "pending_g4_actuals";
    note = "G4 passed but no actual engineer-weeks were supplied.";
  } else {
    variancePctFromAnchorValue = variancePctFromAnchor(actual, anchorWeeks);
    const actualInRange = actual >= minWeeks && actual <= maxWeeks;
    verdict = actualInRange ? "verified" : "revised";
    note = actualInRange
      ? `Recorded actuals ${actual} engineer-weeks are inside ${CURRICULUM_STUDIO_ESTIMATE.label} (variance ${variancePctFromAnchorValue.toFixed(1)}% from anchor ${anchorWeeks}).`
      : `Recorded actuals ${actual} engineer-weeks are outside ${CURRICULUM_STUDIO_ESTIMATE.label} (variance ${variancePctFromAnchorValue.toFixed(1)}% from anchor ${anchorWeeks}). Estimate revised.`;
  }

  return {
    asOf: input.asOf ?? new Date().toISOString().slice(0, 10),
    curriculum: CURRICULUM_STUDIO_ESTIMATE,
    rows: input.rows,
    plannedEngineerWeeks,
    doneEngineerWeeks,
    g4Passed,
    actualEngineerWeeks: actual,
    variancePctFromAnchor: variancePctFromAnchorValue,
    verdict,
    note,
  };
}
