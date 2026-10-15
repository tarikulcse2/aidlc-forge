# Changelog

## 3.6.1 (2026-10-13)
- **Agent rows show token counts:** each aidlc-forge agent's row (`agent-rows.ps1`) ends with its token count, as
  Claude Code's default row does: `coder · CR-007-… U-13 … · green after 2 attempt(s) · 01:37 · 12.4k tokens`.
  Numbers always use a dot (`12.4k`, `1.2M`), whatever the Windows language setting.
- A row too long for the panel now shortens its label instead of cutting off the end, so the running time, token
  count and status always stay visible.
- Re-run `/aidlc-forge:init` in each project to copy the new `scripts/aidlc/agent-rows.ps1`.

## 3.6.0 (2026-10-13)
Faster small CRs. Based on TestApp-aidlc's progress log: writing the code took only 10–20% of a unit's time, and
the rest was fixed per-unit overhead (agent start-up and re-reading ~50 s, review ~45–65 s, bookkeeping ~25 s).
- **Fewer units:** the planner estimates the whole change. If it's ≤ `small_change_lines` (new config key, default
  150) and ≤ 5 production files, it plans **one unit**, never split by layer. It splits only for independent or risky
  parts (auth, security, migrations, the contract) or bigger changes. The `units.md` header records
  `Estimate: ~<n> lines, <n> files`.
- **One combined review:** a small CR that is still split gets `Review: combined`. Only its last unit triggers a
  review, which covers the whole CR in one pass (`<handle> review: whole CR`). Others keep a review per unit, and
  older `units.md` files default to per unit. The code-reviewer's turn limit is now 20 (was 15).
- **Faster planning:** under `balanced`, small standard CRs (≤ 2 stories, no package, persistence, auth or
  contract-versioning decision) are planned on **Sonnet**, not Opus. The planner skips the options table, and
  `design.md`, when there's no real decision.
- **Traceability once per CR:** `implementation` regenerates `docs/traceability.md` only after the last unit.
- Expected effect: a CR-007-sized change (3 units) goes from ~15 to ~6–8 minutes.

## 3.5.0 (2026-10-13)
Live progress inside Claude Code itself, not only in a second terminal.
- **Status line** (`templates/scripts/statusline.sh`, copied by `init`): one line at the bottom of Claude Code, e.g.
  `aidlc ▶ CR-006-admin-login · implementation · U-12 Sign-out (2/3) · coder: green after 1 attempt · 00:16:40`.
  - It refreshes every 3 s (`refreshInterval`), so it keeps updating while the session waits for an agent.
  - It warns after 10 quiet minutes, shows `🏁 … GREEN in …` for 30 minutes after the run, and shows nothing
    outside aidlc projects.
  - It reads `.aidlc/progress.log` and `state.yaml`; no AI.
- **Agent rows** (`templates/scripts/agent-rows.ps1`, Claude Code's `subagentStatusLine`): each running aidlc-forge
  agent's row shows its role, label, the latest `PROGRESS` line it wrote itself for its unit, and running time, e.g.
  `coder · CR-006-admin-login U-12 Sign-out · green after 1 attempt(s) · 02:14`. Other agents keep their default row.
- **`init`** copies both scripts and, after asking, writes `statusLine` and `subagentStatusLine` into the personal
  `.claude/settings.local.json`, with absolute paths. A plugin can't set a status line itself, and
  `${CLAUDE_PLUGIN_ROOT}` isn't documented for these commands. It warns when this would replace your own status line.

## 3.4.2 (2026-10-13)
Completion time for every step, unit and run.
- **`progress.sh` calculates durations:** `STEP DONE`, `UNIT DONE`/`UNIT STOP` and `RUN COMPLETE` get ` in HH:MM:SS`,
  measured from the matching `STEP START` (same step), `UNIT START` (same U-NN) or `RUN START`. Only lines since the
  last `RUN START` count, so an earlier run never matches. It prints the logged line, and the session uses that
  duration (never its own estimate).
- **Chat lines** carry the durations: `✔ planning: 3 units in 00:03:02`, `🏁 RUN COMPLETE: GREEN in 00:18:52`.
- **`watch.ps1`** ends with the total (RUN START → RUN COMPLETE), the slowest step and the slowest unit.
- **`auto-run-report.md`** gets a timing line: the total, each step's duration, and the slowest unit. `RUN COMPLETE`
  is now logged before the report is written, so the report can use its duration.
- **The `implementation` command** always logs `UNIT START` and `UNIT DONE`/`UNIT STOP` itself (also when run by
  hand), and writes `duration=HH:MM:SS` into the metrics row.
- **Unattended runner:** `Claude finished in …` (from Claude Code's `duration_ms`), `Total time : …` (the whole run,
  including its own regression), `AUTO RUN: GREEN in …`, the duration in the notification title,
  `RUNNER VERDICT … in …`, and `duration=` in the metrics run row.

## 3.4.1 (2026-10-13)
Finer progress while a run is going.
- **Agents log progress:** during `auto` and `custom-workflow` runs, agents get a `PROGRESS: <handle> U-NN` tag and
  write `PROGRESS` lines with `progress.sh`:
  - the tester: tests red
  - the coder: tests red, green after n attempts, each failed attempt
  - the code-reviewer: its verdict
  - devops: each readiness area
  - discovery-analyst: each area documented

  So a long unit no longer looks frozen in `watch.ps1`. The planner and analyst have no shell; the main session
  brackets their steps.
- **Chat progress lines:** after each event, the session prints one line (`▶ U-02 Outbox table (2/5)`, `✅ …`, `⛔ …`,
  `🧪 GREEN 73/73`, `🏁 RUN COMPLETE: GREEN`), so the chat reads as a progress log between agent runs.
- **Unattended runner:** shows agents' `PROGRESS` lines live, while still hiding their other internal steps.
- `watch.ps1` shows the last 12 events (was 10). The code-reviewer's shell rule allows the progress line.

## 3.4.0 (2026-10-13)
Real-time progress for full runs.
- **Progress log:** a new `scripts/progress.sh` appends timestamped events to `.aidlc/progress.log`. `auto` and
  `custom-workflow` record `RUN START`, `STEP START`/`STEP DONE`, `UNIT START`/`UNIT DONE`/`UNIT STOP`, `TESTS`,
  `HARD STOP` and `RUN COMPLETE`. Logging never fails a run.
- **Live view `scripts/aidlc/watch.ps1`** (copied by `init`): refreshes every few seconds with the active CR (handle
  and ticket), status, gates, units (⏳/🔨/✅/⛔), elapsed time and the latest events. It ends with
  `RUN COMPLETE: GREEN / RED / HARD STOP` and a beep. Options: `-Seconds`, `-Once`, `-Notify`. No AI involved.
- **Unattended runner (`aidlc-auto.ps1`):**
  - live output via `stream-json`: agent starts with their labels, progress events in colour, edits and commands;
    sub-agents' internal steps are hidden
  - the full stream is saved as `claude-stream.jsonl` in the run folder
  - after the independent regression it writes a `RUNNER VERDICT` event
  - a **Windows notification** at the end (`-NoNotify` turns it off)
- `init` adds `.aidlc/progress.log` to `.gitignore`. All PowerShell scripts are pure ASCII, so they read correctly
  in Windows PowerShell 5.1.

## 3.3.2 (2026-10-13)
- **Security:**
  - Commands' `allowed-tools` changed from `Bash(bash:*)` to `Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*)`. The old
    rule pre-approved any command starting with `bash`, including `bash -c "<anything>"`.
  - The unattended runner no longer allows `bash` at all, and now denies `bash -c *` and `sh -c *`. Claude Code
    doesn't look inside wrapped strings, so `bash -c "git push"` would have got around the `git push` deny rule.
- **Tester effort `medium`** (was `low`). Since 1.8.0 it handles only L units, the hardest ones.
- **CI:** the shared workflow and the project template default to .NET `10.0.x` (the current LTS; .NET 9 goes out of
  support in Nov 2026). `init` now fills in `solution`, `dotnet-version` (from `TargetFramework`) and `docker` (only
  with a Dockerfile). The README notes the private-repo setting for sharing the workflow.
- **Descriptions corrected:**
  - `implementation` no longer claims a unit-level regression run
  - `coder`: TDD mode covers S and M units, plus lite, quick and bug-fix CRs
  - `requirements` points bugs to `bug-fix` and small changes to `quick`
- Re-run `/aidlc-forge:init` in onboarded projects to refresh `scripts/aidlc/aidlc-auto.ps1`.

## 3.3.1 (2026-10-12)
- **Agent labels:** every agent is started with a `description` that names what it works on, shown in Claude Code's
  agent list while it runs: coder `<handle> U-NN <unit title>`, tester `… tests: …`, code-reviewer `… review: …`,
  requirements-analyst `<handle> requirements: <CR title>`, planner `<handle> planning: <CR title>`, devops
  `<handle> deploy readiness`, discovery-analyst `Discovery: <area>` (≤ 70 characters; the title is shortened, never
  the handle). Rule in `reference/core.md`.

## 3.3.0 (2026-10-12)
**CR naming: number plus title.**
- Every CR has a **handle** `CR-NNN-<slug>` (e.g. `CR-005-admin-login`): **3-digit** numbers (was 2) and a 2–4 word
  kebab-case slug. It names the folder and the branch (`aidlc/<handle>`), and it's shown in status, portfolio,
  traceability and reports. `state.yaml` gets `handle:` and an optional `ticket:`. Commit scopes stay short:
  `feat(CR-005 U-12)`.
- **Ticket keys** from Jira, Azure DevOps, GitHub or Linear are recorded (`ticket: PROJ-123`) and shown next to the handle.
- **Arguments:** a CR can be named by its full handle, `CR-005`, `CR-5`, `CR-05`, or its slug.
- **No clashes:** the next number also checks `base_branch` in git repos.
- **Scripts:** a new `cr_dirs` helper sorts CRs numerically (so `CR-01` comes before `CR-006`), and `cr_label`
  shows the handle plus ticket. `portfolio.sh` and `trace.sh` use both.
- **Backward compatible:** older `CR-NN-<slug>` folders keep their names and work everywhere. The discovery
  baseline is now `CR-000-baseline` for new projects.
- Templates and docs use `CR-NNN`, and examples use 3-digit IDs.

## 3.2.0 (2026-10-12)
- New config key **`auto_deploy`** (default `on`). With `auto_deploy: off`, `/aidlc-forge:auto` skips the deploy step and stops
  after testing, with the CR at status `deploy` (run `/aidlc-forge:deploy` later). `custom-workflow` and the unattended
  runner with `-Phases` are unaffected; the runner without `-Phases` follows the setting, since it calls `auto`.

## 3.1.1 (2026-10-12)
- Renamed `/aidlc-forge:customer-workflow` to **`/aidlc-forge:custom-workflow`** (you choose your own steps).

## 3.1.0 (2026-10-12)
- **New `/aidlc-forge:custom-workflow`:** the previous `auto` behaviour. A step picker (Plan steps: Requirements and
  Planning; Build steps: Implementation, Testing and Deploy) and an implementation brief, then only the chosen steps
  run without stopping. `--phases a,b` skips the picker.
- **Changed `/aidlc-forge:auto`:** no picker and no questions. It runs **every remaining step** (requirements →
  planning → implementation → testing → deploy) from the CR's status. The command text is the implementation brief.
  It asks only if nothing was typed. `--phases` moved to `custom-workflow`.
- **Unattended runner** (`scripts/aidlc/aidlc-auto.ps1`): with no `-Phases` (or `-Phases all`) it calls
  `/aidlc-forge:auto`. With specific `-Phases`, it calls `/aidlc-forge:custom-workflow --phases …`. Re-run
  `/aidlc-forge:init` in onboarded projects to refresh the runner.
- Agents follow a `BRIEF:` from either command. The naming convention, the CLAUDE.md template and the README are updated.

## 3.0.0 (2026-10-12)
**Breaking: the plugin is renamed from `aidlc` to `aidlc-forge`,** to match the marketplace.
- Commands: `/aidlc:<name>` → **`/aidlc-forge:<name>`** (e.g. `/aidlc-forge:quick`)
- Agents: `aidlc:<name>` → **`aidlc-forge:<name>`** (e.g. `aidlc-forge:coder`)
- Install ID: `aidlc@aidlc-forge` → **`aidlc-forge@aidlc-forge`**
- Plugin folder: `plugins/aidlc/` → `plugins/aidlc-forge/`. Release tags: `aidlc--vX.Y.Z` → `aidlc-forge--vX.Y.Z`.
- **Unchanged (project data):** the `.aidlc/` config folder, `aidlc/CR-NN-…` branch names, the CLAUDE.md
  `<!-- aidlc:start -->` / `<!-- aidlc:end -->` markers, and `scripts/aidlc/*.ps1`. Already-onboarded projects keep
  working after their settings and managed files are updated.
- **Upgrading a project:** in `.claude/settings.json`, change `enabledPlugins` to `"aidlc-forge@aidlc-forge": true`,
  then re-run `/aidlc-forge:init` to refresh the CLAUDE.md block and `scripts/aidlc/*.ps1` (the runner calls
  `/aidlc-forge:auto`).

## 2.0.0 (2026-10-12)
`/aidlc-forge:acceptance-criteria` merged with the standalone **AcceptanceCriteriaSkill**. It keeps the plugin's lifecycle
integration and adds the skill's way of producing ACs.
- **Sources:** a ticket link or key (Jira, Azure DevOps, GitHub, Linear; fetched via a connected tool, `az`/`gh`, or
  the web, including comments and linked issues; the user pastes it on a login page; never asks for credentials),
  a description, a document, or existing code. Plus `US-NNN` and `CR-NN` for review.
- **Four levels:** Business (3–6 plain ACs), Functional (the default), Technical (`## Technical criteria`: API, data,
  security, side effects, contract changes) and QA (a `.feature` file tagged `@US-NNN @ACn`, scenario names prefixed
  `USnnn_ACk`, reusing existing step wording). One picker asks the source and level, and only what's missing.
- **Grounded in the code:** narrows to the right module, extracts real roles, limits, messages, codes and
  endpoints, and detects duplicates (proposes Changed ACs). Scaled to the level; an Explore agent only for large
  codebases. Never copies secrets.
- **Provenance:** `[from code: path:line]`, `[ASSUMPTION]`, **Conflicts** (the requirement versus the code) and
  **Open questions**.
- **Coverage:** an 8-point list (adds side effects and non-functional), plus a fresh-tester self-review with a
  vague-word list and story-split advice.
- **Progressive disclosure:** a 2.6k-token command, plus `references/levels.md`, `project-analysis.md` and
  `examples.md`, read only at the step that needs them.
- **Config:** new keys `ac_default_level`, `ac_language`, `ticket_system`, `ticket_base_url`, `bdd_framework` and
  `feature_dir` in `.aidlc/config.yaml` (no separate settings file). `init` detects them.
- **Planning import:** Business drafts get status and error codes added as `(assumed)`. Draft Conflicts and Open
  questions are shown at the combined approval. Technical criteria are kept in `request.md` for the planner.
- **Breaking:** the command now asks for the source and level when they're missing, and saved drafts may include
  Technical criteria, Conflicts and Open questions sections.

## 1.9.0 (2026-10-12)
- **New `/aidlc-forge:acceptance-criteria <idea | spec file | US-NNN | CR-NN>`:** writes or reviews ACs only, without
  starting a lifecycle phase. Runs in the session, with no agents.
  - **Draft mode:** at most one round of ≤ 5 questions, then stories with Given/When/Then ACs, using placeholder
    IDs `US-NEW1`… so drafts never clash with real IDs.
  - **Review mode:** a checklist (testable, observable result, status plus stable error code, edge cases, no
    duplicates or contradictions, ≤ 8 ACs per story, nothing invented), then a findings table and corrected ACs.
  - **Saves only on your yes:**
    - drafts to `docs/specs/<slug>.md`, and CR updates to `request.md`. Changing ACs after the gate resets
      `gate_requirements` to pending.
    - the baseline is never edited. Changes to agreed ACs become `docs/specs/change-us-NNN.md`.
- The requirements-analyst's IMPORT MODE replaces `US-NEW` placeholders with real IDs and keeps reviewed ACs word for word.
- `step` suggests the new command when no CR is open. A new "Authoring help" scope in the naming convention.

## 1.8.2 (2026-10-12)
- Renamed the marketplace from `ai-sdlc-plugins` to **`aidlc-forge`**. The install ID is now `aidlc-forge@aidlc-forge`. Commands
  (`/aidlc-forge:*`) and agent names are unchanged.

## 1.8.1 (2026-10-12)
- **P7, smaller core rules:** the tiny-change rules moved to `reference/tiny.md` (read only by `bug-fix`, `quick`
  and `implementation`), and the lean-document rules to `reference/docs.md` (read only by the analyst, the planner,
  `planning`, `quick` and `bug-fix`). `core.md`, which every command and agent reads, drops from about 2.2k to 1.6k tokens.

## 1.8.0 (2026-10-12)
Fewer turns, fewer agent starts, less output. Based on measured costs: the main session starts at about 37.8k
tokens, and each agent at about 8k.
- **P1, no duplicate CLAUDE.md:** agents already receive CLAUDE.md (verified), so the 4 agents that read it again
  no longer do. That saves about 1k tokens and a turn per agent run.
- **P2, batched reads:** every agent reads its files in **one parallel batch** in its first turn, and doesn't
  search for files the context pack names. Core rule: put independent reads in one turn, because every turn
  re-sends the whole context.
- **P3, short reports:** every agent's report is ≤ 10 lines, with no code, diffs or logs. Agent prompts pass IDs and
  paths, not file contents. Devops gets a report section.
- **P4, planner effort `medium`,** raised to `high` (the Agent tool's effort parameter) only for full-track CRs.
- **P5, one coder for S and M units:** the tester runs only for L units, which saves an agent start and a second
  read of the same files for every M unit.
- **P6, tiny inline only when a human drives:** never in auto mode, where every unit goes to the agents so the main
  context stays small for the whole run.

## 1.7.0 (2026-10-09)
Faster: fewer agent hand-offs and less over-thinking.
- **Tiny changes run inline** (new config `tiny_change_lines`, default 30; `0` = off).
  - `quick`, `bug-fix` and S units in `implementation` that change ≤ 30 lines, and don't touch
    auth, secrets, personal data, the data model, migrations or the contract, run in the main session.
  - They still write tests first and run the story's tests, then a **self-check** replaces the agents. No tester,
    coder or code-reviewer agents start.
  - Anything bigger, or that grows past the limit, hands over to the agents as before.
  - Metrics record `mode: inline` or `mode: agents`.
- **Effort per agent:** tester and devops `low`; coder, code-reviewer, requirements-analyst and discovery-analyst
  `medium`; planner `high`.
- **Turn limits per agent (`maxTurns`):** tester 20, devops 20, coder 40, code-reviewer 15, requirements-analyst 20,
  planner 30, discovery-analyst 60. An agent that hits its limit isn't restarted: it's a hard stop in auto mode, or
  a question in step mode.

## 1.6.0 (2026-10-09)
Lean documents: planning writes only what a later step reads.
- **New core rule "Lean documents".** Never written into files: thinking or option debates (options go in chat;
  files get the chosen option plus one line of why), Q&A transcripts, restated baseline text, intent essays,
  assumption lists, risks or diagrams that aren't real, progress narratives, template guidance, empty sections, or "N/A".
- **Leaner templates:**
  - `request.md`: 37 → 20 lines. No intent section, scope block, NFR table or guidance note; decisions are one line.
  - `design.md`: 25 → 14 lines. No options column, flows or risks placeholders.
  - `units.md`: no summary table (each unit appeared twice). A 4-line context pack, with the status in the heading.
  - `adr.md`: 20 → 7 lines. Options become a single "Rejected" line.
- **Optional files:** `design.md` only when there's a decision, a contract change or a data change. ADRs only
  for hard-to-reverse decisions (packages, persistence, auth, contract versioning, public patterns).
- **New limits:** `request.md` ≤ 80 lines (was 200), `design.md` ≤ 60 (was 200), ADR ≤ 12, a 4-line context pack.
  Test report ≤ 8 lines when GREEN. Auto-run report ≤ 30 lines.
- **Agents updated:** requirements-analyst and planner write lean; planning verifies no debate or empty section
  was written; status reads units from their headings.

## 1.5.5 (2026-10-09)
- Renamed the `devops-engineer` agent to **`devops`**.

## 1.5.4 (2026-10-09)
- Renamed the `test-engineer` agent to **`tester`**.

## 1.5.3 (2026-10-09)
- Renamed the `software-engineer` agent to **`coder`**.

## 1.5.2 (2026-10-09)
- Renamed the `planning-architect` agent to **`planner`**.

## 1.5.1 (2026-10-09)
- Renamed the `solution-architect` agent to **`planning-architect`**, after the `/aidlc-forge:planning` phase it owns
  (like `requirements` → `requirements-analyst`).

## 1.5.0 (2026-10-09)
`/aidlc-forge:auto` lets you choose the steps and describe how to implement.
- **Step picker:** a multi-select list in two groups:
  - **Plan steps:** Requirements, Planning
  - **Build steps:** Implementation, Testing, Deploy

  Each option describes how that step will be done. Only the remaining steps are offered. A choice that skips a
  needed earlier step is caught, with one question.
- **Implementation brief:** after the picker, auto asks how you want the change implemented (approach, constraints,
  patterns to follow, or "defaults"). It's saved in the CR's `request.md` under `## Implementation brief (requester)`
  and passed to every agent as `BRIEF:`. The requirements-analyst, solution-architect, test-engineer and
  software-engineer follow it, and say when an AC, ADR or core rule overrides it.
- Runs **only the selected steps**, then stops. The final report lists the steps that weren't run, and suggests
  `/aidlc-forge:auto continue` for them.
- `--phases a,b` skips the picker. The unattended runner gets a new `-Phases` parameter (default `all`) and always passes it.
- After the setup questions (step picker and brief), the run never asks anything.

## 1.4.0 (2026-10-09)
No duplicate test runs or reviews while a workflow runs.
- **Full suite once, after implementation.**
  - Units run only their own tests (`test_story`), to see them fail first and then pass.
  - The whole suite runs once in `/aidlc-forge:testing all` after the last unit, not after each unit or step.
  - `bug-fix` and `quick` do the same: their one full run is the testing step.
  - Auto mode: if that run is RED, the failing stories are fixed and the suite runs once more (at most
    `auto_max_attempts` rounds).
- **The Stop hook is skipped while a CR is in `implementation`.** It still guards direct, ad-hoc edits.
- **`test-all.sh` reuses by default:** a still-valid green run is reused. `--fresh` forces a run, and `--reuse`
  is still accepted.
- **software-engineer:** no `build`, `test_fast` or `test_all` inside its loop, only the story tests.
- **One review per unit:** after fixes, the follow-up review checks only the fixed findings and the fix's diff.
  The code-reviewer never runs builds or tests.
- **Deploy:** no second code review (only config, CI, container and infrastructure), and the devops-engineer
  uses the test report instead of re-running tests.
- **`run-regression.ps1`:** runs one command (`test_all` by default) instead of build, then fast, then all.
- `testing`: `all --fresh` replaces `all --reuse`, and only stories that need attention are shown from `trace.sh`.

## 1.3.0 (2026-10-09)
Lower token cost.
- **`cost_profile` in `.aidlc/config.yaml`** (`economy` | `balanced` | `quality`; default `balanced`). The
  requirements-analyst, solution-architect and code-reviewer agents now default to Sonnet. Commands pass Opus only
  where the profile asks for it:
  - `balanced`: full-track requirements, standard and full planning, and reviews of changes of 150+ lines
  - `quality`: always Opus
  - `economy`: never Opus
  - `init` asks which profile to use.
- **Rules split:** `reference/process.md` (about 3,000 tokens, read by 10 commands and 3 agents) is replaced by
  `core.md` (read by everyone) plus `tracks.md`, `state.md` and `git.md`, which are read only when a step needs
  them. The context-pack format lives in `templates/units.md`.
- **`/clear` reminder:** in step mode, every phase and unit report ends with
  "Tip: run /clear before the next step. Everything it needs is in the files."
- README: new "Keeping token cost down" section.
- Fixed a misplaced line in the old rules ("Status and portfolio use haiku" had ended up inside the entry list).

## 1.2.1 (2026-10-09)
- Renamed `/aidlc-forge:fix` to **`/aidlc-forge:bug-fix`**, and the CR track value from `fix` to **`bug-fix`**, so the command,
  `state.yaml`, `/aidlc-forge:status` and `/aidlc-forge:portfolio` all use the same name.

## 1.2.0 (2026-10-09)
Faster small work: about 7 stops and 3–4 full test runs become 1 stop and 1 run.
- **New `/aidlc-forge:quick <small change>`:** one story, ≤ 3 ACs, one unit, no contract, data or package change. It
  records the ACs, implements test-first, runs a right-sized review and one full test run, then asks "Commit?".
  Bigger changes are routed to `/aidlc-forge:planning`. New `quick` track.
- **Full suite once:** new `scripts/test-all.sh`.
  - It runs `test_all`, prints a compact result plus failure details, writes the log to
    `.aidlc/last-test-all.log`, and records green runs.
  - `--reuse` returns the recorded green result when no code changed since (measured on LeaveManagement:
    0.4 s instead of 13 s).
  - The testing phase no longer runs `test_fast` before `test_all`.
  - Implementation, bug-fix, quick and auto all reuse the engineer's green run.
- **Right-sized review:** changes under `review_small_lines` (new config key, default 150) are reviewed by Sonnet;
  larger ones still by Opus.
- **No plan stop for S units** in `/aidlc-forge:implementation`. M/L units still ask.
- The Stop hook and `test-all.sh` share the "changed since" logic, so a green full run also satisfies the hook.
- `requirements`, `planning` and `step` point small work to `/aidlc-forge:bug-fix` and `/aidlc-forge:quick`.
- `init` adds `.aidlc/last-test-all.*` to `.gitignore`.

## 1.1.2 (2026-10-09)
- Fixed: `/aidlc-forge:step` never offered `/aidlc-forge:close` for CRs whose deploy gate is `n/a`, such as the CR-00 baseline
  created by `/aidlc-forge:discovery`, so that baseline could get stuck.
- `/aidlc-forge:portfolio` now says "test report" instead of the old "regression report".

## 1.1.1 (2026-10-09)
- `/aidlc-forge:bug-fix` and `/aidlc-forge:planning`: short descriptions that fit the command menu, and clear argument hints shown after
  selecting the command (`<describe the bug: ...>`, `<describe what to plan, or a spec file path, or CR-NN>`).
- Selecting either command without a description now asks for it (planning asks only when no CR is waiting for planning).

## 1.1.0 (2026-10-09)
- **New `/aidlc-forge:bug-fix <bug>`:** goes from a bug report straight to a tested fix, with no analysis phase and no gate
  stops. It still records a bug-fix CR (track `bug-fix`), writes a reproducing test named after the affected story (red
  before the fix), runs an independent review and the full tests, then asks "Commit?". It routes to
  `/aidlc-forge:requirements` when the fix would change agreed behaviour, the contract, data or packages.
- **Direct planning:** `/aidlc-forge:planning <intent, ticket text or spec file>` imports the requirements in one step
  (the requirements-analyst's IMPORT MODE: no questions, gaps marked `(assumed)`), asks one combined approval, and
  continues straight into planning. `/aidlc-forge:planning CR-NN` works as before.
- New `bug-fix` track in the process rules. `step` suggests the shortcuts when no CR is open.
- Fixed: the requirements command set the status to the old `design` value instead of `planning`.

## 1.0.0 (2026-10-09)
First release, generalised from the LeaveManagement sample.
- 12 skills, named by scope:
  - project: init, discovery
  - lifecycle: requirements, planning, implementation, testing, deploy, close
  - modes: step, auto
  - views: status, portfolio
- 7 agents named `<area>-<role>`: requirements-analyst, solution-architect, test-engineer, software-engineer,
  code-reviewer, devops-engineer, discovery-analyst, each with a routed model
- CR status values and gate keys follow the phase names (`gate_requirements`, `gate_planning`, `gate_deploy`)
- Marketplace: `aidlc-forge`
- Config-driven hooks (format on edit, Stop test gate on `test_fast`)
- A change-request folder layout with a flat `state.yaml`. Tracks: lite, standard, full.
- Scripts: `trace.sh` (generated traceability), `portfolio.sh` (status across projects)
- Project templates: config, CR documents, runbook, CLAUDE.md section, runner scripts, CI caller
- Stack profiles: dotnet-webapi, generic
