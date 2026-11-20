#!/usr/bin/env bash
# Creates or updates the labels the factory uses. Run once per repo:
#   bash <plugin>/scripts/setup-labels.sh            (current repo)
#   bash <plugin>/scripts/setup-labels.sh owner/repo
# Labels hold each issue's state; the factory's workflows route on them.
set -euo pipefail

repo_args=()
[ $# -gt 0 ] && repo_args=(--repo "$1")

label() { gh label create "$1" --color "$2" --description "$3" --force ${repo_args[@]+"${repo_args[@]}"}; }

label "factory:ready"  "0e8a16" "You: the issue is ready for the factory to build"
label "stage:plan"     "c5def5" "Factory: planning"
label "stage:build"    "1d76db" "Factory: writing tests and code"
label "stage:review"   "fbca04" "Factory: gates and reviews running on the PR"
label "fix-round:1"    "f9d0c4" "Factory: first automatic fix round"
label "fix-round:2"    "f9d0c4" "Factory: second automatic fix round"
label "fix-round:3"    "f9d0c4" "Factory: last automatic fix round"
label "needs-human"    "d93f0b" "The factory stopped: a person must look"
label "ui"             "bfdadc" "Changes what users see; loads the frontend-design skill"
label "type:epic"      "5319e7" "Epic: groups work items as sub-issues"
label "dependencies"   "ededed" "Dependency updates"
echo "labels ready"
echo "v1 labels (stage:backlog, approved:*, review:*, and others) are no longer used; delete them once no issue has them."
