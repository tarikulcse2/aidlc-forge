---
name: close
description: AI-DLC phase 6 (close). Close a delivered CR - merge its stories, NFRs, decisions and design into docs/baseline and archive it. Human-only.
argument-hint: <CR-NNN>
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

Close change request **$ARGUMENTS**. This is never run in auto mode.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.

1. **Check:**
   - every unit is ✅
   - the latest test report is GREEN
   - gate_deploy is `approved` or `n/a`
   - no gate is still `auto`. Gates must be ratified, so suggest `/aidlc-forge:step`.
   If anything fails, list it and stop.
2. **Merge into `docs/baseline/`:**
   - `stories.md`: add the new stories, and replace each changed AC with its new text. Remove the *(CR-NNN)*
     markers, and add `(since CR-NNN)` after the story title.
   - `nfr.md`, `prd.md` (scope, assumptions): apply the deltas. Add one line per decision to the PRD's
     decision log, linking to the CR folder.
   - `architecture.md` and `data-model.md`: apply the design deltas from `design.md`.
   - ADRs from this CR: change `Proposed (CR-NNN)` to `Accepted`.
3. Show the baseline diff summary and ask **"Close CR-NNN?"** On yes, set `status: closed` and `updated`.
4. `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" > docs/traceability.md`. The closed CR's stories are now counted from the baseline.
5. Suggest the commit `docs(CR-NNN): merge into baseline`, and commit only if the human agrees.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
