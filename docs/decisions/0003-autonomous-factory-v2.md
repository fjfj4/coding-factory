# 0003 — Move to an autonomous factory in GitHub Actions

**Date:** 2026-11-20
**Status:** Accepted
**Replaces:** the human approval steps in 0001, and the label-sync script in 0002

## Context

v1 runs locally in Claude Code. A human approves every spec, every larger architecture and every merge, and drives each stage with a `/factory` command. That made the factory safe to learn with, but every feature waits on a person, and four of the agents are our own prompts that we must maintain.

The goal for v2 ([brief](../brief-v2.md)) is different: an issue labelled `factory:ready` should become merged, tested, reviewed and documented code without a human, unless something fails. It should be built from maintained Anthropic components where possible and use few tokens.

## Decision

- **Where it runs:** GitHub Actions, one workflow job per stage, using `anthropics/claude-code-action` pinned to a commit SHA. Labels hold the state; YAML does the routing.
- **Identity:** a small "factory" GitHub App of our own. Its tokens last one hour, can't change workflows, and, unlike `GITHUB_TOKEN`, their events trigger the next workflow.
- **Claude sign-in:** `CLAUDE_CODE_OAUTH_TOKEN` from the owner's Claude plan, with a turn cap and timeout on every run.
- **Agents:** an orchestrator (Haiku), a planner (Opus, because a good plan saves fix rounds later), and test writer, coder, code review, security review, docs and fixer runs (Sonnet). Maintained parts: `feature-dev`'s explorer, architect and reviewer agents; `frontend-design` for UI issues only; `security-guidance` hooks inside the coder run; `claude-security` as a weekly deep scan. Our own prompts only where nothing maintained fits, each a few hundred words.
- **Not chosen:** the `code-review` plugin (8 or more subagents per PR, and it skips PRs Claude already commented on), `pr-review-toolkit` (six agents), `claude-code-security-review` (needs an API key, not updated since February 2026), and the Playwright MCP plugin (unpinned `@latest`). Screenshots come from a pinned Playwright script that CI runs.
- **Merge:** GitHub native auto-merge (squash), only when every required check passes. Branch protection requires those checks. PRs that touch workflows, factory configuration, authentication, payments, secrets handling, database migrations, dependencies, infrastructure files, `CODEOWNERS`, `.claude/` or `CLAUDE.md` are labelled `needs-human` instead.
- **Fix loop:** at most three automatic rounds, then `needs-human` with a short summary.
- **Removed from v1:** the custom coder, test-engineer, code-reviewer and security-reviewer agents, the approval labels, `/factory:spec`, `/factory:architect`, `/factory:release`, the local guard hooks and `board.sh`.
- **Kept from v1:** the gate templates, the PR template with "Visualize the change", `.gitattributes`, Dependabot cooldown, and ADRs 0001 and 0002 as history.
- **Mobile apps:** Expo (React Native with TypeScript), so one codebase serves iOS, Android and web, and screenshots come from the web build.

## Consequences

- Features no longer wait for a person. The owner's main job becomes writing clear acceptance criteria, because the gates and tests are what make auto-merge safe.
- Agents reviewing agents share blind spots. Auto-merge starts switched off for about the first ten issues so the owner can compare the factory's verdicts with their own.
- Every run counts against the owner's Claude plan limits. On Pro, that allows only a few features per five-hour window. Heavier use needs Max or a separate API key with a budget.
- Enforcement moves from local hooks, which a determined agent could get around, to GitHub: branch protection, the App's permissions and each run's tool allowlist.
- Product repos need branch protection, so they must be public or on a paid GitHub plan.
