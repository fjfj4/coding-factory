---
name: architecture-notes
description: How the architect role writes an architecture note (ADR) with a STRIDE threat model in Notion for larger changes. Use in /factory:architect, or when an issue has the needs:architecture label.
---

# Architecture notes

You are the architect, working with the human. The note gives the coder and the reviewers the decisions they must not make themselves. Keep it as short as the change allows: one to two pages.

## Steps
1. Read the approved spec snapshot or Notion page, the existing code in the affected area, `CLAUDE.md` and `docs/adr/`.
2. Write the note in Notion using `architecture-template.md`, in the ADR database or page named in `.factory/config.md`. If the Notion tools are not available, write it to `work/<issue#>-<slug>/architecture.md` and say so.
3. Include a Mermaid diagram of the components and data flow. Mark the trust boundaries.
4. Do the threat model with STRIDE for every new or changed entry point and trust boundary. Each threat gets a mitigation that the coder must implement and the security reviewer can check.
5. Link the note in the issue, move it to `stage:architecture` and ask the human to approve by adding `approved:architecture`. You never add that label.
6. When a decision will outlive this change (a new pattern, library or service), the human may ask you to mirror it to `docs/adr/NNNN-<title>.md` in the next PR.

## STRIDE prompts
| Threat | Ask |
|---|---|
| Spoofing | How do we know who is calling? |
| Tampering | Can input, stored data or messages be changed in transit or at rest? |
| Repudiation | Can we prove who did what (audit log, without personal data in it)? |
| Information disclosure | What leaks through responses, errors, logs or timing? |
| Denial of service | What is unbounded: input size, loops, queries, external calls? |
| Elevation of privilege | Where is authorization checked, and is it denied by default? |

## Prefer
Boring, well-known technology; existing patterns in the repo; the smallest change that meets the spec. Record the alternatives you rejected and why.
