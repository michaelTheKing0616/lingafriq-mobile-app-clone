#!/usr/bin/env bash
# charter: v2
# P12-013: Gate avatar frame-cost on reference Tecno/Infinix-class Android.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
artifact_dir="${FRAME_COST_ARTIFACT_DIR:-$root/build/perf}"
artifact="$artifact_dir/frame_cost_report.json"
budget_ms="${FRAME_COST_BUDGET_MS:-2}"
pkg="${FRAME_COST_PACKAGE:-com.cracklog.lingafriq}"
activity="${FRAME_COST_ACTIVITY:-com.cracklog.lingafriq.MainActivity}"
profile_screen="${FRAME_COST_SCREEN:-avatar_speaking}"

is_reference_device() {
  if [[ "${FRAME_COST_FORCE_NO_DEVICE:-}" == "1" ]]; then
    return 1
  fi
  if ! command -v adb >/dev/null 2>&1; then
    return 1
  fi
  if ! adb get-state >/dev/null 2>&1; then
    return 1
  fi
  local brand model
  brand="$(adb shell getprop ro.product.brand 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]')"
  model="$(adb shell getprop ro.product.model 2>/dev/null | tr -d '\r' | tr '[:upper:]' '[:lower:]')"
  case "$brand" in
    tecno|infinix|itel) return 0 ;;
  esac
  case "$model" in
    tecno*|infinix*|itel*) return 0 ;;
  esac
  if [[ "${FRAME_COST_ALLOW_ANY_DEVICE:-}" == "1" ]]; then
    return 0
  fi
  return 1
}

self_test() {
  mkdir -p "$artifact_dir"
  python3 - "$artifact" "$budget_ms" <<'PY'
import json, sys
path, budget_s = sys.argv[1], float(sys.argv[2])
# Synthetic under-budget speaking path (60 fps class).
samples = [0.35, 0.42, 0.38, 0.40, 0.36, 0.39, 0.37, 0.41, 0.38, 0.40]
p95 = sorted(samples)[int((len(samples) - 1) * 0.95)]
out = {
    "mode": "self-test",
    "screen": "avatar_speaking",
    "verdict": "pass",
    "p95_added_cost_ms": p95,
    "median_frame_ms": 16.0,
    "budget_ms": budget_s,
    "worst_added_cost_ms": sorted(samples, reverse=True)[:5],
    "passed": p95 <= budget_s,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
print(json.dumps(out))
PY
}

collect_from_device() {
  mkdir -p "$artifact_dir"
  adb logcat -c >/dev/null 2>&1 || true
  adb shell am force-stop "$pkg" >/dev/null 2>&1 || true
  adb shell am start -n "$pkg/$activity" \
    --es lingafriq_frame_cost_profile "$profile_screen" >/dev/null 2>&1 || \
    adb shell am start -n "$pkg/$activity" >/dev/null
  local deadline=$(( $(date +%s) + 90 ))
  local got=""
  while [[ $(date +%s) -lt $deadline ]]; do
    got="$(adb logcat -d 2>/dev/null | grep 'LingAfriqFrameCost: report=' | tail -1 || true)"
    if [[ -n "$got" ]]; then
      break
    fi
    sleep 0.5
  done
  if [[ -z "$got" ]]; then
    echo "ERROR: no LingAfriqFrameCost report within 90s (run integration_test/frame_cost_test on device or wire profile intent)" >&2
    exit 1
  fi
  python3 - "$artifact" "$got" "$budget_ms" <<'PY'
import json, re, sys
path, line, budget_s = sys.argv[1], sys.argv[2], float(sys.argv[3])
m = re.search(r"report=(\{.*\})", line)
if not m:
    print("ERROR: could not parse frame cost log line", file=sys.stderr)
    sys.exit(1)
report = json.loads(m.group(1))
screen = report.get("screen", "unknown")
verdict = report.get("verdict", "fail")
p95 = float(report.get("p95_added_cost_ms", 99))
worst = report.get("worst_added_cost_ms") or []
out = {
    "mode": "device",
    "screen": screen,
    "verdict": verdict,
    "p95_added_cost_ms": p95,
    "median_frame_ms": report.get("median_frame_ms"),
    "budget_ms": budget_s,
    "worst_added_cost_ms": worst[:5],
    "passed": verdict == "pass" and p95 <= budget_s,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
print(json.dumps(out))
if verdict == "degraded":
    print(f"ERROR: screen={screen} degraded (30 fps tier); not passed", file=sys.stderr)
    print(f"Worst 5 added-cost frames (ms): {worst[:5]}", file=sys.stderr)
    sys.exit(1)
if verdict != "pass" or p95 > budget_s:
    print(f"ERROR: screen={screen} frame budget exceeded (p95={p95} ms, budget={budget_s})", file=sys.stderr)
    print(f"Worst 5 added-cost frames (ms): {worst[:5]}", file=sys.stderr)
    sys.exit(1)
PY
}

case "${1:-}" in
  --self-test)
    self_test
    ;;
  --require-device)
    if is_reference_device; then
      echo "Reference device attached."
      exit 0
    fi
    echo "Blocked: reference Tecno/Infinix-class device not attached." >&2
    exit 3
    ;;
  "")
    if ! is_reference_device; then
      echo "Blocked: reference Tecno/Infinix-class device not attached." >&2
      exit 3
    fi
    collect_from_device
    ;;
  *)
    echo "Usage: $0 [--self-test|--require-device]" >&2
    exit 2
    ;;
esac
