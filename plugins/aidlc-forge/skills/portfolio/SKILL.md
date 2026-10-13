---
name: portfolio
description: AI-DLC status across many projects - open CRs, gates waiting for ratification, red regressions - in one table. Read-only.
argument-hint: [folder containing projects]  (default: the parent folder of this project)
model: haiku
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

Show the AI-DLC portfolio for **$ARGUMENTS** (default: the parent folder of the current project). Read only.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/portfolio.sh" "<folder>"`.
2. Show the table as returned, then a short **Needs attention** list, ordered:
   - RED regressions
   - gates auto-approved but not yet ratified
   - CRs not updated for more than 14 days
   - projects without a test report
3. For each item, suggest one command and the project folder to run it in.
