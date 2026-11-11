# 0001 — Start with a minimal factory

**Date:** 2026-11-11
**Status:** Accepted

## Context
The full design (see the Coding factory whiteboard) has around a dozen agents. Building them all at once would make it hard to learn which ones earn their place.

## Decision
Version 0.1 has four agents and deterministic gates. The human and the main Claude session cover the other roles.

| Role | v0.1 |
|---|---|
| Test engineer, coder, code reviewer, security reviewer | Subagents |
| CI gates | `.factory/gates.sh` locally, `factory-gates` workflow in CI |
| Analyst, architect, release | Main Claude session with the human, via `/factory:spec`, `/factory:architect`, `/factory:release` |

Other choices:
- **Runs locally** in Claude Code, installed as a plugin from this repo.
- **Human approval** of specs, architecture for larger changes (`needs:architecture`), and every merge.
- **GitHub Issues** for tasks and work breakdown; state in `stage:*` labels; approvals in `approved:*` labels that only humans set.
- **Notion** for specs and architecture notes. Snapshots are frozen into `work/<issue#>-<slug>/` when a build starts, so build agents don't need Notion access and the reviewed spec can't change underneath them.
- **Stack:** language-agnostic security gates, with presets for TypeScript/Node and Python.
- **Adopted from ADLC:** the handoff contract (state in the tracker, artifacts in a work folder, read only the previous stage's files, refuse when inputs are incomplete) and the PR template with a change visualization.

## Consequences
- Fast to start, and each role can be promoted to an agent later when there's evidence it's needed.
- The guard hooks are guardrails, not a sandbox. Branch protection and CODEOWNERS on GitHub are the real enforcement.
- The readiness evaluator, the other agents and the orchestrator come later.
