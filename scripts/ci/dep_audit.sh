#!/usr/bin/env bash
# Fail CI on a high production npm advisory.
# --self-test installs a known-vulnerable lodash and expects npm audit to fail.
set -euo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"

self_test() {
  local work
  work="$(mktemp -d)"
  cd "$work"
  npm init -y >/dev/null
  npm install lodash@4.17.20 --save --ignore-scripts >/dev/null
  if npm audit --omit=dev --audit-level=high; then
    echo "expected the seeded high advisory to fail npm audit"
    exit 1
  fi
  echo "seeded high advisory failed npm audit --omit=dev"
}

if [[ "${1:-}" == "--self-test" ]]; then
  self_test
  exit 0
fi

found=0
while IFS= read -r lock; do
  found=1
  dir="$(dirname "$lock")"
  echo "npm audit --omit=dev --audit-level=high in $dir"
  npm audit --omit=dev --audit-level=high --prefix "$dir"
done < <(find "$root" -name package-lock.json -not -path '*/node_modules/*')

if [[ "$found" -eq 0 ]]; then
  echo "No package-lock.json in this repo. The API lockfile is audited in node-backend."
fi
