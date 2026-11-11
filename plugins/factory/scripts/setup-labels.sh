#!/usr/bin/env bash
# Creates or updates the labels the factory uses. Run once per repo:
#   bash <plugin>/scripts/setup-labels.sh            (current repo)
#   bash <plugin>/scripts/setup-labels.sh owner/repo
set -euo pipefail

repo_args=()
[ $# -gt 0 ] && repo_args=(--repo "$1")

label() { gh label create "$1" --color "$2" --description "$3" --force ${repo_args[@]+"${repo_args[@]}"}; }

label "stage:spec"                 "c5def5" "Human analyst is writing or approving the spec"
label "stage:architecture"         "c5def5" "Human architect is writing or approving the architecture note"
label "stage:build"                "0e8a16" "Test engineer and coder are building"
label "stage:review"               "fbca04" "Code and security review"
label "stage:done"                 "ededed" "Merged"
label "needs:architecture"         "d4c5f9" "Larger change: requires an approved architecture note"
label "approved:spec"              "1d76db" "Human approved the spec"
label "approved:architecture"      "1d76db" "Human approved the architecture note"
label "review:changes-requested"   "d93f0b" "A reviewer found blocking issues"
label "review:passed"              "0e8a16" "Both reviewers passed the PR"
label "dependencies"               "ededed" "Dependency updates"
echo "labels ready"
