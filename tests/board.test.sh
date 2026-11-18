#!/usr/bin/env bash
# Tests for plugins/factory/scripts/board.sh, using a fake `gh` that records its calls.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
board="$root/plugins/factory/scripts/board.sh"
pass=0; fail=0
ok()  { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); echo "FAIL: $1"; }
check() { if eval "$2"; then ok; else bad "$1"; fi; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
stub="$tmp/stub"; mkdir -p "$stub/bin"
log="$stub/calls.log"

# Fake gh: answers from fixture files in $stub and logs every call.
cat > "$stub/bin/gh" <<'EOF'
#!/usr/bin/env bash
stub="$(cd "$(dirname "$0")/.." && pwd)"
echo "gh $*" >> "$stub/calls.log"
case "$1 $2" in
  "issue view")   n="$3"; f="$stub/issue-$n.json"
                  if [[ " $* " == *" --jq "* ]]; then jq -r '.labels[].name' "$f"; else cat "$f"; fi ;;
  "issue edit")   ;;
  "issue list")   cat "$stub/issues.json" ;;
  "project view") echo '{"id":"PVT_1","number":7,"url":"https://github.com/users/demo/projects/7"}' ;;
  "project field-list") cat "$stub/fields.json" ;;
  "project item-add")   echo '{"id":"ITEM_1"}' ;;
  "project item-edit"|"project link"|"project field-create") ;;
  "project create") echo '{"number":7}' ;;
  "api repos/demo/app/issues/10/sub_issues") printf '2\n4\n' ;;
  "api "*) ;;
  *) echo "unexpected gh call: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$stub/bin/gh"

cat > "$stub/fields.json" <<'EOF'
{"fields":[
 {"id":"F_STAGE","name":"Stage","options":[{"id":"S_BACKLOG","name":"Backlog"},{"id":"S_SPEC","name":"Spec review"},{"id":"S_ARCH","name":"Architecture"},{"id":"S_NEW","name":"New"},{"id":"S_PROG","name":"In progress"},{"id":"S_QA","name":"QA"},{"id":"S_REV","name":"Review"},{"id":"S_READY","name":"Ready to merge"},{"id":"S_DONE","name":"Done"}]},
 {"id":"F_OWNER","name":"Owner","options":[{"id":"O_AN","name":"Analyst"},{"id":"O_AR","name":"Architect"},{"id":"O_PL","name":"Planner"},{"id":"O_CO","name":"Coder"},{"id":"O_TE","name":"Test engineer"},{"id":"O_RV","name":"Code + security reviewer"},{"id":"O_HU","name":"Human"},{"id":"O_RE","name":"Release"}]}
]}
EOF
issue() { # issue <n> <labels as JSON array of names>
  jq -n --argjson n "$1" --argjson l "$2" '{url:"https://github.com/demo/app/issues/\($n)", labels:($l|map({name:.}))}' > "$stub/issue-$1.json"
}
issue 1 '["stage:new","approved:spec"]'

repo="$tmp/repo"; mkdir -p "$repo" && git -C "$repo" init -q
run() { (cd "$repo" && PATH="$stub/bin:$PATH" FACTORY_REPO=demo/app bash "$board" "$@"); }
reset() { : > "$log"; }

# --- move without a project: labels only ---
reset
out="$(run move 1 in-progress)"
check "move prints owner"            "grep -q '#1 → In progress (owner: Coder)' <<<\"\$out\""
check "move adds the new label"      "grep -q -- '--add-label stage:in-progress' '$log'"
check "move removes the old label"   "grep -q -- '--remove-label stage:new' '$log'"
check "move keeps approvals"         "! grep -q -- '--remove-label approved:spec' '$log'"
check "no project, no board calls"   "! grep -q 'gh project' '$log'"
check "rejects unknown stage"        "! run move 1 testing 2>/dev/null"
check "rejects bad issue number"     "! run move 'x;rm' new 2>/dev/null"

# --- with a project ---
mkdir -p "$repo/.factory"
printf 'PROJECT_OWNER=demo\nPROJECT_NUMBER=7\n' > "$repo/.factory/board.env"
reset
run move 1 qa >/dev/null
check "adds the issue to the project" "grep -q 'gh project item-add 7 --owner demo --url https://github.com/demo/app/issues/1' '$log'"
check "sets Stage to QA"              "grep -q -- '--field-id F_STAGE --single-select-option-id S_QA' '$log'"
check "sets Owner to Test engineer"   "grep -q -- '--field-id F_OWNER --single-select-option-id O_TE' '$log'"

printf 'PROJECT_OWNER=demo; rm -rf /\nPROJECT_NUMBER=7\n' > "$repo/.factory/board.env"
reset
out="$(run move 1 review 2>&1)"
check "invalid board.env is not run"  "grep -q 'not valid' <<<\"\$out\" && ! grep -q 'gh project item-add' '$log'"
check "label still moves"             "grep -q -- '--add-label stage:review' '$log'"
printf 'PROJECT_OWNER=demo\nPROJECT_NUMBER=7\n' > "$repo/.factory/board.env"

# --- sync: approvals, close-outs, backlog, epics ---
cat > "$stub/issues.json" <<'EOF'
[
 {"number":2,"url":"https://github.com/demo/app/issues/2","state":"OPEN","labels":[{"name":"stage:spec-review"},{"name":"approved:spec"}]},
 {"number":3,"url":"https://github.com/demo/app/issues/3","state":"OPEN","labels":[{"name":"stage:spec-review"},{"name":"approved:spec"},{"name":"needs:architecture"}]},
 {"number":4,"url":"https://github.com/demo/app/issues/4","state":"CLOSED","labels":[{"name":"stage:ready-to-merge"}]},
 {"number":5,"url":"https://github.com/demo/app/issues/5","state":"OPEN","labels":[]},
 {"number":6,"url":"https://github.com/demo/app/issues/6","state":"CLOSED","labels":[]},
 {"number":8,"url":"https://github.com/demo/app/issues/8","state":"OPEN","labels":[{"name":"stage:architecture"},{"name":"needs:architecture"},{"name":"approved:architecture"}]},
 {"number":9,"url":"https://github.com/demo/app/issues/9","state":"OPEN","labels":[{"name":"stage:spec-review"}]},
 {"number":10,"url":"https://github.com/demo/app/issues/10","state":"OPEN","labels":[{"name":"type:epic"},{"name":"stage:backlog"}]}
]
EOF
issue 10 '["type:epic","stage:backlog"]'
reset
out="$(run sync)"
check "approved spec goes to New"              "grep -q '#2 → New (owner: Planner)' <<<\"\$out\""
check "approved spec needing ADR → Architecture" "grep -q '#3 → Architecture (owner: Architect)' <<<\"\$out\""
check "closed issue goes to Done"              "grep -q '#4 → Done (owner: Release)' <<<\"\$out\""
check "unlabelled open issue → Backlog"        "grep -q '#5 → Backlog (owner: Analyst)' <<<\"\$out\""
check "closed unlabelled issue is skipped"     "! grep -q 'issues/6' '$log'"
check "architecture needs spec approval too"   "! grep -q '#8 →' <<<\"\$out\""
check "unapproved spec stays in Spec review"   "! grep -q '#9 →' <<<\"\$out\""
check "epic follows its earliest sub-issue"    "grep -q '#10 → New (owner: Planner)' <<<\"\$out\""
check "sync never adds approvals"              "! grep -q -- '--add-label approved:' '$log'"

# --- setup ---
rm "$repo/.factory/board.env"
reset
out="$(run setup demo)"
check "setup creates the project"     "grep -q 'gh project create --owner demo --title Coding factory' '$log'"
check "setup links the repo"          "grep -q 'gh project link 7 --owner demo --repo demo/app' '$log'"
check "setup creates Stage columns"   "grep -q -- '--name Stage --data-type SINGLE_SELECT --single-select-options Backlog,Spec review,Architecture,New,In progress,QA,Review,Ready to merge,Done' '$log'"
check "setup creates Owner field"     "grep -q -- '--name Owner' '$log'"
check "setup writes board.env"        "grep -qx 'PROJECT_NUMBER=7' '$repo/.factory/board.env'"
check "setup refuses to run twice"    "! run setup demo 2>/dev/null"

# --- show ---
cat > "$stub/issues.json" <<'EOF'
[{"number":11,"title":"Login","labels":[{"name":"stage:qa"}]},{"number":12,"title":"Idea","labels":[]},{"number":13,"title":"Accounts","labels":[{"name":"stage:qa"},{"name":"type:epic"}]}]
EOF
out="$(run show)"
check "show lists columns with owners" "grep -q '== QA — Test engineer' <<<\"\$out\""
check "show places items"              "grep -A2 '== QA' <<<\"\$out\" | grep -q '#11 Login'"
check "show marks epics"               "grep -q '#13 \[epic\] Accounts' <<<\"\$out\""
check "show lists unstaged items"      "grep -A1 'Not on the board yet' <<<\"\$out\" | grep -q '#12 Idea'"

echo "$pass/$((pass + fail)) board tests passed"
[ "$fail" -eq 0 ]
