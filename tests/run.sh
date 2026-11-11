#!/usr/bin/env bash
# Runs every test suite in tests/. Exit 1 if any fails.
set -uo pipefail
dir="$(cd "$(dirname "$0")" && pwd)"
status=0
shopt -s nullglob
# Factory unit tests, then acceptance tests owned by the test engineer.
for t in "$dir"/*.test.sh "$dir"/acceptance/*.test.sh; do
  echo "== $(basename "$t")"
  "$t" || status=1
done
exit "$status"
