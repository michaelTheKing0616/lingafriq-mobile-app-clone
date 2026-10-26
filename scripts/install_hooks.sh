#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

chmod +x .githooks/pre-commit
git config core.hooksPath .githooks

echo "install_hooks: core.hooksPath=$(git config core.hooksPath)"
