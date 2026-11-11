#!/usr/bin/env bash
# Tests for plugins/factory/scripts/init-product.sh and the product gate presets.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
init="$root/plugins/factory/scripts/init-product.sh"
pass=0; fail=0
ok()  { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); echo "FAIL: $1"; }
check() { if eval "$2"; then ok; else bad "$1"; fi; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for stack in node python; do
  repo="$tmp/$stack"
  mkdir -p "$repo" && git -C "$repo" init -q
  printf 'node_modules/\n' > "$repo/.gitignore"
  (cd "$repo" && bash "$init" "$stack" >/dev/null 2>&1)
  check "$stack: creates the config"        "[ -f '$repo/.factory/config.md' ]"
  for f in .factory/gates.sh .factory/check-pr-body.sh .github/workflows/factory-gates.yml \
           .github/pull_request_template.md .github/ISSUE_TEMPLATE/work-item.yml \
           .github/dependabot.yml .github/CODEOWNERS work/.gitkeep docs/adr/.gitkeep tests/acceptance/.gitkeep; do
    check "$stack: creates $f" "[ -e '$repo/$f' ]"
  done
  check "$stack: gates.sh is executable"     "[ -x '$repo/.factory/gates.sh' ]"
  check "$stack: gates.sh is the $stack preset" "grep -q '$([ "$stack" = node ] && echo npx || echo 'uv run')' '$repo/.factory/gates.sh'"
  check "$stack: keeps existing .gitignore"  "grep -qx 'node_modules/' '$repo/.gitignore'"
  check "$stack: ignores scratch space"      "grep -qx '.factory/tmp/' '$repo/.gitignore' && grep -qx '.worktrees/' '$repo/.gitignore'"
  check "$stack: gates.sh rejects unknown gate" "! '$repo/.factory/gates.sh' bogus >/dev/null 2>&1"

  # Running again must not overwrite anything or duplicate .gitignore lines.
  echo "# edited" >> "$repo/.factory/config.md"
  (cd "$repo" && bash "$init" "$stack" >/dev/null 2>&1)
  check "$stack: rerun keeps edits"          "grep -qx '# edited' '$repo/.factory/config.md'"
  check "$stack: rerun no duplicate ignores" "[ \"\$(grep -cx '.worktrees/' '$repo/.gitignore')\" = 1 ]"
done

check "rejects a missing stack" "! (cd '$tmp/node' && bash '$init' >/dev/null 2>&1)"
check "rejects an unknown stack" "! (cd '$tmp/node' && bash '$init' ruby >/dev/null 2>&1)"
mkdir -p "$tmp/not-a-repo"
check "refuses outside a git repo" "! (cd '$tmp/not-a-repo' && GIT_CEILING_DIRECTORIES='$tmp' bash '$init' node >/dev/null 2>&1)"

# The PR template must pass its own check once filled in, and fail while empty.
check "empty PR template fails the check" "! '$root/scripts/check-pr-body.sh' '$root/plugins/factory/templates/product/.github/pull_request_template.md' >/dev/null 2>&1"

echo "$pass/$((pass + fail)) init tests passed"
[ "$fail" -eq 0 ]
