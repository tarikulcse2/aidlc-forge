---
name: bug-fix
description: Fix a bug directly - reproducing test, fix, review (tiny fixes run inline), full tests, then asks to commit. No analysis or approval stops.
argument-hint: <describe the bug: what happens, and what should happen instead>
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git status:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git config:*), Bash(git switch:*), Bash(git checkout -b:*)
---

Fix this bug: **$ARGUMENTS**

**No description given?** If the bug text above is empty, ask:
> Describe the bug: what happens, what should happen instead, and how to reproduce it (if you know)?

Wait for the answer and use it as the bug description. Don't start any other step before then.

Running this command is the human's request for the fix, so there's no requirements or planning stop.
The only question is at the end: whether to commit.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.
If the config is missing, stop and suggest `/aidlc-forge:init`.

## 1. Open a bug-fix CR
- **Handle** (core.md: CR naming): next `CR-NNN`, slug `fix-<2–4 words>`, so `CR-NNN-fix-<words>`; folder `docs/changes/<handle>/`.
- **Branch** (git repos): `aidlc/CR-NNN-fix-<words>` from `base_branch`. Create it if `git status --porcelain` is
  empty. Otherwise ask once: "Create the branch and carry your uncommitted changes over, or fix on the current branch?"
- **`state.yaml`** from `${CLAUDE_PLUGIN_ROOT}/templates/state.yaml`:
  - `id`, `handle`, `ticket` (if any), track `bug-fix`, status `implementation`
  - `gate_requirements: approved`, `gate_requirements_by: <git user name> (via /aidlc-forge:bug-fix)`, today's date
  - `gate_planning: n/a`, `units_total: 1`

## 2. Locate (narrow)
- Find the code path and its existing tests with `Grep` and `Glob`. Read only what's relevant.
- Find the **affected story and AC**: search `docs/baseline/stories.md` and open CRs for the behaviour, or run
  `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh"`.

## 3. Scope check: is this really a fix?
**Stop and route to `/aidlc-forge:requirements Fix: ...`** (explain why in 2 lines) if any of these apply:
- an existing AC's text would have to change, meaning the code does what was agreed and the agreement is what's wrong
- the API contract, the data model, or a package would change
- the fix needs more than one unit of work (roughly more than 5 production files), or a design decision worth an ADR
- it touches authentication or authorization design, rather than a plain bug in it

If no AC describes the expected behaviour yet, but the expected behaviour is unambiguous and contradicts no other
AC, add **one** AC to the affected story, marked *(CR-NNN)*. Otherwise stop as above.

## 4. Record it (short; rules: `${CLAUDE_PLUGIN_ROOT}/reference/docs.md`)
- **`request.md`** (≤ 20 lines):
  - `# CR-NNN: Fix <title>`
  - **Symptom**, **Expected**, **Actual**, **Reproduce** (steps or input)
  - **Affected:** US-NNN ACk (or the new AC)
  - **Root cause:** fill this in after step 5
- **`units.md`:** one unit `U-NN` (next free number) with a context pack (format: `${CLAUDE_PLUGIN_ROOT}/templates/units.md`), size S.

## 5. Reproduce, then fix: inline if tiny, otherwise the `coder` agent in **TDD mode**
**Tiny** (`${CLAUDE_PLUGIN_ROOT}/reference/tiny.md`): do the steps below yourself, run the self-check, and **skip step 6**.
**Otherwise:** the `coder` agent does them.
- It writes the regression test first, named `USnnn_ACk_Fix_<Behaviour>` (or `USnnn_Fix_<Behaviour>`).
  The test **must fail for the bug's reason.** If it passes, the bug isn't reproduced: stop and report what was tried.
- Then it makes the minimal fix, looping on the story's tests (`test_story`) only, until they're green. No full
  suite here.
- Fill in "Root cause" in `request.md` (1–2 lines).

## 6. Review once: only when step 5 used the coder (model per core.md: Model routing)
Run the `code-reviewer` agent with the model the routing table gives for the config's `cost_profile` and the
size of the change. If there are Critical findings, have `coder` fix them, then run a follow-up review
of only those findings and the fix's diff. At most two rounds. If a Critical finding remains, stop and report.

## 7. Test: the one full run
Set status `testing`, then follow `${CLAUDE_PLUGIN_ROOT}/skills/testing/SKILL.md` with scope `all`. This is the
only full-suite run. It writes `docs/ops/test-report.md` and moves the CR to `deploy` when GREEN. If it's RED,
have `coder` fix the failures (story tests only), then run `all` once more. At most two rounds.

## 8. Record and commit
- Set the unit ✅ and `units_done: 1`.
- `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" > docs/traceability.md`
- Append to `.aidlc/metrics.csv`: track `bug-fix`, size S, mode `inline` or `agents`.
- Propose the commit message `fix(CR-NNN): <summary> [US-NNN]`, and ask **"Commit?"** Commit only on yes. Never push.

## 9. Report (≤ 12 lines)
Root cause, the files changed, the reproducing test (red before the fix, green after), the test totals, the
review verdict, and next: `/aidlc-forge:deploy`, or open a PR.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
