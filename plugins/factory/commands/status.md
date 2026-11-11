---
description: Show the factory board - open issues by stage and approval, and open PRs with their review and check status.
---

Show where the factory's work stands. Follow the `factory-workflow` skill for the meaning of the labels.

1. `gh issue list --state open --limit 100 --json number,title,labels,assignees`
2. `gh pr list --state open --json number,title,headRefName,labels,statusCheckRollup,isDraft`
3. Show a compact table per stage (`stage:spec`, `stage:architecture`, `stage:build`, `stage:review`), with each item's approvals (`approved:spec`, `approved:architecture`, `needs:architecture`) and, for items in review, the PR number, `review:*` label and whether checks are green.
4. End with a short "Waiting for you" list: items that need a human approval, PRs that passed review and are ready to merge, and anything stuck after three fix rounds.
