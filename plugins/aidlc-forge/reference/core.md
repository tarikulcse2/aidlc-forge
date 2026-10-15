# AI-DLC core rules (aidlc-forge plugin 3.6.1)

Every aidlc skill and agent reads this file once per session. Detail files are read **only when a step needs them**:
`tiny.md` (tiny changes run inline), `docs.md` (lean documents),
`tracks.md` (tracks, naming, which entry to use), `state.md` (state.yaml, status flow, gates, phase entry),
`git.md` (branches, commits, protected-test check). All are in `${CLAUDE_PLUGIN_ROOT}/reference/`.

## Files
`.aidlc/config.yaml` (flat `key: value`) · `.aidlc/metrics.csv` · `docs/baseline/` (approved truth: prd, stories,
nfr, architecture, `api/` contract, `adr/`) · `docs/changes/CR-NNN-<slug>/` (`state.yaml`, `request.md`,
[`design.md`], `units.md`) · `docs/ops/` (runbook, test-report, release-notes) · `docs/traceability.md` (generated).
- The baseline changes only through `/aidlc-forge:close` or `/aidlc-forge:discovery`. Exception: ADRs and the API contract are
  updated at planning time, contract first.
- CR documents hold the **delta** only.

## IDs
`CR-NNN` (CR-000 is the discovery baseline) · `US-NNN` (unique across baseline and CRs) · `AC1..` per story ·
`NFR-NN` · `ADR-NNN` · `U-NN` (unique per project). Each next ID = highest existing + 1.

**CR naming: the handle `CR-NNN-<slug>`**, e.g. `CR-005-admin-login`.
- **Number:** 3 digits, zero-padded. Next = the highest number among `docs/changes/CR-*` folders + 1, read
  numerically, so older 2-digit folders like `CR-05-…` count as 5. In a git repo, also check `base_branch`
  (`git ls-tree --name-only <base_branch> docs/changes/`) so a parallel branch's number isn't reused.
- **Slug:** 2–4 lowercase kebab-case words from the title (bug-fix: `fix-<words>`).
- **The handle is the name people see:** the folder (`docs/changes/<handle>/`), the branch (`aidlc/<handle>`),
  `handle:` in `state.yaml`, and every summary, report and table. Short `CR-NNN` is used only where space is tight:
  commit scopes (`feat(CR-005 U-12): …`) and `id:`.
- **Ticket:** if the work came from a ticket (Jira, Azure DevOps, GitHub, Linear), record `ticket: <key>` in
  `state.yaml` and show it after the handle (`CR-005-admin-login (PROJ-123)`).
- **Finding a CR from an argument:** accept the full handle, `CR-005`, `CR-5`, `CR-05`, or the slug alone
  (`admin-login`). Match the folder by number, ignoring zero padding, or by slug. If two folders match, ask.
- **Older CRs** (`CR-NN-…`, with no `handle:`) keep their names. Their handle is the folder name. Don't rename them.
Tests are named `US006_AC04_<Behaviour>`. Legacy tests are mapped under a story with `Covered by: A, B`.

## Status and gates (details: `state.md`)
`requirements → planning → implementation → testing → deploy → closed`. Lite, bug-fix and quick CRs skip planning.
Gate values: `pending` | `auto` (🤖, needs ratifying) | `approved` (only on a human's explicit yes) | `n/a`.

## Modes
- **Step** (`/aidlc-forge:step`, or any phase run by hand): ask before each step, stop at gates, never run on into the next step.
- **Auto** (`/aidlc-forge:auto`): never ask. Take defaults, record each as `Decided by Claude (auto mode)`, set gates to
  `auto`, and prefix every subagent prompt with `AUTO MODE.`
- **Hard stops** (auto mode; stop and report, don't work around):
  - tests red after `auto_max_attempts` attempts
  - an unfixable Critical review finding
  - an existing test would change for an AC that isn't marked as changed
  - a new package, a security issue, or a change outside the context pack
  - a contradiction with an accepted ADR
  - a dirty working tree when the CR branch is needed

## Never
- Push, deploy, merge into `base_branch`, or commit on `base_branch`.
- Weaken, skip or delete a test to get to green.
- Invent requirements.
- In auto mode: edit `.claude/`, `CLAUDE.md` or `.aidlc/config.yaml`, or close a CR.

## Model routing (config `cost_profile`; default `balanced`)
When you start one of these agents, **pass the `model` from this table** (the Agent tool's model parameter).
The agent files default to `sonnet`.

| Agent | `economy` | `balanced` | `quality` |
|---|---|---|---|
| requirements-analyst | sonnet | opus for track `full`, otherwise sonnet | opus |
| planner | sonnet | opus for full CRs and for standard CRs with a real design decision; **sonnet** for small standard CRs (≤ 2 stories, no new package, persistence, auth or contract-versioning decision) and a lite CR's single unit | opus |
| code-reviewer | sonnet | sonnet if the change is under `review_small_lines` (default 150) lines, otherwise opus | opus |
| tester, coder, devops, discovery-analyst | sonnet | sonnet | sonnet |

Count changed lines with `git diff --numstat` (against the CR branch point, plus uncommitted changes), or from the
engineer's report without git. The `status` and `portfolio` skills run on haiku.

**Effort and turn limits** are set in each agent's file:
- `low`: devops
- `medium`: tester, coder, code-reviewer, requirements-analyst, discovery-analyst, planner
- Start the planner with **`effort: high`** (the Agent tool's effort parameter) only for **full-track** CRs.

**Starting agents cheaply:**
- **Prompts are short.** Pass IDs and paths (CR folder, unit ID, mode, brief), not file contents, CLAUDE.md or
  these rules: agents read what they need.
- **Agents read in one parallel batch, and don't search** for files a context pack names.
- **Reports are ≤ 10 lines,** with no code, diffs or logs. Don't ask agents for more, and don't paste their reports
  into files.
- **Label every agent with what it's working on.** The Agent tool's `description` is what people see in the agent
  list while it runs. Always use these formats (≤ 70 characters; shorten the title, never the handle or unit):

  | Agent | `description` |
  |---|---|
  | coder | `<handle> U-NN <unit title>`, e.g. `CR-003-todo-description U-05 Description field` |
  | tester | `<handle> U-NN tests: <unit title>` |
  | code-reviewer | `<handle> U-NN review: <unit title>` (a follow-up: `… re-review`) |
  | requirements-analyst | `<handle> requirements: <CR title>` |
  | planner | `<handle> planning: <CR title>` |
  | devops | `<handle> deploy readiness` (several CRs: `Deploy readiness: CR-003, CR-004`) |
  | discovery-analyst | `Discovery: <area or project>` |

  The unit title is the text after `U-NN` in the unit's `### U-NN <title>` heading in `units.md`; the CR title is
  `title:` in `state.yaml`. Fixing failures from the testing phase: `<handle> fix: <failing story or test>`.
- **Tiny changes** (≤ `tiny_change_lines`, nothing sensitive, a human driving) run inline without agents: see
  `${CLAUDE_PLUGIN_ROOT}/reference/tiny.md` (read only by `bug-fix`, `quick` and `implementation`).

If an agent stops because it reached its turn limit (`maxTurns`), don't restart it with the same prompt. In auto
mode that's a hard stop. In step mode, report where it stopped and ask how to continue.

## Speed and size
- **Read narrowly, and in batches:** the config, the stack profile, this file, and the unit's context pack (or the
  CR folder). CLAUDE.md is already loaded, so never read it again. Never "all docs". Read a detail file only when a
  step names it. Put independent reads in **one parallel turn**, because every turn re-sends the whole context.
- **Lean documents:** files hold only what a later step reads. Before writing any CR document or report,
  read `${CLAUDE_PLUGIN_ROOT}/reference/docs.md` (sizes, what never goes in a file).
- **Tests: no duplicate runs.**
  - **During implementation:** each unit runs only its own tests (`test_story`), to see them fail first and then pass.
    No full suite per unit or per step.
  - **Once at the end:** the full suite runs once in `/aidlc-forge:testing all`, after the last unit. It goes through
    `bash "${CLAUDE_PLUGIN_ROOT}/scripts/test-all.sh"`, which also reuses a still-valid green run. If it's RED, fix
    the failures with story tests, then run the suite once more.
  - **No one else runs tests:** the reviewer and the devops engineer never run tests. They use the test report.
  - **The Stop hook** (`test_fast`) is skipped while a CR is in `implementation` and when no code changed. It
    remains the safety net for direct, ad-hoc edits.
  - Never run `test_fast` and `test_all` back to back.
- **Reviews: once per unit.** After fixes, the follow-up review covers only the findings and the fix's diff. The deploy
  phase doesn't review code again; it checks only config, CI, container and infrastructure.
- **Generated, not written:** `docs/traceability.md` comes from `scripts/trace.sh`. Metrics rows
  (`date,cr,unit,track,size,mode,result,attempts,tests_added,notes`) are appended after each unit.
- **Few stops:** S units show their plan without waiting. `bug-fix` and `quick` stop only at "Commit?".
- **Fresh context:** in step mode, end every phase or unit report with:
  `Tip: run /clear before the next step. Everything it needs is in the files.`
  (Not in auto mode.)
