#!/usr/bin/env bash
# Validates the plugin structure: manifests, agent/skill/command frontmatter and hooks.
# Runs locally and in CI. Exit 1 on any problem.
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
plugin="$root/plugins/factory"
errors=0
err() { echo "ERROR: $*"; errors=$((errors + 1)); }

command -v jq >/dev/null 2>&1 || { echo "ERROR: jq is required"; exit 1; }

# All JSON files parse
while IFS= read -r f; do
  jq empty "$f" 2>/dev/null || err "invalid JSON: ${f#"$root"/}"
done < <(find "$root" -name '*.json' -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/.worktrees/*')

# Manifests
jq -e '.name and .owner.name and (.plugins | length > 0)' "$root/.claude-plugin/marketplace.json" >/dev/null 2>&1 \
  || err "marketplace.json needs name, owner.name and at least one plugin"
jq -e '.name == "factory" and .version and .description' "$plugin/.claude-plugin/plugin.json" >/dev/null 2>&1 \
  || err "plugin.json needs name 'factory', version and description"

# Returns the value of a frontmatter key, or empty if missing.
fm() { awk -v k="$2" 'NR==1 && $0!="---"{exit} NR>1 && $0=="---"{exit} NR>1 { if (index($0, k":")==1) { sub("^"k":[ ]*",""); print; exit } }' "$1"; }

check_fields() { # file, fields...
  local f="$1"; shift
  [ "$(head -n1 "$f")" = "---" ] || { err "${f#"$root"/}: missing frontmatter"; return; }
  for k in "$@"; do
    [ -n "$(fm "$f" "$k")" ] || err "${f#"$root"/}: frontmatter field '$k' is missing or empty"
  done
}

for f in "$plugin"/agents/*.md; do
  check_fields "$f" name description tools model
  name="$(fm "$f" name)"; [ "$name" = "$(basename "$f" .md)" ] || err "${f#"$root"/}: name '$name' must match file name"
done
for f in "$plugin"/skills/*/SKILL.md; do
  check_fields "$f" name description
  name="$(fm "$f" name)"; [ "$name" = "$(basename "$(dirname "$f")")" ] || err "${f#"$root"/}: name '$name' must match folder name"
done
for f in "$plugin"/commands/*.md; do
  check_fields "$f" description
done

# Reviewers must stay read-only: no Write, Edit or Bash in their tool lists.
for a in code-reviewer security-reviewer; do
  tools="$(fm "$plugin/agents/$a.md" tools)"
  printf '%s' "$tools" | grep -Eq '(Write|Edit|Bash|NotebookEdit)' && err "agents/$a.md must be read-only (tools: $tools)"
done

# Every hook script referenced exists and is executable
while IFS= read -r cmd; do
  script="${cmd//\"/}"; script="${script//\$\{CLAUDE_PLUGIN_ROOT\}/$plugin}"
  [ -x "$script" ] || err "hook script missing or not executable: $cmd"
done < <(jq -r '.. | objects | select(.type? == "command") | .command' "$plugin/hooks/hooks.json")

if [ "$errors" -gt 0 ]; then
  echo "$errors problem(s) found"
  exit 1
fi
echo "plugin structure OK"
