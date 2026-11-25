#!/usr/bin/env bash
# charter: v2
# P12-012: Gate cold start — median first meaningful frame < 2 s on Tecno/Infinix-class device.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
artifact_dir="${COLD_START_ARTIFACT_DIR:-$root/build/perf}"
artifact="$artifact_dir/cold_start_trace.json"
runs="${COLD_START_RUNS:-10}"
budget_ms=2000
pkg="${COLD_START_PACKAGE:-com.cracklog.lingafriq}"
activity="${COLD_START_ACTIVITY:-com.cracklog.lingafriq.MainActivity}"

median_int() {
  python3 - "$@" <<'PY'
import sys
vals = sorted(int(x) for x in sys.argv[1:])
if not vals:
    print(0)
    sys.exit(0)
mid = len(vals) // 2
if len(vals) % 2:
    print(vals[mid])
else:
    print((vals[mid - 1] + vals[mid]) // 2)
PY
}

top_spans_from_trace() {
  local trace_line="$1"
  python3 - "$trace_line" <<'PY'
import sys
line = sys.argv[1]
if "trace=" not in line:
    print("  (no startup trace in log)")
    sys.exit(0)
raw = line.split("trace=", 1)[1].strip()
events = [e for e in raw.split(",") if e]
starts = {}
durations = []
for ev in events:
    if ev.startswith("start:"):
        starts[ev[6:]] = ev
    elif ev.startswith("end:"):
        name = ev[4:]
        if name in {k[6:] for k in starts if k.startswith("start:")}:
            pass
        # pair by order: track last open start per name
    # Build durations by scanning pairs in order
starts_stack = {}
for ev in events:
    if ev.startswith("start:"):
        name = ev[6:]
        starts_stack.setdefault(name, []).append(ev)
    elif ev.startswith("end:"):
        name = ev[4:]
        stack = starts_stack.get(name)
        if stack:
            stack.pop()
            durations.append((name, 1))
# Simpler: consecutive start/end pairs in file order
durations_ms = []
i = 0
while i < len(events):
    ev = events[i]
    if ev.startswith("start:"):
        name = ev[6:]
        j = i + 1
        while j < len(events):
            if events[j] == f"end:{name}":
                durations_ms.append((name, j - i))
                break
            j += 1
    i += 1
durations_ms.sort(key=lambda x: x[1], reverse=True)
for name, _rank in durations_ms[:3]:
    print(f"  {name}")
if not durations_ms:
    print("  (no paired startup spans)")
PY
}

is_reference_device() {
  if [[ "${COLD_START_FORCE_NO_DEVICE:-}" == "1" ]]; then
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
  if [[ "${COLD_START_ALLOW_ANY_DEVICE:-}" == "1" ]]; then
    return 0
  fi
  return 1
}

self_test() {
  mkdir -p "$artifact_dir"
  local samples=(1650 1700 1750 1800 1820 1850 1880 1900 1920 1950)
  local med
  med="$(median_int "${samples[@]}")"
  python3 - "$artifact" "$med" "${samples[@]}" <<'PY'
import json, sys
path, med_s, *samples = sys.argv[1:]
med = int(med_s)
out = {
    "mode": "self-test",
    "device": "synthetic",
    "runs": len(samples),
    "first_frame_ms": samples,
    "first_meaningful_frame_ms": samples,
    "median_meaningful_frame_ms": med,
    "budget_ms": 2000,
    "passed": med < 2000,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
print(json.dumps(out))
PY
  if [[ "$med" -ge "$budget_ms" ]]; then
    echo "ERROR: self-test median $med ms >= $budget_ms" >&2
    exit 1
  fi
}

collect_from_device() {
  mkdir -p "$artifact_dir"
  adb logcat -c >/dev/null 2>&1 || true
  local meaningful=()
  local first=()
  local i
  for i in $(seq 1 "$runs"); do
    adb shell am force-stop "$pkg" >/dev/null 2>&1 || true
    adb shell am start -n "$pkg/$activity" >/dev/null
    local deadline=$(( $(date +%s) + 30 ))
    local got=""
    while [[ $(date +%s) -lt $deadline ]]; do
      got="$(adb logcat -d -s flutter 2>/dev/null | grep 'LingAfriqColdStart: first_meaningful_frame_ms=' | tail -1 || true)"
      if [[ -n "$got" ]]; then
        break
      fi
      sleep 0.25
    done
    local ff got_ff
    got_ff="$(adb logcat -d -s flutter 2>/dev/null | grep 'LingAfriqColdStart: first_frame_ms=' | tail -1 || true)"
    if [[ -z "$got" ]]; then
      echo "ERROR: run $i: no meaningful frame log within 30s" >&2
      exit 1
    fi
    meaningful+=("$(echo "$got" | sed -n 's/.*first_meaningful_frame_ms=//p' | tr -d '\r')")
    if [[ -n "$got_ff" ]]; then
      first+=("$(echo "$got_ff" | sed -n 's/.*first_frame_ms=//p' | tr -d '\r')")
    fi
    adb logcat -c >/dev/null 2>&1 || true
  done
  local med trace_line
  med="$(median_int "${meaningful[@]}")"
  trace_line="$(adb logcat -d -s flutter 2>/dev/null | grep 'LingAfriqColdStart: trace=' | tail -1 || true)"
  python3 - "$artifact" "$med" "$budget_ms" "${meaningful[@]}" <<'PY'
import json, sys
path, med_s, budget_s, *meaningful = sys.argv[1:]
med, budget = int(med_s), int(budget_s)
first = meaningful  # placeholder; extended below
out = {
    "mode": "device",
    "runs": len(meaningful),
    "first_meaningful_frame_ms": [int(x) for x in meaningful],
    "median_meaningful_frame_ms": med,
    "budget_ms": budget,
    "passed": med < budget,
}
with open(path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2)
print(json.dumps(out))
PY
  echo "Cold-start artifact: $artifact"
  echo "Median meaningful frame: ${med} ms (budget ${budget_ms} ms)"
  if [[ "$med" -ge "$budget_ms" ]]; then
    echo "ERROR: cold start median ${med} ms >= ${budget_ms} ms" >&2
    echo "Top startup spans (from last trace):" >&2
    top_spans_from_trace "$trace_line" >&2
    exit 1
  fi
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
    echo "Blocked: reference Tecno/Infinix-class device not attached (brand/model check failed)." >&2
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
