#!/usr/bin/env bash
# Creates or updates the labels the factory uses. Run once per repo:
#   bash <plugin>/scripts/setup-labels.sh            (current repo)
#   bash <plugin>/scripts/setup-labels.sh owner/repo
set -euo pipefail

repo_args=()
[ $# -gt 0 ] && repo_args=(--repo "$1")

label() { gh label create "$1" --color "$2" --description "$3" --force ${repo_args[@]+"${repo_args[@]}"}; }

# One stage label per work item; they match the board columns. Owner in brackets.
label "stage:backlog"              "ededed" "Board: Backlog (analyst writing the spec)"
label "stage:spec-review"          "c5def5" "Board: Spec review (human approves the spec)"
label "stage:architecture"         "c5def5" "Board: Architecture (architect writes, human approves)"
label "stage:new"                  "bfdadc" "Board: New, ready to pick up (planner)"
label "stage:in-progress"          "0e8a16" "Board: In progress (coder; test engineer writes acceptance tests)"
label "stage:qa"                   "0e8a16" "Board: QA (test engineer: acceptance tests and gates)"
label "stage:review"               "fbca04" "Board: Review (code and security reviewers)"
label "stage:ready-to-merge"       "1d76db" "Board: Ready to merge (human)"
label "stage:done"                 "ededed" "Board: Done (merged; release)"
label "type:epic"                  "5319e7" "Epic: groups work items as sub-issues"
label "needs:architecture"         "d4c5f9" "Larger change: requires an approved architecture note"
label "approved:spec"              "1d76db" "Human approved the spec"
label "approved:architecture"      "1d76db" "Human approved the architecture note"
label "review:changes-requested"   "d93f0b" "A reviewer found blocking issues"
label "review:passed"              "0e8a16" "Both reviewers passed the PR"
label "dependencies"               "ededed" "Dependency updates"
echo "labels ready"
echo "Old labels stage:spec and stage:build are no longer used; delete them once no issue has them."
