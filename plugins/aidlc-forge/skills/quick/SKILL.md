---
name: quick
description: Make a small change directly - one story, up to 3 ACs, test-first, review (tiny changes run inline), full tests, then asks to commit. No analysis or approval stops.
argument-hint: <describe the small change and the expected behaviour>
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git status:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git config:*), Bash(git switch:*), Bash(git checkout -b:*)
---

Make this small change: **$ARGUMENTS**

**No description given?** If the change text above is empty, ask:
> Describe the small change: what should the system do differently, for whom, and what's the expected result?

Wait for the answer and use it. Don't start any other step before then.

Running this command is the human's request, so there are no requirements or planning stops. The only question
is at the end: whether to commit. Speed comes from doing each thing **once**: one agent writes the tests and code,
one right-sized review, one full test run.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.
If the config is missing, stop and suggest `/aidlc-forge:init`.

## 1. Open a quick CR
- **Handle** (core.md: CR naming): next `CR-NNN`, a 2–4 word slug, so `CR-NNN-<slug>`; folder `docs/changes/<handle>/`.
- **Branch** (git repos): `aidlc/CR-NNN-<words>` from `base_branch`. Create it if `git status --porcelain` is
  empty. Otherwise ask once: "Create the branch and carry your uncommitted changes over, or work on the current branch?"
- **`state.yaml`** from `${CLAUDE_PLUGIN_ROOT}/templates/state.yaml`:
  - `id`, `handle`, `ticket` (if any), track `quick`, status `implementation`
  - `gate_requirements: approved`, `gate_requirements_by: <git user name> (via /aidlc-forge:quick)`, today's date
  - `gate_planning: n/a`, `units_total: 1`

## 2. Locate (narrow)
Find the code path and its tests with `Grep` and `Glob`, and the story it belongs to (`docs/baseline/stories.md`,
open CRs, or `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh"`). Read only what's relevant.

## 3. Scope check: is it really small?
**Stop and route to `/aidlc-forge:planning <the same description>`** (explain why in 2 lines) if any of these apply:
- more than **3** new or changed ACs, or more than **one** story
- the API contract, the data model, or a package would change
- more than one unit of work (roughly more than 5 production files), or a design decision worth an ADR
- authentication or authorization design, or anything security-sensitive

If it's really a bug (the code contradicts an agreed AC), switch to `/aidlc-forge:bug-fix` instead.

## 4. Record it (short; no approval stop; rules: `${CLAUDE_PLUGIN_ROOT}/reference/docs.md`)
- **`request.md`** (≤ 25 lines):
  - `# CR-NNN: <title>`
  - **Change:** one paragraph
  - **Story:** an existing `US-NNN`, or a new one numbered after the highest existing ID
  - **ACs:** a Given/When/Then table. Changed existing ACs show their new text, marked *(CR-NNN)*.
  - **Design note:** 2–4 lines
- **`units.md`:** one unit `U-NN` (next free number) with a context pack (format: `${CLAUDE_PLUGIN_ROOT}/templates/units.md`), size S.
- Print the ACs as a short FYI (≤ 6 lines), then continue straight away.

## 5. Implement: inline if tiny, otherwise the `coder` agent in **TDD mode**
- **Tiny** (`${CLAUDE_PLUGIN_ROOT}/reference/tiny.md`): do it yourself, with tests first, the story's tests only, and the
  self-check. **Skip step 6.**
- **Otherwise:** the `coder` agent in TDD mode. Tests named `USnnn_ACk_<Behaviour>`, red first, then the code.
  Existing tests change only for ACs marked *(CR-NNN)*. It loops on the story's tests (`test_story`) only, with no
  full suite here.

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
- Append to `.aidlc/metrics.csv`: track `quick`, size S, mode `inline` or `agents`.
- Propose the commit message `feat(CR-NNN): <summary> [US-NNN]`, and ask **"Commit?"** Commit only on yes. Never push.

## 9. Report (≤ 12 lines)
What changed, the ACs and their tests (red, then green), the test totals, the review verdict, and next:
`/aidlc-forge:deploy`, or open a PR.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
