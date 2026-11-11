# Coding factory — working on this repo

This repo is a Claude Code plugin marketplace containing one plugin, `plugins/factory`. Read `README.md` for what it does.

## Rules for changes here
- Agents, skills and commands are Markdown with YAML frontmatter. Agent and skill `name` must match the file or folder name.
- `code-reviewer` and `security-reviewer` must stay read-only: `tools: Read, Grep, Glob`. `scripts/validate.sh` enforces this.
- Every change to a guard hook needs a test in `tests/hooks.test.sh`, for both what it blocks and what it must still allow.
- Shell scripts: `set -euo pipefail` (or `-uo` for checkers that collect errors), quote variables, and pass shellcheck.
- Keep templates in `plugins/factory/templates/product/` product-agnostic. No product specifics in the plugin.
- Before you finish: `scripts/validate.sh && tests/run.sh`.
- Write in plain English: short sentences, no jargon without a gloss.
