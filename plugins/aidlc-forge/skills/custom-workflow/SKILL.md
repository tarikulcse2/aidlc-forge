---
name: custom-workflow
description: Choose which lifecycle steps run automatically - pick steps in a picker, describe how to implement, then the chosen steps run to the end without stopping. Never pushes, deploys or closes. (/aidlc-forge:auto runs every step with no picker.)
argument-hint: <describe the change and how to implement it> | continue [CR-NNN]   (optional: --phases implementation,testing)
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git status:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git config:*), Bash(git switch:*), Bash(git checkout -b:*), Bash(git add:*), Bash(git commit:*)
---

Run the **chosen** AI-DLC steps in **AUTO MODE** for: **$ARGUMENTS**

This is `/aidlc-forge:auto` with a step picker and an implementation brief: you choose which steps run. To run every
remaining step with no questions, use `/aidlc-forge:auto`.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` and `${CLAUDE_PLUGIN_ROOT}/reference/git.md`. Their modes,
hard stops, never-rules and git rules apply to the whole run. If `.aidlc/config.yaml` is missing, stop.

## 0. Set up the run: the only time you ask anything
**0a. Read the arguments.**
- `--phases <list>`: a comma-separated list from `requirements, planning, implementation, testing, deploy`, or `all`.
  When it's given, **skip 0c** (the unattended runner always passes it).
- `continue` or `continue CR-NNN`: resume that CR, or the oldest open CR. Anything else is the description of a new
  change request.

**0b. Work out the remaining steps.**
- New CR: all five steps (planning is skipped later if the track turns out to be lite).
- Existing CR: the steps from its `state.yaml` status onward. Don't offer steps that are already done.

**0c. Show the step picker.** Use the **AskUserQuestion** tool with `multiSelect: true`, and offer only the remaining
steps. Each option's description says **how that step will be done**:
- Question 1, header `Plan steps`: "Which planning steps should run automatically?"
  - **Requirements:** requirements-analyst writes the stories and acceptance criteria, answering its own questions
    with defaults; the gate is marked 🤖 for you to ratify.
  - **Planning:** planner chooses the recommended design and writes ADRs, contract changes and context-packed
    units; the gate is marked 🤖.
- Question 2, header `Build steps`: "Which build steps should run automatically?"
  - **Implementation:** for each unit in order: tests first, then code (only the unit's own tests run), one
    review, and a local commit.
  - **Testing:** the one full-suite run after all units; failing stories are fixed and the suite re-run (at most
    `auto_max_attempts` rounds); writes the test report.
  - **Deploy:** readiness table and release notes for staging. It never deploys; the gate is marked 🤖.

Each question needs 2–4 options. If a group has only one remaining step, put it in the other question. If only one
step remains in total, skip the picker and say in one line which step will run.

**0d. Check the selection** against the entry rules in `${CLAUDE_PLUGIN_ROOT}/reference/state.md`. Selected steps run
in lifecycle order. If a selected step needs an earlier step that is neither done nor selected (for example,
Implementation without Planning on a standard CR), ask once: *"Implementation needs Planning first. Add Planning, or
run only up to <last runnable step>?"*

**0e. Get the implementation brief.** If the arguments don't already describe the change, ask in plain text:
> Describe the change and how you want it implemented: the approach, constraints, and patterns or files to follow.
> Reply "defaults" to let Claude decide.

For `continue`, ask instead: *"Any implementation notes for this run? (or 'none')"*

**0f. Record and confirm.**
- Write the brief into the CR's `request.md` under `## Implementation brief (requester)`, dated, appending if the
  section already exists. Create the CR first if it's new (step 1 does that).
- Print the plan in ≤ 8 lines: the CR, the steps that will run (✔) and won't (✘), the brief in one line, and the
  `cost_profile`.
- **Then start. Ask nothing more until the final report.**

## Rules for the run (after step 0)
1. Never ask the human anything. Wherever a skill says "Step mode: ask/wait", follow its AUTO MODE branch instead.
2. Start every subagent prompt with `AUTO MODE.`, followed by `BRIEF: <the implementation brief>` (unless it's "defaults").
3. Gates become `auto`, never `approved`.
4. Before each step, re-read the CR's `state.yaml`. Run **only the selected steps**, in order. Stop after the last
   selected one.

## Steps (follow each skill's SKILL.md in `${CLAUDE_PLUGIN_ROOT}/skills/`)
| # | Step | Runs while status is | Until |
|---|---|---|---|
| 1 | `requirements` (new CR only) | – | `request.md` written, gate_requirements `auto` |
| 2 | `planning` (standard/full) | `planning` | `units.md` written, gate_planning `auto`, status `implementation` |
| 3 | `implementation`, repeated for every unit in dependency order | `implementation` | every unit ✅, status `testing` |
| 4 | `testing all`: **the one full-suite run** (units ran only their own tests). If RED: `coder` fixes each failing story (story tests only), then `testing all` runs once more. At most `auto_max_attempts` rounds, then a hard stop. | `testing` | GREEN, status `deploy` |
| 5 | `deploy staging` | `deploy` | readiness table and release notes written, gate_deploy `auto` |

`close` is never run in auto mode.

**Parallel units** (only when config has `parallel_units: on` and this is a git repo): units in the same parallel
group whose context packs don't share files can run as concurrent `coder` subagents, each with
worktree isolation. Merge each finished worktree into the CR branch one at a time. On any merge conflict, stop
doing parallel work and implement the remaining units one after another.

## Hard stops
Follow the hard stops in core.md. On a hard stop, finish the bookkeeping (unit ⛔, a metrics row), then go to the report.
Don't continue with other units, because they may depend on the one that stopped.

## Final report
Write `docs/ops/auto-run-report.md` (≤ 30 lines; leave out anything empty or already recorded elsewhere) and print the same summary:
- the steps selected, and each one's outcome (✅, 🤖, or ⛔ with the reason and evidence), plus the steps not selected
- the brief, and anything in it that couldn't be followed (with the reason)
- **decisions made by Claude** that a human must review, with links to the decision rows and ADRs
- units implemented, with commits (hashes), and the test totals
- next human actions: run `/aidlc-forge:step` to ratify the 🤖 gates, review the branch diff, open a PR, or run
  `/aidlc-forge:custom-workflow continue` (or `/aidlc-forge:auto continue`) for the remaining steps
