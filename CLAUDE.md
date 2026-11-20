# Coding factory — working on this repo

This repo is a Claude Code plugin marketplace containing one plugin, `plugins/factory`. Read `README.md` for what it does.

## Rules for changes here
- Agents, skills and commands are Markdown with YAML frontmatter. Agent and skill `name` must match the file or folder name.
- Review stages (code review, security review) must stay read-only: no Write, Edit or Bash tools in their allowlist.
- v2 runs in GitHub Actions. Read `docs/plan-v2.md` and ADR 0003 before changing how the factory works.
- Shell scripts: `set -euo pipefail` (or `-uo` for checkers that collect errors), quote variables, and pass shellcheck.
- Keep templates in `plugins/factory/templates/product/` product-agnostic. No product specifics in the plugin.
- Before you finish: `scripts/validate.sh && tests/run.sh`.
- Write in plain English: short sentences, no jargon without a gloss.
