#!/usr/bin/env bash
# PreToolUse guard for the Bash tool.
# Reads the hook payload (JSON) on stdin. Exit 2 blocks the command and shows
# stderr to Claude. Exit 0 allows it. Fails closed if jq is missing.
set -euo pipefail

deny() {
  echo "factory guard: blocked. $1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || deny "jq is required by the factory guard hooks. Install jq (e.g. 'brew install jq')."

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // empty')"
[ -z "$cmd" ] && exit 0

# Collapse whitespace so patterns are not dodged with extra spaces or newlines.
c="$(printf '%s' "$cmd" | tr '\n\t' '  ' | tr -s ' ')"

match() { printf '%s' "$c" | grep -Eqi -- "$1"; }

# --- Human-only actions: merging, releasing, repo and credential admin ---
match '(^|[;&| ])gh +pr +merge' && deny "Merging is a human decision. Ask the human to merge on GitHub."
match '(^|[;&| ])gh +release' && deny "Releases are a human decision."
match '(^|[;&| ])gh +(repo +delete|secret|auth|ssh-key|gpg-key)' && deny "Repository and credential administration is human-only."
match '(^|[;&| ])gh +api .*(-X|--method) *(DELETE|PUT|PATCH)' && deny "Mutating GitHub API calls other than POST are human-only."

# Approvals are labels a human adds. Reading them is fine; adding, removing or redefining them is not.
match '(--add-label|--remove-label)[ =]+[^ ]*approved:' && deny "Approvals (approved:* labels) are given by a human in GitHub, not by Claude."
match 'gh +api .*labels.*(-f|-F|--field|--raw-field|--input).*approved:' && deny "Approvals (approved:* labels) are given by a human in GitHub, not by Claude."
match 'gh +label +(create|edit|delete|clone)' && deny "Label administration is human-only (run scripts/setup-labels.sh yourself)."


# --- Git safety ---
match 'git( +-[Cc] +[^ ]+)* +push.*(--force| -f( |$)| -d( |$)|--mirror|--delete| :[^ ]|:refs/)' && deny "Force-push, mirror and remote branch deletion are not allowed."
match 'git( +-[Cc] +[^ ]+)* +push.*( |:)(main|master)( |$)' && deny "Pushing to main is not allowed. Push a feature branch and open a PR."
match 'git( +-[Cc] +[^ ]+)* +(commit|push|merge|rebase).*--no-verify' && deny "Skipping git hooks with --no-verify is not allowed."
match 'git( +-[Cc] +[^ ]+)* +config .*(core\.hookspath|user\.(name|email))' && deny "Changing git hooks path or identity is not allowed."
match 'git( +-[Cc] +[^ ]+)* +reset +--hard +(origin/)?(main|master)' && deny "Hard reset to main is not allowed."

# --- Destructive or privilege-escalating commands ---
match '(^|[;&| ])sudo( |$)' && deny "sudo is not allowed."
# \$HOME below is matched literally in the command text; it must not expand.
# shellcheck disable=SC2016
match 'rm +(-[a-z]*r[a-z]*f|-[a-z]*f[a-z]*r|-r +-f|-f +-r)[a-z]* +(/|~|\$HOME|\.\.)( |/|$)' && deny "Recursive delete outside the project is not allowed."
match '(curl|wget)[^|]*\| *(ba|z|k)?sh' && deny "Piping downloads into a shell is not allowed."
match '(^|[;&| ])(chmod|chown) +-R +[^ ]*( /|~)' && deny "Recursive permission changes outside the project are not allowed."

# --- Secrets ---
printf '%s' "$c" | sed -E 's/\.env\.(example|sample|template)//g' | grep -Eqi -- '(^|[ /=<"'"'"'])\.env(\.[a-z0-9_-]+)?($|[ "'"'"';|&>])' && deny "Reading or writing .env files is not allowed. Ask the human for non-secret config."
match '(\.ssh/|\.aws/|\.gnupg/|\.config/gh/|id_rsa|id_ed25519|\.npmrc|\.netrc|\.pem( |$)|\.key( |$))' && deny "Access to credential files is not allowed."
match '(^|[;&| ])(printenv|env)( *$| *\|)' && deny "Dumping the environment is not allowed (it can contain secrets)."

# --- Protected paths: the gates, the hooks and Claude settings ---
if [ "${FACTORY_ALLOW_PROTECTED:-0}" != "1" ]; then
  if match '(\.github/workflows|plugins/factory/hooks|\.claude/settings|\.factory/(gates\.sh|check-pr-body\.sh))'; then
    if match '(>|sed +-i|tee |mv |cp |rm |chmod |ln |truncate|perl +-[a-z]*i)'; then
      deny "Agents may not change CI gates, guard hooks or Claude settings. A human can allow this by starting Claude with FACTORY_ALLOW_PROTECTED=1."
    fi
  fi
fi

exit 0
