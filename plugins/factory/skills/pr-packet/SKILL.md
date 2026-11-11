---
name: pr-packet
description: How to fill in the factory PR template so a human can approve a change at a glance, including a Mermaid diagram generated from the actual diff. Use when opening or updating a PR in /factory:build or /factory:fix.
---

# The PR packet

The human approves a merge from one packet: the PR description, the review reports and the gate results. Write the description from the evidence (the diff, the coder and test engineer reports, the gate output), never from memory or intent.

## Sections (all required; CI checks them with `.factory/check-pr-body.sh`)
1. **Why:** the problem or goal in 1–3 sentences, then `Fixes #<issue>`.
2. **What changed:** a short list grouped by area. Mark renames and formatting as "mechanical".
3. **Visualize the change:** at least one of:
   - a Mermaid diagram for flow, architecture, data model or state changes (before/after pair preferred)
   - before/after screenshots for visible UI changes (ask the human to add them if you can't capture them)
   - `N/A: <one-line reason>`, only when nothing structural or visible changed
4. **How to verify:** exact commands, and which tests cover which acceptance criterion.
5. **Risk and rollback:** what could break, who is affected, how to undo it (revert, feature flag, migration rollback).
6. **Checklist:** tick an item only if it is true. Leave it unticked and explain if not.

## Generating the diagram
- Build it from `git diff main...HEAD`, not from the plan. Every node must correspond to code that exists in the diff or that the diff calls.
- Choose the type by what changed: `flowchart` for control or request flow, `sequenceDiagram` for interactions between components, `erDiagram` for data model changes, `stateDiagram-v2` for state machines.
- Highlight what is new or changed: add `classDef changed stroke-width:3px` and apply it with `class <node> changed`.
- Keep it under about 15 nodes. Split into two diagrams rather than one dense one.
- Check the syntax: GitHub shows a red error box for invalid Mermaid. Quote labels that contain parentheses or colons.

## Writing the body safely
Write the body to `.factory/tmp/<issue#>/pr-body.md` and pass it with `--body-file`. Never put PR text inside a shell string, because issue and spec text can contain shell metacharacters.
