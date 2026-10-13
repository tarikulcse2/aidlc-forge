---
name: status
description: AI-DLC status of the current project - open CRs, gates, units, traceability gaps, last regression, and the next action. Read-only. Use when asked about AI-DLC progress or status.
model: haiku
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

Report the AI-DLC status of this project. **Read only:** don't change any file except `docs/traceability.md`.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/portfolio.sh"` and show its table and "Needs attention" list.
2. For each CR with `status: implementation`, list its units from the `### U-NN` headings in `units.md`: one line
   each (unit, title, size, after, status).
3. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" > docs/traceability.md`. Show only its summary line and
   any ❌ or 🟡 stories.
4. Last test run: the date and verdict from `docs/ops/test-report.md`, or "none yet". Don't run tests here.
5. End with the **next action**, as one command, using the same order as `/aidlc-forge:step`.
