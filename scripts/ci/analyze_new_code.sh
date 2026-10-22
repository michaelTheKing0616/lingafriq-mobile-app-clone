#!/usr/bin/env bash
# Fail when a change adds an analyzer warning. Legacy warnings may stay; they may not grow.
set -euo pipefail

script_path=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")

parse_issues() {
  python3 -c '
import sys
text = sys.stdin.read().splitlines()
for line in text:
    parts = [p.strip() for p in line.split(" - ")]
    if len(parts) >= 4 and parts[0] in ("error", "warning"):
        loc = parts[1]
        if ":" not in loc:
            continue
        path, line_no, _col = loc.split(":", 2)
        print(f"{parts[0]}\t{path}:{line_no}")
        continue
    bullets = [p.strip() for p in line.split(" • ")]
    if len(bullets) >= 4 and bullets[0] in ("error", "warning"):
        loc = bullets[2]
        if ":" not in loc:
            continue
        path, line_no, _col = loc.split(":", 2)
        print(f"{bullets[0]}\t{path}:{line_no}")
'
}

run_analyze() {
  local dir="$1"
  shift
  if [[ "$#" -eq 0 ]]; then
    return 0
  fi
  local pubspec="$dir/pubspec.yaml"
  if [[ -f "$pubspec" ]] && grep -q "sdk: flutter" "$pubspec" && command -v flutter >/dev/null 2>&1; then
    (cd "$dir" && flutter analyze --no-fatal-infos --no-fatal-warnings "$@" 2>&1) || true
  elif command -v dart >/dev/null 2>&1; then
    (cd "$dir" && dart analyze --no-fatal-warnings "$@" 2>&1) || true
  else
    echo "dart or flutter is required" >&2
    return 1
  fi
}

count_for() {
  local file="$1"
  local issues="$2"
  printf '%s\n' "$issues" | awk -F'\t' -v f="$file" '
    $1 == "warning" {
      nloc = split($2, loc, ":")
      if (nloc >= 2 && loc[1] == f) n++
    }
    END { print n + 0 }
  '
}

lines_for() {
  local file="$1"
  local issues="$2"
  printf '%s\n' "$issues" | awk -F'\t' -v f="$file" '
    $1 == "warning" {
      nloc = split($2, loc, ":")
      if (nloc >= 2 && loc[1] == f) print $2
    }
  '
}

gate() {
  local repo="$1"
  cd "$repo"
  local base=""
  if [[ -n "${ANALYZE_BASE:-}" ]]; then
    base="$ANALYZE_BASE"
  elif [[ "${GITHUB_EVENT_NAME:-}" == "push" && -n "${GITHUB_EVENT_BEFORE:-}" && "${GITHUB_EVENT_BEFORE}" != 0000000000000000000000000000000000000000 ]]; then
    base="$GITHUB_EVENT_BEFORE"
  elif [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    git fetch origin "${GITHUB_BASE_REF}" >/dev/null 2>&1 || true
    base="origin/${GITHUB_BASE_REF}"
  elif git rev-parse --verify origin/main >/dev/null 2>&1; then
    base=origin/main
  elif git rev-parse --verify HEAD~1 >/dev/null 2>&1; then
    base=HEAD~1
  else
    echo "baseline 0 unchanged"
    return 0
  fi

  local mb
  mb=$(git merge-base HEAD "$base")
  local added modified
  added=$(git diff --name-only --diff-filter=A "$mb" HEAD -- '*.dart' || true)
  modified=$(git diff --name-only --diff-filter=M "$mb" HEAD -- '*.dart' || true)

  local current_out base_out
  current_out=$(run_analyze "$repo" .)
  local current_issues err_lines
  current_issues=$(printf '%s\n' "$current_out" | parse_issues || true)
  err_lines=$(printf '%s\n' "$current_issues" | awk -F'\t' '$1 == "error" { print $2 }')
  if [[ -z "$added" && -z "$modified" ]]; then
    if [[ -n "$err_lines" ]]; then
      printf '%s\n' "$err_lines"
      return 1
    fi
    echo "baseline 0 unchanged"
    return 0
  fi

  local base_files=()
  local f
  if [[ -n "$modified" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] && base_files+=("$f")
    done <<<"$modified"
  fi

  base_out=""
  if [[ "${#base_files[@]}" -gt 0 ]]; then
    local work
    work=$(mktemp -d)
    git worktree add --detach "$work" "$mb" >/dev/null
    if [[ -f "$work/pubspec.yaml" ]] && grep -q "sdk: flutter" "$work/pubspec.yaml" && command -v flutter >/dev/null 2>&1; then
      (cd "$work" && flutter pub get >/dev/null)
    fi
    base_out=$(run_analyze "$work" .)
    git worktree remove --force "$work" >/dev/null
  fi
  local base_issues
  base_issues=$(printf '%s\n' "$base_out" | parse_issues || true)

  local failed=0
  if [[ -n "$err_lines" ]]; then
    printf '%s\n' "$err_lines"
    failed=1
  fi
  local base_total=0
  local now_total=0
  if [[ -n "$added" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local hits
      hits=$(lines_for "$f" "$current_issues")
      if [[ -n "$hits" ]]; then
        printf '%s\n' "$hits"
        failed=1
      fi
    done <<<"$added"
  fi

  if [[ -n "$modified" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local b n
      b=$(count_for "$f" "$base_issues")
      n=$(count_for "$f" "$current_issues")
      base_total=$((base_total + b))
      now_total=$((now_total + n))
      if [[ "$n" -gt "$b" ]]; then
        echo "$f baseline $b now $n delta +$((n - b))"
        failed=1
      fi
    done <<<"$modified"
  fi

  if [[ "$failed" -ne 0 ]]; then
    if [[ "$now_total" -gt "$base_total" ]]; then
      echo "delta +$((now_total - base_total))"
    fi
    return 1
  fi
  echo "baseline ${base_total} unchanged"
}

self_test() {
  local tmp
  tmp=$(mktemp -d)
  local fail=0

  seed_repo() {
    local repo="$1"
    git -C "$repo" init -q -b main
    cat >"$repo/pubspec.yaml" <<'EOF'
name: fixture
environment:
  sdk: '>=3.0.0 <4.0.0'
EOF
    mkdir -p "$repo/lib"
  }
  commit() {
    local repo="$1"
    local msg="$2"
    git -C "$repo" add -A
    git -C "$repo" -c user.email=ci@example.com -c user.name=ci commit -q -m "$msg"
  }

  local ac1="$tmp/ac1"
  mkdir -p "$ac1"
  seed_repo "$ac1"
  printf '%s\n' 'void main() {}' >"$ac1/lib/ok.dart"
  commit "$ac1" "base"
  printf '%s\n' 'void main() {' '  var unused = 1;' '}' >"$ac1/lib/new_warning.dart"
  commit "$ac1" "add warning"
  local out
  if out=$(ANALYZE_BASE="$(git -C "$ac1" rev-parse HEAD~1)" bash "$script_path" "$ac1" 2>&1); then
    echo "AC1 expected failure" >&2
    fail=1
  fi
  printf '%s\n' "$out" | grep -q 'lib/new_warning.dart:2' || { echo "AC1 missing file:line" >&2; echo "$out" >&2; fail=1; }

  local ac2="$tmp/ac2"
  mkdir -p "$ac2"
  seed_repo "$ac2"
  printf '%s\n' 'void main() {' '  var unused = 1;' '}' >"$ac2/lib/legacy.dart"
  commit "$ac2" "base"
  printf '%s\n' 'void main() {' '  var unused = 1;' '  // touch' '}' >"$ac2/lib/legacy.dart"
  commit "$ac2" "touch"
  if ! out=$(ANALYZE_BASE="$(git -C "$ac2" rev-parse HEAD~1)" bash "$script_path" "$ac2" 2>&1); then
    echo "AC2 expected pass" >&2
    echo "$out" >&2
    fail=1
  fi
  printf '%s\n' "$out" | grep -q 'baseline 1 unchanged' || { echo "AC2 missing unchanged baseline" >&2; echo "$out" >&2; fail=1; }

  local ac3="$tmp/ac3"
  mkdir -p "$ac3"
  seed_repo "$ac3"
  printf '%s\n' 'void main() {' '  var unused = 1;' '}' >"$ac3/lib/legacy.dart"
  commit "$ac3" "base"
  printf '%s\n' 'void main() {' '  var unused = 1;' '  var also = 2;' '}' >"$ac3/lib/legacy.dart"
  commit "$ac3" "more warnings"
  if out=$(ANALYZE_BASE="$(git -C "$ac3" rev-parse HEAD~1)" bash "$script_path" "$ac3" 2>&1); then
    echo "AC3 expected failure" >&2
    fail=1
  fi
  printf '%s\n' "$out" | grep -q 'delta +1' || { echo "AC3 missing delta" >&2; echo "$out" >&2; fail=1; }

  local ac_err="$tmp/ac-err"
  mkdir -p "$ac_err"
  seed_repo "$ac_err"
  printf '%s\n' 'void main() {}' >"$ac_err/lib/ok.dart"
  commit "$ac_err" "base"
  printf '%s\n' 'void main( {' >"$ac_err/lib/broken.dart"
  commit "$ac_err" "syntax error"
  if out=$(ANALYZE_BASE="$(git -C "$ac_err" rev-parse HEAD~1)" bash "$script_path" "$ac_err" 2>&1); then
    echo "error case expected failure" >&2
    fail=1
  fi
  printf '%s\n' "$out" | grep -q 'lib/broken.dart:' || { echo "error case missing file:line" >&2; echo "$out" >&2; fail=1; }

  rm -rf "$tmp"
  if [[ "$fail" -ne 0 ]]; then
    echo "self-test failed" >&2
    return 1
  fi
  echo "self-test passed"
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit 0
fi

gate "${1:-.}"
