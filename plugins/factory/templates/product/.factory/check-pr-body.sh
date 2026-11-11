#!/usr/bin/env bash
# Checks that a PR description fills in every required section of the PR template.
# Usage: PR_BODY="..." scripts/check-pr-body.sh   or   scripts/check-pr-body.sh body.md
set -uo pipefail

if [ $# -gt 0 ]; then body="$(cat "$1")"; else body="${PR_BODY:-}"; fi
# Drop HTML comments (template hints) and carriage returns.
clean="$(printf '%s\n' "$body" | tr -d '\r' | perl -0pe 's/<!--.*?-->//gs')"

errors=0
err() { echo "ERROR: $*"; errors=$((errors + 1)); }

section() { # prints the text under "## <title>" up to the next "## "
  printf '%s\n' "$clean" | awk -v t="## $1" '
    $0 == t { on = 1; next }
    on && /^## / { exit }
    on { print }'
}

required=("Why" "What changed" "Visualize the change" "How to verify" "Risk and rollback" "Checklist")
for s in "${required[@]}"; do
  printf '%s\n' "$clean" | grep -qx "## $s" || { err "missing section: ## $s"; continue; }
  text="$(section "$s" | grep -v '^[[:space:]]*$' || true)"
  [ -n "$text" ] || err "section is empty: ## $s"
done

printf '%s\n' "$clean" | grep -Eqi '(fixes|closes|resolves) #[0-9]+' || err "link the issue with 'Fixes #<n>' under ## Why"

viz="$(section "Visualize the change")"
if printf '%s' "$viz" | grep -Eqi '(^|[^a-z])n/a([^a-z]|$)'; then
  printf '%s' "$viz" | grep -Eqi 'n/a *[:-] *[^ ].{3,}' || err "'N/A' under ## Visualize the change needs a one-line reason, e.g. 'N/A: docs typo'"
else
  printf '%s' "$viz" | grep -Eq '(```mermaid|!\[|<img|https?://)' || err "## Visualize the change needs a Mermaid diagram, a screenshot, or 'N/A: <reason>'"
fi

if printf '%s' "$(section "Checklist")" | grep -q '\- \[ \]'; then
  err "unchecked items under ## Checklist"
fi

if [ "$errors" -gt 0 ]; then
  echo "$errors problem(s) in the PR description"
  exit 1
fi
echo "PR description OK"
