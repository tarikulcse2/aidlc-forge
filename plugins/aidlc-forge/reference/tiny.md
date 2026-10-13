# Tiny changes run inline

Read this only in `bug-fix`, `quick` and `implementation`. Config: `tiny_change_lines` (default 30; `0` = off).

**Only when a human is driving** (`bug-fix`, `quick`, or `implementation` typed by hand or via `step`). **Never in
AUTO MODE:** there, every unit goes to the agents, so the main session's context stays small for the rest of the run.
In those cases, for `bug-fix`, `quick` and **S units** in `implementation`, decide before starting whether the change is **tiny**:
- you expect ≤ `tiny_change_lines` changed lines (production and test code together)
- it doesn't touch authentication, authorization, secrets, personal data, the data model, migrations or the API contract

**Tiny → do it yourself in the main session. Don't start the tester, coder or code-reviewer agents.**
1. Write the failing test(s) named `USnnn_ACk_<Behaviour>`, and run `test_story`: they must be red for the right reason.
2. Write the code, and run `test_story` until it's green (same attempt limit as the coder).
3. **Self-check** your diff, and fix anything that fails:
   - every AC in scope has a test
   - error codes and status codes match the contract
   - null, empty and boundary input are handled
   - no existing test was weakened
   - no debug code is left, and the change follows the existing patterns
4. Continue with the skill's next step (record, test phase, commit) exactly as before.

**Not tiny, or it grows past the limit while you work?** Stop doing it inline: hand the unit to the coder (then
the code-reviewer), and pass it what's done so far.
Record `mode: inline` or `mode: agents` in the metrics row.
