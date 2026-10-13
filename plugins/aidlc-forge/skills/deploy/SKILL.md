---
name: deploy
description: AI-DLC phase 5 (deploy). Prepare deployment readiness for CRs whose units are all done - container, CI, runbook, release notes - and run deploy gate. Never deploys.
argument-hint: [environment, e.g. staging | production]  (default staging)
---

Prepare a release to **$ARGUMENTS** (default `staging`). You never deploy: pipelines deploy after a human approves.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.

1. **Scope:** the CRs with `status: deploy`. If there are none, say so and stop.
2. **Regression:** `docs/ops/test-report.md` must be GREEN and newer than the last unit's commit (or the
   last change to the CR folder). Otherwise run `/aidlc-forge:testing all` first. If the result is RED, stop.
3. **Delegate** to the `devops` agent with the CRs in scope and the target environment.
4. **Security (no second code review):** the code-reviewer already checked every unit's code. Check only what no
   unit review saw: configuration, secrets handling, the container and CI files, and infrastructure changed for
   this release. Copy any Critical or security findings from the unit reviews into the runbook's readiness table.
5. **Deploy gate summary:** the readiness table, with blockers (❌) first.
   - Step mode: ask **"Approve deploy gate for <CRs> to <environment>?"** On yes, set `gate_deploy: approved`, `gate_deploy_by`
     and `gate_deploy_date` in each CR's `state.yaml`.
   - AUTO MODE: set `gate_deploy: auto` (a human approves the real deployment in the pipeline).
6. **Next step:** the human merges the CR branch through a PR, and the pipeline deploys.
   After deployment: `/aidlc-forge:close CR-NNN`.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
