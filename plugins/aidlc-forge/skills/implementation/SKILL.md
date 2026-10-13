---
name: implementation
description: AI-DLC phase 3 (implementation). Implement one unit of work as a test-first bolt - failing tests, code, one independent review, commit (only the unit's own tests run; the full suite runs once in testing). Use when asked to build or implement a unit (U-NN) of an aidlc project.
argument-hint: <U-NN | next>
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git status:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git config:*)
---

Implement unit **$ARGUMENTS** (`next` = the first ⏳ unit whose dependencies are all ✅, in the CR with status `implementation`).

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.

1. **Check.** Find the unit in `docs/changes/*/units.md`. The CR's planning gate (gate_planning, or gate_requirements for lite, bug-fix and quick) must be
   `approved`, or `auto` in an auto run, and every dependency must be ✅. Otherwise stop. Set the unit's status to 🔨.
2. **Plan** (≤ 10 lines: files, ACs, contract impact).
   - **Size S:** show the plan as information and continue. No stop.
   - **Size M/L, step mode:** wait for OK.
   - AUTO MODE: continue without waiting.
3. **Tests and code:**
   - **tiny S unit, not in AUTO MODE** (`${CLAUDE_PLUGIN_ROOT}/reference/tiny.md`): do it yourself, with tests first, the unit's tests only,
     and the self-check. No agents, and **skip step 4**.
   - size **S** or **M**, or a lite, bug-fix or quick CR: `coder` agent in **TDD mode** (one agent, not two)
   - size **L** only: `tester` agent, then the `coder` agent (the tests are worth a separate pass)
   - Pass the CR folder, unit ID and mode. Prefix `AUTO MODE.` in auto runs.
   - The coder runs only this unit's tests (`test_story`). **The full suite is not run per unit.** It runs
     once, in the testing phase after the last unit.
4. **Review (only when an agent wrote the code; model per core.md: Model routing):** `code-reviewer` agent, with the model the routing table gives
   for the config's `cost_profile` and the size of the change. Review **once**. If there are Critical findings:
   - have `coder` fix them (with the unit's tests only)
   - then run a **follow-up review** that checks only those findings and the fix's diff (not the whole unit again)
   - at most two fix rounds. Still Critical: ⛔ hard stop in auto mode, or ask the human in step mode.
5. **No full test run here.** The full suite and the protected-test check run once, in `/aidlc-forge:testing`.
6. **Record:**
   - Set the unit to ✅ in `units.md` and `units_done` + 1 in `state.yaml`. If every unit is done, set status `testing`.
   - `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" > docs/traceability.md`
   - Append a row to `.aidlc/metrics.csv` (create the header if the file is missing): date, cr, unit, track,
     size, mode, result, attempts, tests_added, notes.
7. **Commit** (git repos), with the message `feat(CR-NNN U-NN): <title> [US-xxx, ...]`.
   - AUTO MODE: commit locally on the CR branch. Never push.
   - Step mode: propose the message and commit only if the human says yes.
8. **Report:**
   - an AC → test → ✅/❌ table
   - files changed
   - test commands with their counts
   - the review verdict
   - next: `/aidlc-forge:implementation next`, or `/aidlc-forge:testing all` when every unit is done

On a hard stop: set the unit to ⛔, append a metrics row with result `hard-stop`, and report the reason and the evidence.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
