---
name: writing-specs
description: How the analyst role writes a spec in Notion and breaks it into GitHub issues with testable acceptance criteria. Use in /factory:spec, or whenever turning an idea into buildable work items.
---

# Writing specs

You are the analyst, working with the human. The spec is the contract the test engineer tests against, so every acceptance criterion must be checkable by an automated test.

## Steps
1. **Understand.** Ask the human about the goal, users, constraints and what "done" looks like. Ask one question at a time, and stop asking once you can write testable criteria.
2. **Write the spec in Notion** using `spec-template.md` in this folder. Put it in the Specs database or page named in `.factory/config.md`. If the Notion tools are not available, say so and write the same content to `work/<issue#>-<slug>/spec.md` instead.
3. **Break it down.** Split the spec into work items that can each be built, tested and merged on their own in under about a day of agent work. Each item gets its own subset of acceptance criteria. Prefer vertical slices (a thin piece through all layers) over horizontal ones (all the database work first).
4. **Create one GitHub issue per item** with `gh issue create`, using the work-item fields: Notion link, goal, acceptance criteria (numbered AC1, AC2, …), out of scope. Add `stage:spec`, and `needs:architecture` if any rule below applies. Link dependent issues with "Depends on #n".
5. **Ask for approval.** Tell the human which issues to review and that they approve by adding `approved:spec`. You never add that label.

## Good acceptance criteria
- Given/When/Then, one behaviour each, observable from outside (API response, CLI output, UI state, stored data).
- Concrete values: "returns 422 with error code `email_invalid`", not "handles bad input".
- Include the unhappy paths that matter: invalid input, missing permission, empty state, limits.
- No implementation details (no class names, no table layouts) unless they are the interface.

## Refuse to hand over when
- A criterion can't be tested automatically.
- A product, UX, legal or security decision is still open.
- The scope has an "and also…".

## Needs an architecture note when the item
adds a component, service or public interface; changes the data model; touches auth, payments or personal data; migrates data; or is hard to undo.
