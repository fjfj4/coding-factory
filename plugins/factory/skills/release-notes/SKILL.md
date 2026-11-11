---
name: release-notes
description: How the release role prepares a release - choosing the semantic version, writing release notes from merged PRs, and handing the publish command to the human. Use in /factory:release.
---

# Preparing a release

You prepare; the human publishes. The guard hooks block `gh release` and pushes to `main` for Claude.

## Steps
1. Find the last release: `gh release list --limit 1` (or the latest `v*` tag). If there is none, this is `v0.1.0`.
2. List merged PRs since then: `gh pr list --state merged --base main --search "merged:>=<date of last release>" --json number,title,labels,body`.
3. Check every PR in the list: its gates passed on `main` (`gh run list --branch main --limit 5`) and its issues are closed. Report anything that is still open or red, and stop if the latest `main` run is red.
4. Choose the version with semantic versioning:
   - **major:** a breaking change to a public interface (a PR or spec says so)
   - **minor:** new behaviour
   - **patch:** fixes only
   Before 1.0.0, breaking changes bump the minor version.
5. Write release notes to `.factory/tmp/release/notes.md`:
   ```
   ## <version> — <date>
   ### Added
   - <user-facing change> (#<pr>)
   ### Changed
   ### Fixed
   ### Security
   ### Upgrade notes
   <migrations, config changes, breaking changes; or "None">
   ```
   Write for users, not developers: describe behaviour, not files.
6. Give the human the exact command to publish, for them to run:
   `gh release create v<version> --target main --title "v<version>" --notes-file .factory/tmp/release/notes.md`
7. After they confirm it's published, move the released issues from `stage:review` or `stage:done` to `stage:done` and comment the version on each.

Deployment isn't part of the factory yet. If the product deploys from releases, remind the human to watch the deploy.
