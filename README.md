# Coding factory

> **v2 is under construction.** The factory is moving from local Claude Code commands to an autonomous pipeline in GitHub Actions: you label an issue `factory:ready`, and it comes back as a tested, reviewed, documented and auto-merged PR, or as a `needs-human` label with a clear reason. Read the [plan](docs/plan-v2.md) and [ADR 0003](docs/decisions/0003-autonomous-factory-v2.md). Progress is tracked in issue #12.
>
> **Looking for v1?** The local, human-approved factory (custom agents, `/factory:spec`, `/factory:build`, guard hooks, the kanban board) is tagged [`v1.0.0`](https://github.com/fjfj4/coding-factory/tree/v1.0.0).

## What is here today

The plugin can already set up a product repo with the deterministic gates that v2 builds on.

```
/plugin marketplace add fjfj4/coding-factory
/plugin install factory@coding-factory
```

Then open Claude Code in the product repo and run `/factory:init` (or `/factory:init node` / `/factory:init python`). It creates:

| File | Purpose |
|---|---|
| `.factory/config.md` | Stack, test folders, conventions. |
| `.factory/gates.sh` | The gate commands: lint, types, tests, acceptance tests, build. |
| `.factory/check-pr-body.sh` | Checks the PR template is filled in. |
| `.github/workflows/factory-gates.yml` | The same gates in CI, plus Semgrep, gitleaks and Trivy. |
| `.github/pull_request_template.md` | The PR packet: why, what, diagram, verify, risk, checklist. |
| `.github/ISSUE_TEMPLATE/work-item.yml` | Work items with acceptance criteria. |
| `.github/CODEOWNERS` | Changes to gates and CI need your review. |
| `work/`, `docs/adr/`, `tests/acceptance/` | Work notes, ADRs, acceptance tests. |

Then create the labels (`bash <plugin>/scripts/setup-labels.sh`) and protect `main`: require a pull request and the `factory-gates` checks.

**On Windows,** the scripts run in Git Bash, which comes with Git for Windows. You also need the GitHub CLI (`gh auth login`) and `jq`.

## Repository layout

```
.claude-plugin/marketplace.json     this repo is a plugin marketplace
plugins/factory/
  commands/      init
  skills/        pr-packet
  scripts/       init-product.sh, setup-labels.sh
  templates/     files /factory:init copies into a product repo
scripts/         validate.sh, check-pr-body.sh (for this repo's own CI)
tests/           tests for the PR check and /factory:init
docs/            v2 brief and plan; decisions/ holds the ADRs
```

## Developing the factory

```
scripts/validate.sh   # plugin structure and frontmatter
tests/run.sh          # PR-check and init tests
```

Both run in CI on every PR.
