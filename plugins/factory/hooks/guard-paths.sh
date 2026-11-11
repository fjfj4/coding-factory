#!/usr/bin/env bash
# PreToolUse guard for file tools (Read, Write, Edit, MultiEdit, NotebookEdit).
# Exit 2 blocks the call and shows stderr to Claude. Fails closed if jq is missing.
set -euo pipefail

deny() {
  echo "factory guard: blocked. $1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || deny "jq is required by the factory guard hooks. Install jq (e.g. 'brew install jq')."

payload="$(cat)"
tool="$(printf '%s' "$payload" | jq -r '.tool_name // empty')"
path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty')"
[ -z "$path" ] && exit 0

base="$(basename -- "$path")"

# --- Secrets: never read or written by agents ---
case "$base" in
  .env|.env.*|*.pem|*.key|*.p12|*.pfx|id_rsa*|id_ed25519*|.npmrc|.netrc|credentials|*.tfstate|*.tfstate.*)
    case "$base" in
      .env.example|.env.sample|.env.template) ;;
      *) deny "Access to secret-bearing files ($base) is not allowed." ;;
    esac
    ;;
esac
case "$path" in
  */.ssh/*|*/.aws/*|*/.gnupg/*|*/.config/gh/*)
    deny "Access to credential directories is not allowed." ;;
esac

[ "$tool" = "Read" ] && exit 0

# --- Protected paths: the gates, the hooks and Claude settings ---
if [ "${FACTORY_ALLOW_PROTECTED:-0}" != "1" ]; then
  case "$path" in
    */.github/workflows/*|.github/workflows/*|*/plugins/factory/hooks/*|plugins/factory/hooks/*|*/.claude/settings*.json|.claude/settings*.json|*/.factory/gates.sh|.factory/gates.sh|*/.factory/check-pr-body.sh|.factory/check-pr-body.sh)
      deny "Agents may not change CI gates, guard hooks or Claude settings ($path). A human can allow this by starting Claude with FACTORY_ALLOW_PROTECTED=1."
      ;;
  esac
fi

exit 0
