#!/usr/bin/env bash
# Applies the orchestrator's verdict to an issue with labels and comments.
# The agent decides; this script is the only thing that changes GitHub.
# Env: VERDICT (JSON from the agent), ISSUE (number), REPO (owner/name),
#      DRY_RUN ("false" to act; anything else only comments what it would do), GH_TOKEN.
set -euo pipefail

: "${VERDICT:?}" "${ISSUE:?}" "${REPO:?}"
dry_run="${DRY_RUN:-true}"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

gh_() { gh "$@" --repo "$REPO"; }
# Changes to GitHub go through act: in a dry run it only records them.
planned=()
act() { if [ "$dry_run" = "false" ]; then gh_ "$@"; else planned+=("$*"); fi; }

comment() { # comment <file>
  gh_ issue comment "$ISSUE" --body-file "$1" >/dev/null
}

if ! decision="$(jq -er '.decision' <<<"$VERDICT" 2>/dev/null)"; then decision="invalid"; fi
reason="$(jq -r '.reason // ""' <<<"$VERDICT" 2>/dev/null || true)"
body="$tmp/comment.md"

case "$decision" in
  ready)
    printf '**Factory:** ready to build. %s\n' "$reason" > "$body"
    act issue edit "$ISSUE" --add-label "stage:plan" --remove-label "factory:ready"
    ;;
  unclear)
    { printf '**Factory:** I need answers before I can build this. %s\n\n' "$reason"
      jq -r '.questions // [] | to_entries[] | "\(.key + 1). \(.value)"' <<<"$VERDICT"
      printf '\nAnswer in a comment, then add the `factory:ready` label again.\n'; } > "$body"
    act issue edit "$ISSUE" --add-label "needs-human" --remove-label "factory:ready"
    ;;
  split)
    count="$(jq '.subissues // [] | length' <<<"$VERDICT")"
    if [ "$count" -lt 2 ]; then
      printf '**Factory:** the orchestrator asked to split this issue but gave fewer than two parts. A person must look.\n' > "$body"
      act issue edit "$ISSUE" --add-label "needs-human" --remove-label "factory:ready"
    else
      printf '**Factory:** this is too big for one PR, so I split it into %s parts. %s\n\n' "$count" "$reason" > "$body"
      for i in $(seq 0 $((count - 1))); do
        title="$(jq -r ".subissues[$i].title" <<<"$VERDICT")"
        { jq -r ".subissues[$i].body" <<<"$VERDICT"; printf '\n\nPart of #%s.\n' "$ISSUE"; } > "$tmp/sub$i.md"
        if [ "$dry_run" = "false" ]; then
          url="$(gh_ issue create --title "$title" --body-file "$tmp/sub$i.md" --label "factory:ready")"
          num="${url##*/}"
          id="$(gh api "repos/$REPO/issues/$num" --jq .id)"
          gh api --method POST "repos/$REPO/issues/$ISSUE/sub_issues" -F "sub_issue_id=$id" >/dev/null
          printf -- '- #%s\n' "$num" >> "$body"
        else
          planned+=("issue create --title $title --label factory:ready")
          printf -- '- %s\n' "$title" >> "$body"
        fi
      done
      act issue edit "$ISSUE" --add-label "type:epic" --remove-label "factory:ready"
    fi
    ;;
  *)
    printf '**Factory:** the orchestrator gave no valid answer, so a person must look.\n' > "$body"
    act issue edit "$ISSUE" --add-label "needs-human" --remove-label "factory:ready"
    ;;
esac

if [ "$dry_run" != "false" ]; then
  { printf '\n---\n_Dry run: no labels changed and no issues created. Set the repository variable `FACTORY_DRY_RUN` to `false` to let the factory act. It would have run:_\n'
    for p in "${planned[@]}"; do printf -- '- `gh %s`\n' "$p"; done; } >> "$body"
fi
comment "$body"
echo "decision=$decision"
