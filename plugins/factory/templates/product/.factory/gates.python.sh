#!/usr/bin/env bash
# Factory gates for a Python project (uv + ruff + mypy + pytest). Copied to .factory/gates.sh by /factory:init.
# Agents may run this file but not change it (guard hooks). Edit the commands to fit your project.
# Usage: ./.factory/gates.sh <all|ci|lint|typecheck|test|acceptance|build|security>
set -euo pipefail
cd "$(dirname "$0")/.."

g_lint()       { uv run ruff check . && uv run ruff format --check .; }
g_typecheck()  { uv run mypy .; }
g_test()       { uv run pytest --ignore=tests/acceptance -q; }
g_acceptance() { uv run pytest tests/acceptance -q; }
g_build()      { uv build --quiet; }

g_security() { # Local preview of the CI security gates. Skipped tools still run in CI.
  if command -v semgrep >/dev/null; then semgrep scan --config p/default --error --metrics=off --quiet; else echo "skip: semgrep not installed (runs in CI)"; fi
  if command -v gitleaks >/dev/null; then gitleaks detect --no-git --source . --redact; else echo "skip: gitleaks not installed (runs in CI)"; fi
  uv run --with pip-audit pip-audit
}

run() { echo "== gate: $1"; "g_$1"; echo "== pass: $1"; }

case "${1:-all}" in
  all) for g in lint typecheck test acceptance build security; do run "$g"; done ;;
  ci)  for g in lint typecheck test acceptance build; do run "$g"; done ;;
  lint|typecheck|test|acceptance|build|security) run "$1" ;;
  *) echo "usage: $0 <all|ci|lint|typecheck|test|acceptance|build|security>" >&2; exit 64 ;;
esac
