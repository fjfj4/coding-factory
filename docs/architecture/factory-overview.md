# The factory at a glance

Every stage of Coding Factory v2, the model it runs on, and the plugins, skills and tools it gets. Source: [plan](../plan-v2.md) and [ADR 0003](../decisions/0003-autonomous-factory-v2.md). Solid green boxes are built; the rest are planned.

```mermaid
flowchart TD
  you(["You add the label factory:ready"]) --> orch
  cron(["Hourly sweep"]) --> orch

  orch["<b>Orchestrator</b><br/>Model: Haiku<br/>Skills: none, our own prompt<br/>Tools: Read, Glob, Grep (read-only)<br/>Decides: ready, unclear, split"]
  orch -->|"unclear"| h1[/"Questions + needs-human"/]
  orch -->|"split"| subs["Sub-issues, each factory:ready"] --> orch
  orch -->|"ready: stage:plan"| plan

  plan["<b>Planner</b><br/>Model: Opus, also for its subagents<br/>Plugin: feature-dev<br/>Agents: code-explorer, code-architect<br/>Output: plan comment with Mermaid"]
  plan --> tw & coder

  subgraph par["In parallel, on separate branches"]
    tw["<b>Test writer</b><br/>Model: Sonnet<br/>Skills: none, our own prompt<br/>Writes acceptance tests from the spec only"]
    coder["<b>Coder</b><br/>Model: Sonnet<br/>Skill: frontend-design, only on ui issues<br/>Hooks: security-guidance, set to Sonnet"]
  end

  tw & coder --> join["<b>Join + open PR</b><br/>No model: plain git"]
  join --> gates["<b>Gates</b><br/>No model<br/>build, lint, types, tests, e2e<br/>Semgrep, gitleaks, Trivy<br/>acceptance tests untouched"]

  gates --> cr & sr & docs
  cr["<b>Code reviewer</b><br/>Model: Sonnet<br/>Plugin: feature-dev, agent code-reviewer<br/>Read-only, verdict as JSON"]
  sr["<b>Security reviewer</b><br/>Model: Sonnet, Opus if auth is touched<br/>Skills: none, our own prompt<br/>Read-only"]
  docs["<b>Docs + teaching</b><br/>Model: Sonnet<br/>Skills: none, two short prompts<br/>Screenshots: pinned Playwright script run by CI"]

  cr & sr & docs --> decide{"All checks green?"}
  decide -->|"yes"| merge[["GitHub auto-merge<br/>No model"]]
  decide -->|"protected paths"| h2[/"needs-human"/]
  decide -->|"no, round 1 to 3"| fixer["<b>Fixer</b><br/>Model: Sonnet<br/>Max 3 rounds"] --> gates
  decide -->|"no, after round 3"| h3[/"Summary + needs-human"/]

  weekly(["Weekly"]) --> deep["<b>Deep security scan</b><br/>Plugin: claude-security<br/>Model: plugin default<br/>Whole codebase, not per PR"]

  classDef built fill:#d3f9d8,stroke:#2b8a3e,stroke-width:2px
  classDef planned fill:#f1f3f5,stroke:#868e96,stroke-dasharray:4
  classDef nomodel fill:#fff,stroke:#adb5bd
  class orch built
  class plan,tw,coder,cr,sr,docs,fixer,deep planned
  class join,gates,merge nomodel
```

## Summary table

| Stage | Model | Plugins, skills, hooks | Can write? | Status |
|---|---|---|---|---|
| Orchestrator | Haiku | Our own prompt | No (labels set by a script) | Built |
| Planner | Opus |  `feature-dev`: `code-explorer`, `code-architect` | Comments only | Planned |
| Test writer | Sonnet | Our own prompt | Tests only | Planned |
| Coder | Sonnet | `frontend-design` (ui issues), `security-guidance` hooks | Yes | Planned |
| Join, gates, merge | None | Plain CI | n/a | Gates reused from v1 |
| Code reviewer | Sonnet | `feature-dev`: `code-reviewer` | No | Planned |
| Security reviewer | Sonnet, Opus on auth | Our own prompt | No | Planned |
| Docs + teaching | Sonnet | Our own prompts, Playwright script in CI | Docs only | Planned |
| Fixer | Sonnet | Same as coder | Yes | Planned |
| Deep security scan | Plugin default | `claude-security`, weekly | No | Planned |

Only one stage uses Haiku. Only the planner uses Opus every time; the security reviewer uses it when auth code changes. Most steps use no model at all, which keeps runs cheap and predictable.
