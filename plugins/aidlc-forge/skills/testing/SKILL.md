---
name: testing
description: AI-DLC phase 4 (testing). Run the full regression with the configured test commands, map results to stories, find AC gaps and weakened tests, write docs/ops/test-report.md, and move a CR from testing to deploy when GREEN. Use when asked to test, run regression, or check that nothing broke.
argument-hint: [all | all --fresh | fast | US-NNN]  (default all)
model: sonnet
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*), Bash(git diff:*), Bash(git merge-base:*), Bash(git status:*)
---

Run the testing phase for **$ARGUMENTS** (default `all`). This is read-only for code and tests: **never edit
source or test files here.** You run, analyse and report. Use it at any time as a regression check, too.

**Setup:** `.aidlc/config.yaml` gives the commands. If it's missing, stop and suggest `/aidlc-forge:init`.

1. **Run** the tests. This phase is **the one full-suite run** after implementation. Units only ran their own tests.
   - `all`: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/test-all.sh"`. It runs `test_all` once and prints only a compact
     result plus failure details (the full log is in `.aidlc/last-test-all.log`). If a green run already exists
     and no code changed since, it reuses that result instead of running again.
   - `all --fresh`: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/test-all.sh" --fresh`. Always runs, for example after an
     environment change.
   - `fast`: `test_fast` from config (it builds). `US-NNN`: `test_story` with `{ID}` replaced by `USNNN`.
   Never run `test_fast` before `test_all`: the fast tests are a subset. If the build fails, report RED with the errors.
2. **Map:** `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" | grep -E "❌|🟡|Summary|unknown"` (only what needs attention)
   gives stories → tests. For each failing test, give
   its story (from the name), expected vs actual, and a classification: *code bug*, *test bug*, *environment*,
   or *intended change* (its AC is marked as changed in an open CR).
3. **Protected tests** (git repos): protected-test check from `${CLAUDE_PLUGIN_ROOT}/reference/git.md`, against `base_branch`. Without git, report "skipped (no git)".
4. **Write** `docs/ops/test-report.md`, replacing the previous one. Lean: when GREEN, only the header table (≤ 8 lines). When RED, add only the sections that have content (≤ 40 lines), and never write empty sections:
   ```
   # Test report
   | | |
   |---|---|
   | Date | <UTC date-time> |
   | Scope | <scope> |
   | Verdict | GREEN or RED |
   | Totals | <passed>/<total> passed, <failed> failed, <skipped> skipped |
   ## Failures        (test, story, expected vs actual, classification, suggested fix)
   ## Story coverage  (only stories that are ❌ or 🟡 in trace.sh output)
   ## Protected tests (OK, ⚠ list, or skipped)
   ## Commands run
   ```
5. **Advance:** if the scope was `all` (with or without `--fresh`), the verdict is GREEN and the protected-test check is OK (or skipped),
   set every CR with `status: testing` to `status: deploy` (and update `updated`).
6. Finish with the verdict, and the single next action: `/aidlc-forge:deploy` if GREEN, otherwise the fix to make
   (for example *"Fix the code bug in X with `/aidlc-forge:implementation U-NN`"*).

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
