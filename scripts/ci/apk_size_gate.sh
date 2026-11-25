#!/usr/bin/env bash
# charter: v2
# P12-004: Gate per-ABI release APK compressed download size (< 40 MB).
# Measurement: APK file bytes on disk (zip container = Play download-size proxy).
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
MAX_BYTES="${APK_SIZE_GATE_MAX_BYTES:-40000000}"
BASELINE="${APK_SIZE_GATE_BASELINE:-$root/scripts/ci/apk_size_baseline.json}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: required tool '$1' is not available; refusing to pass the gate" >&2
    exit 2
  fi
}

threshold_ok() {
  local size="$1"
  if [[ "$size" -lt "$MAX_BYTES" ]]; then
    return 0
  fi
  return 1
}

baseline_delta() {
  local abi="$1"
  local size="$2"
  if [[ ! -f "$BASELINE" ]]; then
    echo "  baseline: (missing $BASELINE)"
    return 0
  fi
  python3 - "$BASELINE" "$abi" "$size" <<'PY'
import json, sys
path, abi, size_s = sys.argv[1], sys.argv[2], sys.argv[3]
size = int(size_s)
try:
    data = json.load(open(path, encoding="utf-8"))
except OSError as e:
    print(f"  baseline: unreadable ({e})")
    sys.exit(0)
abis = data.get("abis") or {}
prev = abis.get(abi)
if prev is None:
    print(f"  baseline: no entry for {abi}")
else:
    delta = size - int(prev)
    sign = "+" if delta >= 0 else ""
    print(f"  baseline: {prev} bytes  delta {sign}{delta} vs last release")
PY
}

top_five_assets() {
  local apk="$1"
  echo "  five largest entries inside APK:"
  unzip -l "$apk" 2>/dev/null | awk 'NR > 3 && NF >= 4 && $1 ~ /^[0-9]+$/ { print $1 "\t" $4 }' \
    | sort -t$'\t' -k1 -nr | head -5 | while IFS=$'\t' read -r sz path; do
    echo "    ${sz} bytes  ${path}"
  done
}

measure_dir() {
  local dir="$1"
  local fail=0
  require_cmd unzip
  require_cmd python3
  if [[ ! -d "$dir" ]]; then
    echo "ERROR: APK directory not found: $dir" >&2
    exit 2
  fi
  shopt -s nullglob
  local apks=("$dir"/*-release.apk)
  if [[ ${#apks[@]} -eq 0 ]]; then
    apks=("$dir"/app-release.apk)
  fi
  if [[ ${#apks[@]} -eq 0 || ! -f "${apks[0]}" ]]; then
    echo "ERROR: no release APK(s) in $dir" >&2
    exit 2
  fi

  echo "apk_size_gate: measurement=compressed APK file bytes (download-size proxy); limit=${MAX_BYTES} bytes"

  for apk in "${apks[@]}"; do
    [[ -f "$apk" ]] || continue
    local base
    base="$(basename "$apk")"
    local abi="unknown"
    if [[ "$base" =~ app-(.+)-release\.apk ]]; then
      abi="${BASH_REMATCH[1]}"
    fi
    local size
    size="$(wc -c <"$apk" | tr -d ' ')"
    echo ""
    echo "ABI ${abi}: ${size} bytes  (${apk})"
    baseline_delta "$abi" "$size"
    if ! threshold_ok "$size"; then
      echo "FAIL: ${abi} APK is >= ${MAX_BYTES} bytes"
      top_five_assets "$apk"
      fail=1
    fi
  done

  if [[ "$fail" -ne 0 ]]; then
    exit 1
  fi
  echo ""
  echo "apk_size_gate: all measured ABIs under ${MAX_BYTES} bytes"
}

self_test() {
  set +e
  require_cmd python3
  require_cmd unzip
  local work
  work="$(mktemp -d)"
  local script="${BASH_SOURCE[0]}"
  trap 'rm -rf "${work:-}"' EXIT

  python3 - "$work" <<'PY'
import zipfile, sys
from pathlib import Path
work = Path(sys.argv[1])
# under threshold
small = work / "app-arm64-v8a-release.apk"
with zipfile.ZipFile(small, "w", compression=zipfile.ZIP_DEFLATED) as zf:
    zf.writestr("assets/small.txt", b"x" * 1024)
# over threshold (name only; size enforced via env in second run)
big = work / "app-armeabi-v7a-release.apk"
with zipfile.ZipFile(big, "w", compression=zipfile.ZIP_STORED) as zf:
    zf.writestr("assets/pad.bin", b"\0" * (50 * 1024 * 1024))
PY

  if APK_SIZE_GATE_MAX_BYTES=40000000 bash "$script" --apk-dir "$work" >/dev/null 2>&1; then
    echo "self-test: expected oversize APK to fail"
    exit 1
  fi

  # Only small APK present
  rm -f "$work/app-armeabi-v7a-release.apk"
  if ! APK_SIZE_GATE_MAX_BYTES=40000000 bash "$script" --apk-dir "$work" >/dev/null 2>&1; then
    echo "self-test: expected small APK to pass"
    exit 1
  fi

  # Missing unzip should fail loud (simulate by PATH)
  if PATH="/usr/bin:/bin" command -v unzip >/dev/null 2>&1; then
    if env -i PATH="/nonexistent" HOME="${HOME:-/tmp}" APK_SIZE_GATE_MAX_BYTES=40000000 \
      bash "$script" --apk-dir "$work" >/dev/null 2>&1; then
      echo "self-test: expected missing unzip to fail"
      exit 1
    fi
  fi

  echo "apk_size_gate self-test ok"
  set -e
}

usage() {
  echo "Usage: $0 [--apk-dir DIR] [--self-test]" >&2
  exit 2
}

main() {
  if [[ "${1:-}" == "--self-test" ]]; then
    self_test
    exit 0
  fi
  local apk_dir="$root/build/app/outputs/flutter-apk"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apk-dir)
        shift
        apk_dir="${1:?}"
        ;;
      --self-test)
        self_test
        exit 0
        ;;
      -h | --help)
        usage
        ;;
      *)
        usage
        ;;
    esac
    shift
  done
  measure_dir "$apk_dir"
}

main "$@"
