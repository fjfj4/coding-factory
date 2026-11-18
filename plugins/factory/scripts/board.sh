#!/usr/bin/env bash
# The factory board. GitHub stage labels are the source of truth; this script moves
# work items between stages and mirrors them onto a GitHub Project board (kanban).
#
#   board.sh setup [owner] [title]   create the GitHub Project, its fields, and .factory/board.env
#   board.sh move <issue#> <stage>   move one item: swap its stage:* label and update the board
#   board.sh sync                    apply approvals, close-outs and epic roll-ups; refresh the board
#   board.sh show                    print the board in the terminal (works without a Project)
#
# Stages: backlog spec-review architecture new in-progress qa review ready-to-merge done
# Needs: gh (with the "project" scope for setup and board updates: gh auth refresh -s project), jq, git.
set -euo pipefail

STAGES=(backlog spec-review architecture new in-progress qa review ready-to-merge done)
NAMES=("Backlog" "Spec review" "Architecture" "New" "In progress" "QA" "Review" "Ready to merge" "Done")
OWNERS=("Analyst" "Human" "Architect" "Planner" "Coder" "Test engineer" "Code + security reviewer" "Human" "Release")
OWNER_OPTIONS="Analyst,Architect,Planner,Coder,Test engineer,Code + security reviewer,Human,Release"

die()  { echo "board: $*" >&2; exit 1; }
warn() { echo "board: warning: $*" >&2; }

stage_index() { # stage_index <stage> -> prints its position, fails if unknown
  local i
  for i in "${!STAGES[@]}"; do
    if [ "${STAGES[$i]}" = "$1" ]; then echo "$i"; return 0; fi
  done
  return 1
}

root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "run this inside the product repo"
envfile="$root/.factory/board.env"
repo="${FACTORY_REPO:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"

# ---- GitHub Project access (optional: without board.env only labels change) ----

project_owner=""; project_number=""; project_id=""; fields_json=""

load_project() { # reads board.env without executing it; caches the project id and fields
  [ -n "$project_id" ] && return 0
  [ -f "$envfile" ] || return 1
  project_owner="$(sed -n 's/^PROJECT_OWNER=\([A-Za-z0-9-]\{1,39\}\)$/\1/p' "$envfile")"
  project_number="$(sed -n 's/^PROJECT_NUMBER=\([0-9]\{1,9\}\)$/\1/p' "$envfile")"
  [ -n "$project_owner" ] && [ -n "$project_number" ] || { warn "$envfile is not valid"; return 1; }
  project_id="$(gh project view "$project_number" --owner "$project_owner" --format json | jq -r .id)"
  fields_json="$(gh project field-list "$project_number" --owner "$project_owner" --format json)"
}

field_id()  { jq -r --arg f "$1" '.fields[] | select(.name == $f) | .id' <<<"$fields_json"; }
option_id() { jq -r --arg f "$1" --arg o "$2" '.fields[] | select(.name == $f) | .options[] | select(.name == $o) | .id' <<<"$fields_json"; }

board_set() { # board_set <issue url> <stage index>; returns 0 when there is no board to update
  local url="$1" i="$2" item
  [ -f "$envfile" ] || return 0
  load_project || return 1
  item="$(gh project item-add "$project_number" --owner "$project_owner" --url "$url" --format json | jq -r .id)"
  gh project item-edit --id "$item" --project-id "$project_id" \
    --field-id "$(field_id Stage)" --single-select-option-id "$(option_id Stage "${NAMES[$i]}")" >/dev/null
  gh project item-edit --id "$item" --project-id "$project_id" \
    --field-id "$(field_id Owner)" --single-select-option-id "$(option_id Owner "${OWNERS[$i]}")" >/dev/null
}

# ---- Labels ----

relabel() { # relabel <issue#> <stage> <current labels, one per line>
  local n="$1" stage="$2" labels="$3" l args=()
  while IFS= read -r l; do
    case "$l" in stage:*) [ "$l" = "stage:$stage" ] || args+=(--remove-label "$l") ;; esac
  done <<<"$labels"
  gh issue edit "$n" --repo "$repo" --add-label "stage:$stage" ${args[@]+"${args[@]}"} >/dev/null
}

move_issue() { # move_issue <issue#> <stage> <url> <labels>
  local n="$1" stage="$2" url="$3" labels="$4" i
  i="$(stage_index "$stage")"
  relabel "$n" "$stage" "$labels"
  board_set "$url" "$i" || warn "label moved, but the board was not updated for #$n; run: board.sh sync"
  echo "#$n → ${NAMES[$i]} (owner: ${OWNERS[$i]})"
}

cmd_move() {
  local n="${1:-}" stage="${2:-}" json
  [[ "$n" =~ ^[0-9]+$ ]] || die "usage: board.sh move <issue#> <stage>"
  stage_index "$stage" >/dev/null || die "unknown stage '$stage'. Stages: ${STAGES[*]}"
  json="$(gh issue view "$n" --repo "$repo" --json url,labels)"
  move_issue "$n" "$stage" "$(jq -r .url <<<"$json")" "$(jq -r '.labels[].name' <<<"$json")"
}

# ---- Sync ----

current_stage() { # current_stage <labels> -> first known stage label, or nothing
  local l
  while IFS= read -r l; do
    case "$l" in stage:*) stage_index "${l#stage:}" >/dev/null && { echo "${l#stage:}"; return 0; } ;; esac
  done <<<"$1"
  return 0
}

has_label() { grep -qxF -- "$2" <<<"$1"; }

next_stage() { # next_stage <state> <stage> <labels> -> where the item belongs now
  local state="$1" stage="$2" labels="$3"
  if [ "$state" = "CLOSED" ]; then echo done; return; fi
  if [ -z "$stage" ]; then echo backlog; return; fi
  if [ "$stage" = "spec-review" ] && has_label "$labels" "approved:spec"; then
    if has_label "$labels" "needs:architecture"; then echo architecture; else echo new; fi
    return
  fi
  if [ "$stage" = "architecture" ] && has_label "$labels" "approved:architecture" && has_label "$labels" "approved:spec"; then
    echo new; return
  fi
  echo "$stage"
}

cmd_sync() {
  local issues count k n url state labels stage target placed="" epics=() e children child ci min
  issues="$(gh issue list --repo "$repo" --state all --limit 500 --json number,url,state,labels)"
  count="$(jq length <<<"$issues")"
  for ((k = 0; k < count; k++)); do
    n="$(jq -r ".[$k].number" <<<"$issues")"
    url="$(jq -r ".[$k].url" <<<"$issues")"
    state="$(jq -r ".[$k].state" <<<"$issues")"
    labels="$(jq -r ".[$k].labels[].name" <<<"$issues")"
    stage="$(current_stage "$labels")"
    # Closed issues that never entered the factory stay off the board.
    if [ "$state" = "CLOSED" ] && [ -z "$stage" ]; then continue; fi
    if has_label "$labels" "type:epic"; then epics+=("$n|$url|$state|$stage"); continue; fi
    target="$(next_stage "$state" "$stage" "$labels")"
    if [ "$target" != "$stage" ]; then
      move_issue "$n" "$target" "$url" "$labels"
    else
      board_set "$url" "$(stage_index "$stage")" || warn "board not updated for #$n"
    fi
    placed+="$n:$(stage_index "$target")"$'\n'
  done
  # An epic sits in the earliest stage of its open sub-issues; done when all are done.
  for e in ${epics[@]+"${epics[@]}"}; do
    IFS='|' read -r n url state stage <<<"$e"
    children="$(gh api "repos/$repo/issues/$n/sub_issues" --jq '.[].number' 2>/dev/null || true)"
    min=""
    while IFS= read -r child; do
      [ -n "$child" ] || continue
      ci="$(sed -n "s/^$child:\([0-9]*\)$/\1/p" <<<"$placed")"
      [ -n "$ci" ] && { [ -z "$min" ] || [ "$ci" -lt "$min" ]; } && min="$ci"
    done <<<"$children"
    if [ "$state" = "CLOSED" ]; then target=done
    elif [ -n "$min" ]; then target="${STAGES[$min]}"
    else target="${stage:-backlog}"; fi
    labels="$(gh issue view "$n" --repo "$repo" --json labels --jq '.labels[].name')"
    if [ "$target" != "$stage" ]; then move_issue "$n" "$target" "$url" "$labels"
    else board_set "$url" "$(stage_index "$target")" || warn "board not updated for epic #$n"; fi
  done
  echo "board synced"
}

# ---- Show ----

cmd_show() {
  local issues i
  issues="$(gh issue list --repo "$repo" --state open --limit 500 --json number,title,labels)"
  for i in "${!STAGES[@]}"; do
    echo "== ${NAMES[$i]} — ${OWNERS[$i]}"
    jq -r --arg s "stage:${STAGES[$i]}" '.[] | select([.labels[].name] | index($s))
      | "  #\(.number) \(if ([.labels[].name] | index("type:epic")) then "[epic] " else "" end)\(.title)"' <<<"$issues"
  done
  echo "== Not on the board yet (no stage label)"
  jq -r '.[] | select([.labels[].name | startswith("stage:")] | any | not) | "  #\(.number) \(.title)"' <<<"$issues"
  if load_project 2>/dev/null; then
    echo; echo "Board: $(gh project view "$project_number" --owner "$project_owner" --format json | jq -r .url)"
  fi
}

# ---- Setup ----

cmd_setup() {
  local owner="${1:-${repo%%/*}}" title="${2:-Coding factory}" number names url
  [ -f "$envfile" ] && die "already set up ($envfile). Delete it to point at a different project."
  number="$(gh project create --owner "$owner" --title "$title" --format json | jq -r .number)"
  gh project link "$number" --owner "$owner" --repo "$repo" >/dev/null
  names="$(IFS=,; echo "${NAMES[*]}")"
  gh project field-create "$number" --owner "$owner" --name Stage --data-type SINGLE_SELECT --single-select-options "$names" >/dev/null
  gh project field-create "$number" --owner "$owner" --name Owner --data-type SINGLE_SELECT --single-select-options "$OWNER_OPTIONS" >/dev/null
  mkdir -p "$(dirname "$envfile")"
  printf 'PROJECT_OWNER=%s\nPROJECT_NUMBER=%s\n' "$owner" "$number" > "$envfile"
  url="$(gh project view "$number" --owner "$owner" --format json | jq -r .url)"
  cat <<EOF
Created the project: $url
Saved $envfile (commit it, so everyone uses the same board).

Two minutes of clicking left, because GitHub can't create views from the command line:
  1. Open the project and change the first view's layout to Board.
  2. View options → Column by: Stage. Show the fields Owner, Assignees, Labels and Parent issue.
  3. Filter that view: -label:type:epic
  4. Add a second view, "Epics": Table layout, filter label:type:epic, show Stage and Sub-issues progress.
Then fill the board: bash "$(cd "$(dirname "$0")" && pwd)/board.sh" sync
EOF
}

case "${1:-}" in
  setup) shift; cmd_setup "$@" ;;
  move)  shift; cmd_move "$@" ;;
  sync)  cmd_sync ;;
  show)  cmd_show ;;
  *) die "usage: board.sh <setup [owner] [title] | move <issue#> <stage> | sync | show>" ;;
esac
