# Factory config

Read by every factory agent and command. Keep it short and specific to this product. No secrets.

## Product
- **Name:** <product name>
- **Repo:** <owner/repo>
- **Stack:** <e.g. TypeScript, Node 22, Express, PostgreSQL>

## Where things live
- **Specs (Notion):** <link to the Specs database or page>
- **Architecture notes / ADRs (Notion):** <link to the ADR database or page>
- **Work items:** GitHub Issues in this repo
- **Snapshots for agents:** `work/<issue#>-<slug>/spec.md` and `architecture.md`, written when the build starts
- **Long-lived ADRs in the repo:** `docs/adr/`

## Gates
All gate commands live in `.factory/gates.sh` (protected: agents can run it but not change it).

| Gate | Command |
|---|---|
| Everything local | `./.factory/gates.sh all` |
| Lint and format | `./.factory/gates.sh lint` |
| Type check | `./.factory/gates.sh typecheck` |
| Unit tests | `./.factory/gates.sh test` |
| Acceptance tests | `./.factory/gates.sh acceptance` |
| Build | `./.factory/gates.sh build` |
| Local security scan (if tools installed) | `./.factory/gates.sh security` |

CI runs the same commands plus Semgrep (SAST), gitleaks (secrets), Trivy (dependencies) and the PR description check.

## Tests
- **Acceptance test folder (owned by the test engineer):** `tests/acceptance/`
- **Unit tests (owned by the coder):** <e.g. next to the code as `*.test.ts`, or `tests/unit/`>
- **Test framework:** <e.g. Vitest, pytest>

## Conventions
- Branch: `<issue#>-<short-slug>`
- Commits: `feat(#<issue>): ...`, `fix(#<issue>): ...`, `test(#<issue>): ...`, `refactor(#<issue>): ...`
- Coding standards: <link or short list, e.g. "see CLAUDE.md">
- Areas that always need an architecture note: auth, payments, personal data, data migrations, public APIs, anything irreversible
