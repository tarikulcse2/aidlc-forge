---
name: auto
description: Run every remaining lifecycle step automatically - requirements, planning, implementation, testing, deploy (unless auto_deploy is off) - with no questions and no stops. Never pushes, deploys or closes. (To choose the steps, use /aidlc-forge:custom-workflow.)
argument-hint: <describe the change and how to implement it> | continue [CR-NNN]
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git status:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git config:*), Bash(git switch:*), Bash(git checkout -b:*), Bash(git add:*), Bash(git commit:*)
---

Run **every remaining** AI-DLC step in **AUTO MODE** for: **$ARGUMENTS**

No step picker and no questions: it runs from the CR's current status through deploy, then reports. To choose which
steps run, or to be asked for an implementation brief, use `/aidlc-forge:custom-workflow`.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` and `${CLAUDE_PLUGIN_ROOT}/reference/git.md`. Their modes,
hard stops, never-rules and git rules apply to the whole run. If `.aidlc/config.yaml` is missing, stop.

## 0. Start (no questions)
- **`continue` or `continue CR-NNN`:** resume that CR, or the oldest open CR, from its `state.yaml` status.
- **Anything else:** the text is both the new change request **and the implementation brief** (approach,
  constraints, patterns). Start at step 1.
- **Empty:** this is the only question auto ever asks: *"Describe the change (and, optionally, how to implement it)."*
  Wait for the answer, then start.
- If the text has implementation notes, write them into the CR's `request.md` under
  `## Implementation brief (requester)`, dated (after step 1 creates the CR).
- Print the plan in ≤ 5 lines: the CR, all remaining steps (✔), deploy as ✘ if `auto_deploy: off`, the brief in one
  line, and the `cost_profile`. Then start.

## Rules for the run
1. Never ask the human anything. Wherever a skill says "Step mode: ask/wait", follow its AUTO MODE branch instead.
2. Start every subagent prompt with `AUTO MODE.`, followed by `BRIEF: <the implementation notes>` if there are any.
3. Gates become `auto`, never `approved`.
4. Before each step, re-read the CR's `state.yaml`. Run **every remaining step** in order, and skip only those already done.
5. **`auto_deploy: off`** in `.aidlc/config.yaml`: skip step 5 (deploy). The run ends after testing, with the CR at
   status `deploy`. Any other value, or no key: run it.

## Steps (follow each skill's SKILL.md in `${CLAUDE_PLUGIN_ROOT}/skills/`)
| # | Step | Runs while status is | Until |
|---|---|---|---|
| 1 | `requirements` (new CR only) | – | `request.md` written, gate_requirements `auto` |
| 2 | `planning` (standard/full; lite skips it) | `planning` | `units.md` written, gate_planning `auto`, status `implementation` |
| 3 | `implementation`, repeated for every unit in dependency order | `implementation` | every unit ✅, status `testing` |
| 4 | `testing all`: **the one full-suite run** (units ran only their own tests). If RED: `coder` fixes each failing story (story tests only), then `testing all` runs once more. At most `auto_max_attempts` rounds, then a hard stop. | `testing` | GREEN, status `deploy` |
| 5 | `deploy staging` (skipped when `auto_deploy: off`) | `deploy` | readiness table and release notes written, gate_deploy `auto` |

`close` is never run in auto mode.

**Parallel units** (only when config has `parallel_units: on` and this is a git repo): units in the same parallel
group whose context packs don't share files can run as concurrent `coder` subagents, each with worktree isolation.
Merge each finished worktree into the CR branch one at a time. On any merge conflict, stop doing parallel work and
implement the remaining units one after another.

## Hard stops
Follow the hard stops in core.md. On a hard stop, finish the bookkeeping (unit ⛔, a metrics row), then go to the report.
Don't continue with other units, because they may depend on the one that stopped.

## Final report
Write `docs/ops/auto-run-report.md` (≤ 30 lines; leave out anything empty or already recorded elsewhere) and print the same summary:
- each step's outcome (✅, 🤖, or ⛔ with the reason and evidence)
- the brief, and anything in it that couldn't be followed (with the reason)
- **decisions made by Claude** that a human must review, with links to the decision rows and ADRs
- units implemented, with commits (hashes), and the test totals
- next human actions: run `/aidlc-forge:step` to ratify the 🤖 gates, review the branch diff, open a PR (with
  `auto_deploy: off`: run `/aidlc-forge:deploy` when you're ready to release), and run
  `/aidlc-forge:close` after deployment
