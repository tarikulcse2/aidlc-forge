---
name: step
description: AI-DLC step-by-step mode. Work out the single next lifecycle step across open CRs, ask before running it, run only that step, then stop. Use when someone asks "what's next" in an aidlc project.
argument-hint: [CR-NNN]  (default: the oldest open CR)
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

Run **one step** of the lifecycle in step-by-step mode. A human approves every step.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.
If the config is missing, the next step is `/aidlc-forge:init`.

## 1. Where are we? (read only)
Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/portfolio.sh"`. Focus on **$ARGUMENTS**, or on the oldest open CR.
Choose the **first** of these that applies:

| # | State | Step |
|---|---|---|
| 1 | Any gate is `auto` | **Ratify:** show what auto mode decided (the decision rows `Decided by Claude (auto mode)`, ADRs, units built) and ask, gate by gate, "Ratify the <phase> gate for CR-NNN?". Yes → `approved`, with the human's name and date. No → ask what to change, and route to the matching phase skill. |
| 2 | gate_requirements `pending` and `request.md` exists | Show the requirements gate summary and ask for approval (as in `/aidlc-forge:requirements` step 7) |
| 3 | `status: planning`, no `units.md` yet | `/aidlc-forge:planning CR-NNN` |
| 4 | gate_planning `pending` and `units.md` exists | Show the planning gate summary and ask for approval |
| 5 | `status: implementation` | `/aidlc-forge:implementation next` (one unit) |
| 6 | `status: testing` | `/aidlc-forge:testing all` |
| 7 | `status: deploy`, gate_deploy `pending` | `/aidlc-forge:deploy staging` |
| 8 | gate_deploy `approved` (deployed), or `n/a` with status `deploy` (e.g. the CR-000 baseline from discovery, once ratified) | `/aidlc-forge:close CR-NNN` |
| 9 | No open CRs | Say so. Suggest `/aidlc-forge:requirements <idea>`, `/aidlc-forge:planning <spec>` when the requirements are already written, `/aidlc-forge:bug-fix <bug>` for a bug, `/aidlc-forge:quick <change>` for a small change, `/aidlc-forge:acceptance-criteria <idea>` to draft ACs first, or `/aidlc-forge:discovery` if `docs/baseline/` is empty |

## 2. Ask before running it
Tell me in at most 5 lines: where we are, the step (the exact skill and its argument), and what it will change.
Ask **"Run this step?"** and wait.

## 3. Run only that step
Follow that skill's `SKILL.md` in `${CLAUDE_PLUGIN_ROOT}/skills/<name>/`, including its own questions and gates.
Don't continue into the following step.

## 4. Report
The result (tests and counts, files changed), and the next step as one command.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
