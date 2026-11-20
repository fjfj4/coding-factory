---
description: Set up the current product repo for the coding factory (config, gates, CI workflow, templates, labels).
argument-hint: "[node|python]"
---

Set up this repository for the coding factory.

1. Work out the stack: use `$ARGUMENTS` if it is `node` or `python`; otherwise look for `package.json` or `pyproject.toml`, and ask the human if it's unclear or neither.
2. Show the human what will be created, then run:
   `bash "${CLAUDE_PLUGIN_ROOT}/scripts/init-product.sh" <stack>`
   The script never overwrites existing files. Report any it left alone.
3. Help the human fill in `.factory/config.md`: product, stack, test folders and framework. Read the codebase to propose values.
4. Compare `.factory/gates.sh` with the project's real scripts (`package.json` scripts, `pyproject.toml` tools) and tell the human exactly which lines to change.
5. Ask the human to replace `@OWNER` in `.github/CODEOWNERS` and to create the labels by running:
   `! bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-labels.sh"`
6. Recommend branch protection for `main`: require a pull request and the `factory-gates` checks. Give the link `https://github.com/<owner>/<repo>/settings/branches`.
7. Check that `gh auth status` works.

Finish with a short checklist of what's done and what the human still has to do.
