#!/usr/bin/env bash
# Sets up a product repo for the coding factory. Run from the product repo root:
#   bash "<plugin>/scripts/init-product.sh" <node|python>
# Never overwrites existing files; it reports them instead.
set -euo pipefail

stack="${1:-}"
case "$stack" in node|python) ;; *) echo "usage: init-product.sh <node|python>" >&2; exit 64 ;; esac

here="$(cd "$(dirname "$0")" && pwd)"
tpl="$here/../templates/product"
git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "run this inside a git repository" >&2; exit 1; }
cd "$(git rev-parse --show-toplevel)"

copy() { # copy <src> <dest> [mode]
  if [ -e "$2" ]; then echo "exists, left alone: $2"; return; fi
  mkdir -p "$(dirname "$2")"
  cp "$1" "$2"
  [ -n "${3:-}" ] && chmod "$3" "$2"
  echo "created: $2"
}

copy "$tpl/.factory/config.md"                      .factory/config.md
copy "$tpl/.factory/gates.$stack.sh"                .factory/gates.sh 755
copy "$tpl/.factory/check-pr-body.sh"               .factory/check-pr-body.sh 755
copy "$tpl/.github/workflows/factory-gates.yml"     .github/workflows/factory-gates.yml
copy "$tpl/.github/pull_request_template.md"        .github/pull_request_template.md
copy "$tpl/.github/ISSUE_TEMPLATE/work-item.yml"    .github/ISSUE_TEMPLATE/work-item.yml
copy "$tpl/.github/dependabot.yml"                  .github/dependabot.yml
copy "$tpl/.github/CODEOWNERS"                      .github/CODEOWNERS

mkdir -p work docs/adr tests/acceptance
for d in work docs/adr tests/acceptance; do [ -n "$(ls -A "$d")" ] || { touch "$d/.gitkeep"; echo "created: $d/.gitkeep"; }; done

touch .gitignore
while IFS= read -r line; do
  [ -z "$line" ] && continue
  grep -qxF -- "$line" .gitignore || { echo "$line" >> .gitignore; echo "added to .gitignore: $line"; }
done < "$tpl/.factory/gitignore.snippet"

echo
echo "Next steps:"
echo "  1. Fill in .factory/config.md and adjust the commands in .factory/gates.sh."
echo "  2. Replace @OWNER in .github/CODEOWNERS with your GitHub username."
echo "  3. Create the labels:   bash \"$here/setup-labels.sh\""
echo "  4. Protect main: require a PR, the factory-gates checks and code-owner review."
