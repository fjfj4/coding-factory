---
description: Show the factory board - every work item and epic by column, who owns it, and what's waiting for you.
---

Show where the factory's work stands. Follow the `factory-workflow` skill for the columns and owners.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" sync`. It applies approvals (approved items move to New), moves closed issues to Done, places epics, and refreshes the GitHub Project board if one is set up.
2. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/board.sh" show` and present it as a compact board: one section per column with its owner, epics marked.
3. Add the open PRs: `gh pr list --state open --json number,title,headRefName,labels,statusCheckRollup,isDraft`, with their `review:*` label and whether checks are green.
4. End with a short "Waiting for you" list: items in Spec review, items in Architecture whose note is ready, items in Ready to merge, and anything stuck after three fix rounds.
5. If `.factory/board.env` exists, give the link to the GitHub Project board.
