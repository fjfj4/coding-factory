#!/usr/bin/env bash
# Factory gates for a TypeScript / Node project. Copied to .factory/gates.sh by /factory:init.
# Agents may run this file but not change it (guard hooks). Edit the commands to fit your project.
# Usage: ./.factory/gates.sh <all|ci|lint|typecheck|test|acceptance|build|security>
set -euo pipefail
cd "$(dirname "$0")/.."

g_lint()       { npx --no-install eslint . --max-warnings=0 && npx --no-install prettier --check .; }
g_typecheck()  { npx --no-install tsc --noEmit; }
g_test()       { npm test --silent; }
g_acceptance() { npx --no-install vitest run tests/acceptance; }
g_build()      { npm run build --if-present; }

g_security() { # Local preview of the CI security gates. Skipped tools still run in CI.
  if command -v semgrep >/dev/null; then semgrep scan --config p/default --error --metrics=off --quiet; else echo "skip: semgrep not installed (runs in CI)"; fi
  if command -v gitleaks >/dev/null; then gitleaks detect --no-git --source . --redact; else echo "skip: gitleaks not installed (runs in CI)"; fi
  npm audit --audit-level=high
}

run() { echo "== gate: $1"; "g_$1"; echo "== pass: $1"; }

case "${1:-all}" in
  all) for g in lint typecheck test acceptance build security; do run "$g"; done ;;
  ci)  for g in lint typecheck test acceptance build; do run "$g"; done ;;
  lint|typecheck|test|acceptance|build|security) run "$1" ;;
  *) echo "usage: $0 <all|ci|lint|typecheck|test|acceptance|build|security>" >&2; exit 64 ;;
esac
