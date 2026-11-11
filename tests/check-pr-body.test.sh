#!/usr/bin/env bash
# Tests for scripts/check-pr-body.sh. Run: tests/check-pr-body.test.sh
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
check="$root/scripts/check-pr-body.sh"
fail=0; count=0

expect() { # expect <pass|fail> <label> <body>
  count=$((count + 1))
  PR_BODY="$3" "$check" >/dev/null 2>&1; got=$?
  local want=0; [ "$1" = fail ] && want=1
  if [ "$got" -ne "$want" ]; then echo "FAIL: expected $1: $2"; fail=$((fail + 1)); fi
}

good='## Why
Agents could push to main. Fixes #12

## What changed
- hooks: block pushes to main

## Visualize the change
```mermaid
flowchart LR
  A[git push main] --> B{guard} --> C[blocked]
```

## How to verify
Run tests/run.sh

## Risk and rollback
Low. Revert the commit.

## Checklist
- [x] The spec'"'"'s acceptance criteria are met
- [x] Gates pass locally
- [x] Docs updated'

expect pass "complete description" "$good"
expect fail "empty body" ""
expect fail "untouched template" "$(cat "$root/.github/pull_request_template.md")"
expect fail "no issue link" "${good/Fixes #12/}"
expect fail "N/A without reason" "$(printf '%s' "$good" | perl -0pe 's/```mermaid.*?```/N\/A/s')"
expect pass "N/A with reason" "$(printf '%s' "$good" | perl -0pe 's/```mermaid.*?```/N\/A: docs typo only/s')"
expect fail "visualization missing" "$(printf '%s' "$good" | perl -0pe 's/```mermaid.*?```/see code/s')"
expect fail "unchecked checklist item" "${good/- \[x\] Docs updated/- [ ] Docs updated}"
expect fail "missing section" "${good/\#\# Risk and rollback/\#\# Risks}"

echo "$((count - fail))/$count PR body tests passed"
[ "$fail" -eq 0 ]
