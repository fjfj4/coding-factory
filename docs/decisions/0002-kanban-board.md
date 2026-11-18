# 0002 — The kanban board is a GitHub Project, driven by labels

**Date:** 2026-11-18
**Status:** Accepted

## Context
We want one place that shows every work item and epic, which column it is in, and who is responsible. The columns follow the roles: Backlog (analyst), Spec review (human), Architecture (architect), New (planner), In progress (coder), QA (test engineer), Review (code and security reviewers), Ready to merge (human), Done (release).

## Options
| Option | For | Against |
|---|---|---|
| **GitHub Project board** | Lives next to the issues; updates live; drag-and-drop, filters, mobile app; sub-issue progress for epics; no hosting | Views must be set up by hand once; needs the `project` scope on `gh` |
| Custom web application | Full control of the design | A second copy of the state to keep in step, hosting, login and security to maintain |
| Claude artifact or Notion page | Easy to share | Can't update itself when the agents work; becomes a stale snapshot |

## Decision
- The board is a GitHub Project per product, with a `Stage` single-select field (the columns) and an `Owner` field.
- The `stage:*` label on each issue stays the source of truth. `scripts/board.sh move` changes the label and the Project card together; `board.sh sync` repairs drift, applies approvals (acting as the planner until there is a planner agent), moves closed issues to Done, and places epics.
- Epics are `type:epic` issues with GitHub sub-issues.

## Consequences
- Agents and commands need only `gh`, which they already use. The guard hooks still stop Claude from adding approvals.
- Cards dragged by hand are moved back on the next sync. Humans move items through commands or `board.sh move`.
- The QA column is new: after the coder and the test engineer finish in parallel, the joined code goes to QA, where the gates run and the test engineer judges any failing acceptance test.
