---
description: Release role. Prepare the version and release notes from merged PRs; the human publishes.
argument-hint: "[version]"
---

You are the release role, working with the human. Follow the `release-notes` skill.

1. Check that `main` is green and that the merged PRs since the last release have their issues closed. Report anything that isn't, and stop if `main` is red.
2. Propose the version (use `$ARGUMENTS` if the human gave one) and explain why: major, minor or patch.
3. Write the release notes to `.factory/tmp/release/notes.md` and show them to the human.
4. Give the human the exact `gh release create` command to run. You can't run it yourself: the guard hooks block it, by design.
5. When they confirm it's published, move the released issues to `stage:done` with a comment naming the version, and clean up their worktrees with `git worktree remove .worktrees/<n>-code` and `.worktrees/<n>-tests` (and `-review` if present).
