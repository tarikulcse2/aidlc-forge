# Changelog

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
