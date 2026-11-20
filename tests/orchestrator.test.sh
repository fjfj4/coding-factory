#!/usr/bin/env bash
# Tests for actions/orchestrator/route.sh, with a fake gh that records its calls.
set -uo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
route="$root/actions/orchestrator/route.sh"
pass=0; fail=0
ok()  { pass=$((pass + 1)); }
bad() { fail=$((fail + 1)); echo "FAIL: $1"; }
check() { if eval "$2"; then ok; else bad "$1"; fi; }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
# Fake gh: log each call, keep comment bodies, return a URL for issue create and an id for the API.
cat > "$tmp/bin/gh" <<'EOF'
#!/usr/bin/env bash
echo "gh $*" >> "$GH_LOG"
prev=""
for a in "$@"; do
  [ "$prev" = "--body-file" ] && [ "$1" = "issue" ] && [ "$2" = "comment" ] && cat "$a" >> "$GH_COMMENTS"
  prev="$a"
done
case "$1 $2" in
  "issue create") n=$(( $(grep -c 'issue create' "$GH_LOG") + 100 )); echo "https://github.com/o/r/issues/$n" ;;
  "api repos/o/r/issues/"*) echo 9999 ;;
esac
EOF
chmod +x "$tmp/bin/gh"

run() { # run <dry_run> <verdict json>
  : > "$tmp/log"; : > "$tmp/comments"
  PATH="$tmp/bin:$PATH" GH_LOG="$tmp/log" GH_COMMENTS="$tmp/comments" \
    VERDICT="$2" ISSUE=7 REPO=o/r DRY_RUN="$1" "$route" > "$tmp/out" 2>&1
}
log()  { grep -c -- "$1" "$tmp/log"; }

run false '{"decision":"ready","reason":"Clear."}'
check "ready: moves to stage:plan"        "grep -q 'issue edit 7 --add-label stage:plan --remove-label factory:ready' '$tmp/log'"
check "ready: comments"                   "grep -q 'ready to build' '$tmp/comments'"
check "ready: prints decision"            "grep -qx 'decision=ready' '$tmp/out'"

run false '{"decision":"unclear","reason":"Vague.","questions":["Who is the user?","What is done?"]}'
check "unclear: needs-human"              "grep -q 'add-label needs-human --remove-label factory:ready' '$tmp/log'"
check "unclear: numbered questions"       "grep -qx '2. What is done?' '$tmp/comments'"

run false '{"decision":"split","reason":"Big.","subissues":[{"title":"Part A","body":"AC a"},{"title":"Part B","body":"AC b"}]}'
check "split: creates two sub-issues"     "[ \"\$(log 'issue create')\" = 2 ]"
check "split: sub-issues are factory:ready" "grep -q 'issue create --title Part A --body-file .* --label factory:ready' '$tmp/log'"
check "split: links them as sub-issues"   "[ \"\$(log 'sub_issues')\" = 2 ]"
check "split: parent becomes an epic"     "grep -q 'add-label type:epic --remove-label factory:ready' '$tmp/log'"
check "split: comment lists the issues"   "grep -qx -- '- #101' '$tmp/comments' && grep -qx -- '- #102' '$tmp/comments'"

run false '{"decision":"split","reason":"Big.","subissues":[{"title":"Only","body":"x"}]}'
check "split with one part: needs-human"  "grep -q 'add-label needs-human' '$tmp/log' && [ \"\$(log 'issue create')\" = 0 ]"

run false 'not json'
check "invalid verdict: needs-human"      "grep -q 'add-label needs-human' '$tmp/log'"
check "invalid verdict: prints invalid"   "grep -qx 'decision=invalid' '$tmp/out'"

run false '{"decision":"ship it"}'
check "unknown decision: needs-human"     "grep -q 'add-label needs-human' '$tmp/log'"

# Dry run: comments only, changes nothing.
run true '{"decision":"split","reason":"Big.","subissues":[{"title":"Part A","body":"a"},{"title":"Part B","body":"b"}]}'
check "dry run: only a comment"           "[ \"\$(grep -vc 'issue comment' '$tmp/log')\" = 0 ] && [ \"\$(log 'issue comment')\" = 1 ]"
check "dry run: says what it would do"    "grep -q 'Dry run' '$tmp/comments' && grep -q 'issue create --title Part A' '$tmp/comments'"
run "" '{"decision":"ready","reason":"x"}'
check "empty DRY_RUN means dry run"       "! grep -q 'issue edit' '$tmp/log'"

# Untrusted text never reaches a shell: a title with shell syntax stays literal.
run false '{"decision":"split","reason":"r","subissues":[{"title":"$(touch '"$tmp"'/pwned)","body":"b"},{"title":"B","body":"b"}]}'
check "split: titles are not executed"    "[ ! -e '$tmp/pwned' ]"

echo "$pass/$((pass + fail)) orchestrator tests passed"
[ "$fail" -eq 0 ]
