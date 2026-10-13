# aidlc-forge: an AI-Driven Development Life Cycle plugin for Claude Code

`aidlc-forge` runs your software lifecycle with Claude Code: **requirements → planning → implementation → testing →
deploy → close**. Claude does the work, you approve at a few gates, and every change is recorded, tested and
traceable. One plugin serves every project; each project keeps only a small config file and its documents.

**Names at a glance:**
| Thing | Name |
|---|---|
| Marketplace and plugin | `aidlc-forge` (install ID `aidlc-forge@aidlc-forge`) |
| Commands | `/aidlc-forge:<name>`, e.g. `/aidlc-forge:quick` |
| Agents | `aidlc-forge:<name>`, e.g. `aidlc-forge:coder` |
| Project data (unchanged since 1.x) | `.aidlc/config.yaml`, `aidlc/CR-NNN-…` branches, `scripts/aidlc/*.ps1`, `<!-- aidlc:start -->` markers in CLAUDE.md |

```
requirements ──► planning ──► implementation ──► testing ──► deploy ──► close
     │              │          (per unit)          │           │         │
 requirements    planning     tests → code →     one full    deploy    merge into
 gate            gate         review → commit    suite run   gate      baseline
```

Version 3.3.2. See [CHANGELOG.md](CHANGELOG.md).

**What's new (1.6 → 3.3.2)**
| Version | Change |
|---|---|
| 3.3.2 | Security: commands pre-approve only the plugin's own scripts (was any `bash …` command); the unattended runner blocks `bash -c` and `sh -c`. Tester at `medium` effort. CI defaults to .NET 10, and `init` fills in the project's version. Corrected descriptions. |
| 3.3.1 | Agents are labelled in the agent list with what they work on: `<handle> U-NN <unit title>` (coder), `… review: …`, `<handle> planning: <title>`, and so on. |
| 3.3.0 | CR naming: the handle `CR-NNN-<slug>` (3 digits plus title) is shown everywhere, an optional `ticket:`, arguments by number or slug, and numeric sorting. Older `CR-NN` CRs keep working. |
| 3.2.0 | New config `auto_deploy: off`: `/aidlc-forge:auto` stops after testing (no deploy step). Default `on`. |
| 3.1.1 | Renamed `customer-workflow` to **`custom-workflow`** (no behaviour change). |
| 3.1.0 | New `/aidlc-forge:custom-workflow` (step picker + brief; runs only the chosen steps). `/aidlc-forge:auto` now runs **every** remaining step with no picker or questions. |
| 3.0.0 | **Plugin renamed to `aidlc-forge`:** commands are now `/aidlc-forge:…`, agents `aidlc-forge:…`, and the install ID is `aidlc-forge@aidlc-forge`. Project data (`.aidlc/`, `aidlc/CR-…` branches, CLAUDE.md markers) is unchanged. |
| 2.0.0 | `/aidlc-forge:acceptance-criteria` merged with the AcceptanceCriteriaSkill: ticket fetching (Jira, Azure DevOps, GitHub, Linear), four levels (Business, Functional, Technical, QA `.feature`), code-grounded facts with provenance, Conflicts and Open questions, an 8-point coverage list and a fresh-tester self-review. New `ac_*`, `ticket_*` and `bdd_*` config keys. |
| 1.9.0 | New `/aidlc-forge:acceptance-criteria`: draft or review ACs only, with a testability checklist; saves drafts to `docs/specs/` for `/aidlc-forge:planning` |
| 1.8.1 | Smaller core rules (2.2k → 1.6k tokens): tiny-change and lean-document rules moved to files read only where needed |
| 1.8.0 | Agents skip the duplicate CLAUDE.md read, read files in one parallel batch, and report in ≤ 10 lines. One coder for S and M units (tester only for L). Planner at `medium` effort (`high` only for full track). Tiny inline mode only when you drive, never in auto. |
| 1.7.0 | Tiny changes (≤ 30 lines) run inline with no agents; per-agent effort levels and turn limits |
| 1.6.0 | Lean documents: no thinking, debates or empty sections in files; smaller templates and size limits |

---

## Contents
1. [Requirements](#1-requirements)
2. [Install, update and uninstall](#2-install-update-and-uninstall)
3. [Quick start](#3-quick-start)
4. [Which command for which change](#4-which-command-for-which-change)
5. [Command reference](#5-command-reference)
6. [How it works: step, auto, planning and every command](#6-how-it-works-step-auto-planning-and-every-command)
7. [Core concepts](#7-core-concepts)
8. [Agents](#8-agents)
9. [Testing and quality](#9-testing-and-quality)
10. [Configuration reference](#10-configuration-reference-aidlcconfigyaml)
11. [Cost and speed](#11-cost-and-speed)
12. [Project files and folders](#12-project-files-and-folders)
13. [Git rules](#13-git-rules)
14. [Hooks and scripts](#14-hooks-and-scripts)
15. [CI](#15-ci)
16. [Stack profiles](#16-stack-profiles)
17. [Safety rules](#17-safety-rules)
18. [Troubleshooting and FAQ](#18-troubleshooting-and-faq)
19. [Plugin layout (for maintainers)](#19-plugin-layout-for-maintainers)

---

## 1. Requirements
| Need | Why |
|---|---|
| Claude Code 2.1 or later | Plugins, skills, agents and hooks |
| **Git Bash** (on Windows) | The hooks and scripts are bash |
| PowerShell 5.1+ or 7 | The project runner scripts (`scripts/aidlc/*.ps1`) |
| **git** (strongly recommended) | Branch per CR, local commits per unit, the protected-test check, parallel units |

---

## 2. Install, update and uninstall

**From a team git repo** (recommended):
```
claude plugin marketplace add YOUR-ORG/aidlc-forge
claude plugin install aidlc-forge@aidlc-forge --scope user
```
Or, inside Claude Code: `/plugin install aidlc-forge --marketplace YOUR-ORG/aidlc-forge`.

**From a local folder:**
```
claude plugin marketplace add "<path-to>/aidlc-forge"
claude plugin install aidlc-forge@aidlc-forge --scope user
```

**Scopes:**
- `--scope user` makes it available in every project on your machine. That's safe: the hooks do nothing in projects
  without `.aidlc/config.yaml`.
- `--scope project` enables it only for the current project.

**Teammates:** `/aidlc-forge:init` writes `extraKnownMarketplaces` and `enabledPlugins` into the project's
`.claude/settings.json`, so teammates get the plugin after they trust the folder.

**Load changes:** commands load when a session starts. After installing or updating, run `/reload-plugins` or start
a new session.

| Task | Command |
|---|---|
| Update from git | `claude plugin marketplace update aidlc-forge`, then `claude plugin update aidlc-forge@aidlc-forge` |
| Local folder | Nothing to update: edits apply at the next session or after `/reload-plugins` |
| Try plugin edits without installing | `claude --plugin-dir "<path>/plugins/aidlc-forge"` (terminal only) |
| Turn off temporarily | `claude plugin disable aidlc-forge@aidlc-forge` (`enable` to turn back on) |
| Uninstall | `claude plugin uninstall aidlc-forge@aidlc-forge` |
| See components and token cost | `claude plugin details aidlc-forge@aidlc-forge` |

### Upgrading from `aidlc` (2.x and earlier) to `aidlc-forge` (3.0.0)
Before 3.0.0, the plugin was called `aidlc` (commands `/aidlc:…`, install ID `aidlc@aidlc-forge`, and earlier
`aidlc@ai-sdlc-plugins`).
1. **Your machine:**
   - remove the old plugin: `claude plugin uninstall aidlc@aidlc-forge` (or `aidlc@ai-sdlc-plugins`)
   - update the marketplace: `claude plugin marketplace update aidlc-forge`
   - install the new one: `claude plugin install aidlc-forge@aidlc-forge --scope user`
2. **Each onboarded project:**
   - in `.claude/settings.json`, change `enabledPlugins` to `"aidlc-forge@aidlc-forge": true`
   - run `/aidlc-forge:init` to refresh the CLAUDE.md block and `scripts/aidlc/*.ps1`. The unattended runner now calls
     `/aidlc-forge:auto`.
3. **Run `/reload-plugins` or start a new session.**

Project data (`.aidlc/`, CR folders, branches, markers) needs no change. Old CR documents keep the old command names
as history.

### Upgrading to 3.1.x (`auto` and `custom-workflow`)
- **`/aidlc-forge:auto` now runs every remaining step with no questions.** To choose the steps (the old picker), use
  **`/aidlc-forge:custom-workflow`**. `--phases a,b` moved to `custom-workflow`.
- **Each onboarded project:** re-run `/aidlc-forge:init` to refresh `scripts/aidlc/aidlc-auto.ps1`. Without
  `-Phases` it calls `auto`; with `-Phases` it calls `custom-workflow --phases …`.
- Run `/reload-plugins` or start a new session.

### Upgrading to 3.2.x (`auto_deploy`)
- Nothing to do: `auto` still runs deploy by default (`auto_deploy` defaults to `on`).
- To make `auto` stop after testing in a project, add `auto_deploy: off` to its `.aidlc/config.yaml`. Projects
  onboarded with 3.2+ get the key (set to `on`) from `/aidlc-forge:init`.

### Upgrading to 3.3.x (CR handles)
- Nothing to do. Existing `CR-NN-<slug>` folders keep their names and work everywhere, and are now shown by
  folder name (e.g. `CR-05-admin-login`) instead of `CR-05`.
- New CRs get 3-digit handles (`CR-006-<slug>`), with `handle:` and an optional `ticket:` in `state.yaml`.
- Don't rename old CR folders: branches, commits and reports refer to them by their current names.
- **3.3.2 (security):** re-run `/aidlc-forge:init` in each onboarded project to refresh `scripts/aidlc/aidlc-auto.ps1`.
  The new runner no longer allows `bash` at all, and blocks `bash -c` and `sh -c`. Commands themselves need no
  change: they now pre-approve only the plugin's own scripts.

---

## 3. Quick start

**New project:**
```
git init
/aidlc-forge:init                       # config, CLAUDE.md block, permissions, scripts
/aidlc-forge:requirements <product idea>     # full track for a new product
/aidlc-forge:step                       # then one step at a time, /aidlc-forge:auto (all steps) or /aidlc-forge:custom-workflow (chosen steps)
```

**Existing project with code but no AI-DLC docs** (for example AuthApi, ProjectHub):
```
/aidlc-forge:init
/aidlc-forge:discovery                  # or one module at a time: /aidlc-forge:discovery src/Modules/Billing
/aidlc-forge:step                       # ratify the CR-000 baseline, then /aidlc-forge:close CR-000
```

**Project on the earlier in-repo sample layout** (`docs/01-requirements`, `.claude/commands/aidlc-*.md`):
```
/aidlc-forge:init                       # offers the migration and removes the old commands and hooks
```

**Daily use:**
```
/aidlc-forge:bug-fix Rejecting a request doesn't release the balance
/aidlc-forge:quick Show the manager's name on each leave request
/aidlc-forge:acceptance-criteria PROJ-123 technical                             # ACs from a ticket, grounded in the code
/aidlc-forge:acceptance-criteria Managers can delegate approvals to a deputy    # draft ACs → docs/specs/delegation.md
/aidlc-forge:planning docs/specs/delegation.md                                  # import those ACs and plan
/aidlc-forge:auto continue
/aidlc-forge:status
```

**Writing requirements yourself:** draft or review the ACs with `/aidlc-forge:acceptance-criteria` from a ticket, a
description, a document or existing code. Choose the level: **Business** for the PO, **Functional** for the team,
**Technical** for developers, or **QA** for a `.feature` file. Resolve its Conflicts and Open questions, save to
`docs/specs/`, then run `/aidlc-forge:planning docs/specs/<file>.md`. The ACs are imported word for word, with no question round.

---

## 4. Which command for which change
| Change | Use | Stops | Agents |
|---|---|---|---|
| Trivial: typo, config value, message | Ask Claude directly (the test-gate hook still protects you) | 0 | 0 |
| A bug | `/aidlc-forge:bug-fix <bug>` | 1 (commit) | 0 if tiny, otherwise coder + reviewer |
| A small change (1 story, ≤ 3 ACs) | `/aidlc-forge:quick <change>` | 1 (commit) | 0 if tiny, otherwise coder + reviewer |
| Just the acceptance criteria (draft or review), no lifecycle yet | `/aidlc-forge:acceptance-criteria <ticket, idea, file, US-NNN or CR-NNN>` | 1–2 (source/level, save?) | 0 (an Explore agent for large codebases at Technical/QA) |
| Requirements already written | `/aidlc-forge:planning <spec text or file>` | ~3 | analyst, planner, then per unit |
| Medium or large, defaults are fine | `/aidlc-forge:auto <change + how to implement>` (every step; `auto_deploy: off` skips deploy) | 0 | as needed |
| Medium or large, but only some steps automatic | `/aidlc-forge:custom-workflow <change>` | picker + brief | as needed |
| Large or risky | `/aidlc-forge:requirements` → `/aidlc-forge:step` … | every gate | as needed |

"Tiny" means ≤ `tiny_change_lines` (30) changed lines, with no auth, secrets, personal data, data model, migration or
contract change (see [§9](#9-testing-and-quality)).

---

## 5. Command reference
All commands are `/aidlc-forge:<name>`. **User-only** commands run only when you type them; Claude never starts them by itself.

### Project setup
| Command | Arguments | What it does |
|---|---|---|
| **`init`** (user-only) | `[stack]`, e.g. `dotnet-webapi` | Detects the stack and test layout, runs build and fast tests once, and proposes: `.aidlc/config.yaml` (asks your `cost_profile`), a managed `CLAUDE.md` block, permissions and plugin enablement in `.claude/settings.json`, `scripts/aidlc/*.ps1`, an optional `.github/workflows/aidlc-ci.yml`, `.gitignore` lines and the docs folders. Offers `git init`. Migrates the earlier sample layout. Always asks before writing; never commits. Re-run it to refresh managed files after a plugin update. |
| **`discovery`** (user-only) | `[area]`, default the whole repo | Brownfield onboarding. The discovery-analyst writes the **as-is baseline** as CR-000: stories with ACs observed in the code (each with its source `file:line`), existing tests mapped with `Covered by:`, observable NFRs, architecture, contract, existing decisions, and **unknowns and risks** (untested behaviour, suspected bugs that are reported but never fixed). It never changes code. Ratify with `/aidlc-forge:step`, then `/aidlc-forge:close CR-000`. |

### Lifecycle phases (one change request, in order)
| Command | Arguments | Status it handles | What it does |
|---|---|---|---|
| **`requirements`** | `<intent, feature, change or bug>` | – → `requirements` | Opens a CR named by its handle `CR-NNN-<slug>` (folder, branch, `state.yaml`, plus the ticket key if any), proposes a track, and points bugs and small changes to `bug-fix` or `quick`. The requirements-analyst asks ≤ 10 grouped questions with defaults, then writes a lean `request.md`. Ends at the **requirements gate**. |
| **`planning`** | `CR-NNN`, or `<intent / ticket text / spec file>` | `planning` | With `CR-NNN`: the planner shows options in chat, then writes `design.md` only if needed, ADRs only for hard-to-reverse decisions, the contract change first, and `units.md` context packs. Ends at the **planning gate**. With text or a file (**direct planning**): imports the requirements without questions (gaps marked `(assumed)`), asks one combined approval, then plans. With no argument and nothing to plan, it asks you to describe what to plan. |
| **`implementation`** | `<U-NN \| next>` | `implementation` | One unit, test-first. A tiny S unit runs inline when you drive (never in auto mode); otherwise S and M units use the coder in TDD mode, and L units use the tester then the coder. Only the unit's own tests run. One review, plus a follow-up limited to the findings. Records status, traceability and metrics, and commits locally (auto mode) or proposes a commit (step mode). Shows the plan for S units and waits for M/L units in step mode. |
| **`testing`** | `[all \| all --fresh \| fast \| US-NNN]` | `testing` → `deploy` | **The one full-suite run** after implementation (reuses a still-valid green run; `--fresh` forces one). Maps failures to stories, runs the protected-test check, and writes a lean `docs/ops/test-report.md`. Moves the CR to `deploy` when GREEN. Read-only for code. |
| **`deploy`** | `[staging \| production]` | `deploy` | Release readiness: the devops agent updates the container, CI, runbook and release notes, using the test report rather than re-running tests. Security covers only config, CI, container and infrastructure (code was reviewed per unit). Ends at the **deploy gate**. **Never deploys:** your pipeline does, after you approve. |
| **`close`** (user-only) | `<CR-NNN>` | → `closed` | Merges a delivered CR into `docs/baseline/` (stories, changed ACs, NFRs, a decision log line, the design delta) and marks its ADRs Accepted. Needs every unit ✅, a GREEN report, and the deploy gate approved or n/a. Never runs in auto mode. |

### Shortcuts into the lifecycle
| Command | Arguments | What it does |
|---|---|---|
| **`bug-fix`** (user-only) | `<what happens, what should happen>` (asks if empty) | Track `bug-fix`. Writes a ≤ 20-line fix note, reproduces the bug with a failing test **first** (if it can't reproduce it, it stops), fixes it minimally, then runs one review (or the self-check if tiny), the one full test run, and asks **"Commit?"**. If the fix would change agreed behaviour, the contract, data or packages, it routes you to `requirements`. |
| **`quick`** (user-only) | `<the small change and expected behaviour>` (asks if empty) | Track `quick`, for one story with ≤ 3 new or changed ACs. Writes a ≤ 25-line request, implements test-first (inline if tiny), reviews, runs the full suite once, and asks **"Commit?"**. Anything bigger is routed to `planning`. |
| **`planning <spec>`** | text or a file path | Direct planning (see above). |

### Authoring help (no lifecycle phase)
| Command | Arguments | What it does |
|---|---|---|
| **`acceptance-criteria`** | a ticket link or key, idea text, a document, existing code, `US-NNN` or `CR-NNN`; optional level (asks if empty) | Writes or reviews ACs **grounded in your code**, at **Business, Functional, Technical or QA** level (QA adds a `.feature` file). Fetches tickets from Jira, Azure DevOps, GitHub or Linear. Every rule is sourced (`[from code: path:line]`) or flagged (`[ASSUMPTION]`, Conflicts, Open questions); there's an 8-point coverage list and a fresh-tester self-review. Shows the result, then saves only on your yes: drafts to `docs/specs/`, feeding `/aidlc-forge:planning`. Never edits the baseline, opens a CR or starts a phase. See [§6.14](#614-acceptance-criteria-draft-or-review-acs-only). |

### Ways of running the lifecycle
| Command | Arguments | What it does |
|---|---|---|
| **`step`** | `[CR-NNN]` | Works out the **single next step** for the oldest (or given) open CR, says what it will do, asks "Run this step?", runs only that step, then stops. It also ratifies 🤖 gates set by auto mode. |
| **`auto`** (user-only) | `<change + how to implement>` or `continue [CR-NNN]` | Runs **every remaining step** (requirements → planning → implementation → testing → deploy) with **no picker and no questions**. With `auto_deploy: off` in the config, it stops after testing. Your text is also the implementation brief. See [§6.3](#63-auto-mode-aidlc-forgeauto-and-aidlc-forgecustom-workflow). |
| **`custom-workflow`** (user-only) | `<change + how to implement>` or `continue [CR-NNN]`; optional `--phases a,b` | Like `auto`, but first shows a **step picker** (choose which steps run) and asks for an **implementation brief**, then runs only the chosen steps without stopping. See [§6.3](#63-auto-mode-aidlc-forgeauto-and-aidlc-forgecustom-workflow). |

### Read-only views
| Command | Arguments | What it shows |
|---|---|---|
| **`status`** | – | This project: open CRs and gates, units of CRs in implementation, traceability gaps (❌/🟡 only), the last test result, and the next command. Runs on Haiku. |
| **`portfolio`** | `[folder]`, default the parent folder | Every onboarded project under a folder in one table, plus **Needs attention**: RED test runs, 🤖 gates waiting to be ratified, stale CRs, projects without a test report. Runs on Haiku. |

---

## 6. How it works: step, auto, planning and every command
This section walks through each workflow: **what you type, what happens, what you're asked, which files change,
and what comes next.** For a one-line summary of each command, see [§5](#5-command-reference).

### 6.1 The big picture
Every change is a **change request (CR)** that moves through the lifecycle. Each phase has an owner, and three
phases end at a **gate** where a human approves.

```
 you ──► requirements ──► planning ──► implementation ──► testing ──► deploy ──► close
          analyst          planner      tester/coder        full        devops     merge into
          (stories+ACs)    (design,     + code-reviewer     suite       (runbook,  baseline
                           units)       per unit            once        notes)
          ▼ gate           ▼ gate                                       ▼ gate
```

There are four ways to drive it:

| Way | You do | Best for |
|---|---|---|
| **Command by command** | type each phase command yourself, e.g. `/aidlc-forge:planning CR-004` | full control, learning the process |
| **Step mode** (`/aidlc-forge:step`) | type `/aidlc-forge:step` repeatedly; it works out the next command and asks before running it | not having to remember what's next |
| **Auto mode** (`/aidlc-forge:auto`) | type the change once; it runs every remaining step with no questions (deploy optional via `auto_deploy`) | medium or large work where defaults are fine |
| **Custom workflow** (`/aidlc-forge:custom-workflow`) | tick the steps and give a brief once; it runs only those, without stopping | when only some steps should run automatically |

There are also two **shortcuts** that skip analysis for small work: `/aidlc-forge:bug-fix` and `/aidlc-forge:quick`
([§6.10](#610-bug-fix-straight-to-a-tested-fix), [§6.11](#611-quick-a-small-change-in-one-go)). And there's one
**authoring helper** that sits outside the lifecycle: `/aidlc-forge:acceptance-criteria` drafts or reviews ACs before any
CR exists, from a ticket, description, document or existing code. The ACs are grounded in your code and written at
Business, Functional, Technical or QA level ([§6.14](#614-acceptance-criteria-draft-or-review-acs-only)).

The **state** of every CR lives in its `state.yaml`, so you can stop at any point, close Claude, `/clear`, or switch
machines, and carry on later. Nothing is kept only in the chat.

### 6.2 Step mode: `/aidlc-forge:step`
**You type:** `/aidlc-forge:step` (or `/aidlc-forge:step CR-004` to focus on one CR).

**What happens:**
1. It reads the status of every open CR (`portfolio.sh`, no AI cost) and picks the oldest CR, or the one you named.
2. It chooses the **first** rule that matches:

   | # | When the CR is… | The next step is… |
   |---|---|---|
   | 1 | any gate is 🤖 `auto` | **ratify** it: shows what auto mode decided and asks gate by gate. Yes → ✅. No → asks what to change. |
   | 2 | requirements written, gate pending | the requirements gate summary and approval |
   | 3 | status `planning`, no units yet | `/aidlc-forge:planning CR-NNN` |
   | 4 | units written, planning gate pending | the planning gate summary and approval |
   | 5 | status `implementation` | `/aidlc-forge:implementation next` (one unit) |
   | 6 | status `testing` | `/aidlc-forge:testing all` |
   | 7 | status `deploy`, deploy gate pending | `/aidlc-forge:deploy staging` |
   | 8 | deployed (or the CR-000 baseline, ratified) | `/aidlc-forge:close CR-NNN` |
   | 9 | no open CRs | suggests `requirements`, `planning <spec>`, `bug-fix`, `quick` or `discovery` |
3. It tells you in ≤ 5 lines where you are, the exact command, and what it will change, then asks **"Run this step?"**
4. On yes, it runs **only that step**, including that command's own questions and gates, then stops.
5. It reports the result and the next command, ending with *"Tip: run /clear before the next step."*

**Example session:**
```
/aidlc-forge:step   → "CR-004 is in requirements. Next: approve the requirements gate."  → yes
/clear
/aidlc-forge:step   → "Next: /aidlc-forge:planning CR-004"  → yes → choose an option → approve the planning gate
/clear
/aidlc-forge:step   → "Next: /aidlc-forge:implementation next (U-21)"  → yes → unit done, commit? → yes
… repeat until all units are done …
/aidlc-forge:step   → "Next: /aidlc-forge:testing all"  → GREEN
/aidlc-forge:step   → "Next: /aidlc-forge:deploy staging"  → approve the deploy gate
```

### 6.3 Auto mode: `/aidlc-forge:auto` and `/aidlc-forge:custom-workflow`
Both run lifecycle steps in **AUTO MODE**, without stopping at gates. The difference is how much you choose:

| | `/aidlc-forge:auto` | `/aidlc-forge:custom-workflow` |
|---|---|---|
| Which steps run | **every remaining step**, from the CR's status through deploy (or through testing with `auto_deploy: off`) | **only the steps you tick** in a picker |
| Questions before it starts | **none** (it asks only if you typed nothing) | the step picker, plus the implementation brief |
| Implementation brief | your command text | asked for (or taken from your text) |
| Unattended runner | `aidlc-auto.ps1` (default) | `aidlc-auto.ps1 -Phases a,b` |

**`/aidlc-forge:auto`: everything, no questions**
```
/aidlc-forge:auto Email the employee when leave is decided. Use an outbox table and reuse IEmailSender.
/aidlc-forge:auto continue             # resume the oldest open CR from its current status
/aidlc-forge:auto continue CR-004
```
1. With a description, it opens a new CR, and your text is also the **brief**. With `continue`, it resumes from the
   CR's status. With nothing typed, it asks once what to build.
2. It prints a ≤ 5-line plan, then runs **requirements → planning → implementation → testing → deploy**. It skips
   steps that are already done, and planning for lite CRs.
3. **To skip deploy in a project,** set `auto_deploy: off` in `.aidlc/config.yaml`. `auto` then stops after testing,
   with the CR at status `deploy`; run `/aidlc-forge:deploy` when you're ready to release. (Deploy never actually
   deploys anyway: it writes the readiness table and release notes.) For a single run, use
   `/aidlc-forge:custom-workflow` and leave Deploy unticked.

**`/aidlc-forge:custom-workflow`: you choose the steps**
```
/aidlc-forge:custom-workflow Email the employee when leave is decided
/aidlc-forge:custom-workflow continue CR-004
/aidlc-forge:custom-workflow --phases implementation,testing continue CR-004   # no picker
```
1. **Step picker:** two multi-select questions. Tick any combination:

   | Group | Option | How it will be done |
   |---|---|---|
   | Plan steps | Requirements | the analyst writes stories and ACs, answering its own questions with defaults; the gate becomes 🤖 |
   | Plan steps | Planning | the planner takes the recommended design and writes ADRs, the contract change and units; the gate becomes 🤖 |
   | Build steps | Implementation | each unit in order: tests first, then code (only the unit's tests run), one review, a local commit |
   | Build steps | Testing | the one full-suite run; failing stories are fixed and the suite re-run (≤ `auto_max_attempts` rounds) |
   | Build steps | Deploy | readiness table and release notes for staging; never deploys; the gate becomes 🤖 |

   Only the steps that are still left are offered. If you pick a step that needs an earlier one you didn't pick
   (e.g. Implementation without Planning), it asks once whether to add it.
2. **Implementation brief:** *"Describe the change and how you want it implemented: the approach, constraints, and
   patterns or files to follow."* Reply `defaults` to let Claude decide. For `continue`, it asks for optional notes.
3. **Plan summary:** the steps that will run (✔) and won't (✘), the brief, and the cost profile. Then it runs **only
   the chosen steps**, with no more questions.

**The run (both commands):**
- The brief is saved in `request.md` under `## Implementation brief (requester)` and passed to every agent as
  `BRIEF:`. Agents follow it, unless it contradicts an AC, an accepted ADR or a core rule; then they say so.
- Decisions are recorded as `Decided by Claude (auto mode)`, with rejected options on one line, so you can overturn them.
- Gates become 🤖 `auto`, never ✅. Commits are local, on the CR branch. It never pushes, deploys or closes.
- On a **hard stop** ([§17](#17-safety-rules)), it finishes the bookkeeping, marks the unit ⛔, and goes straight to the report.
- Every unit goes to the agents (tiny inline mode is off in auto runs), and agent reports are ≤ 10 lines, so the main
  session's context stays small for the whole run.
- Optional: independent units run in parallel worktrees when `parallel_units: on` and the project uses git.

**Afterwards:**
1. Read `docs/ops/auto-run-report.md`: each step's outcome, decisions Claude made, units and commit hashes, test
   totals (and, for custom-workflow, the steps not run).
2. Run `/aidlc-forge:step` to **ratify** each 🤖 gate (or ask for changes).
3. Review the branch diff and open a PR. Run `/aidlc-forge:custom-workflow continue` for steps you didn't select.

**Unattended:** `scripts/aidlc/aidlc-auto.ps1 -Intent "continue CR-004" -MaxBudgetUsd 10` runs `/aidlc-forge:auto`
headless. Add `-Phases implementation,testing` to run `/aidlc-forge:custom-workflow --phases …` instead (no picker).
It enforces limits through Claude Code permissions and re-runs the regression itself ([§14](#14-hooks-and-scripts)).

### 6.4 Requirements: `/aidlc-forge:requirements <intent>`
1. **Opens a CR** with its handle `CR-NNN-<slug>` (e.g. `CR-006-leave-emails`): the folder `docs/changes/<handle>/`,
   `state.yaml` (`id`, `handle`, and the `ticket` if your intent mentions one). See [§7](#cr-naming-number-plus-title).
2. **Proposes a track** (lite, standard or full) with a reason. If it's really a bug or a small change, it suggests
   `bug-fix` or `quick` and asks once whether to switch.
3. **Branch** `aidlc/CR-NNN-<slug>` (asks first; git only).
4. **The requirements-analyst asks you up to 10 questions**, grouped by topic, each with a suggested default.
   Answer them, or say "defaults".
5. It writes a lean **`request.md`**: new stories with Given/When/Then ACs, changed ACs with their full new text, and
   one-line decisions. Error ACs name the status code and a stable error code.
6. **Lite track:** the planner also writes the single unit now, because the requirements gate covers the design.
7. **Requirements gate:** a ≤ 15-line summary, then *"Approve requirements gate for CR-NNN?"* Yes → ✅ with your name
   and date, and the status moves to `planning` (lite: `implementation`).

**Next:** `/aidlc-forge:planning CR-NNN` (lite: `/aidlc-forge:implementation U-NN`).

### 6.5 Planning: `/aidlc-forge:planning`
There are two ways in.

**A. Plan an existing CR: `/aidlc-forge:planning CR-004`** (or no argument, for the CR waiting for planning)
1. Checks that the requirements gate is approved. A lite CR has nothing to plan.
2. **The planner** reads `request.md`, the architecture, the relevant ADRs and the contract, plus the key code files.
3. For each real decision it shows an **options table in chat** (2–3 options, pros and cons, a recommendation) and
   asks you to choose. The debate stays in chat; files only get the choice and one line of why.
4. It writes, only where needed:
   - **`design.md`** (≤ 60 lines): decisions, contract changes, data changes
   - **ADRs** (≤ 12 lines) only for hard-to-reverse decisions: packages, persistence, auth, contract versioning, public patterns
   - **the contract change first**, with its version bumped
   - **`units.md`**: one 4-line context pack per unit, with exactly which files to read, which ACs, what to change,
     and when it's done. Units are S or M; independent units share a parallel group.
5. Checks that **every AC is in exactly one unit**, and that no empty section or debate went into a file.
6. **Planning gate:** decisions, contract changes and units in order, then *"Approve planning gate for CR-004?"* Yes → ✅,
   and the status moves to `implementation`.

**B. Direct planning: `/aidlc-forge:planning <text or spec file>`**, for when the requirements already exist.
1. Reads the file (or the text). If it's really a bug or a small change, it suggests `bug-fix` or `quick`.
2. Opens a CR with its handle `CR-NNN-<slug>` (standard track, or full for a new product), and takes the ticket key from the source.
3. The analyst **imports** the requirements without asking questions. Gaps it had to fill are marked `(assumed)`.
4. **One combined approval:** the stories, every `(assumed)` item, and changed stories, then *"Approve the
   requirements and continue to planning?"*
5. On yes, it continues with steps 2–6 of A.

With no argument and nothing waiting for planning, it asks: *"Describe what you want to plan."*

**Next:** `/aidlc-forge:implementation next`, or `/aidlc-forge:auto continue` to implement every unit.

### 6.6 Implementation: `/aidlc-forge:implementation <U-NN | next>`
`next` picks the first ⏳ unit whose dependencies are all ✅. For each unit:

```
            ┌─ tiny S unit, not auto (≤ 30 lines, safe) ───► you: tests → code → self-check   (no agents, no review)
unit ──────►├─ S or M unit, or lite/bug-fix/quick CR ───────► coder (TDD: tests first, then code) ─► code-reviewer
            └─ L unit ──────────────────────────────────────► tester (failing tests) ─► coder ─► code-reviewer
```

1. **Checks** the gate and dependencies, and marks the unit 🔨.
2. **Plan** (≤ 10 lines). S units carry on; M/L units wait for your OK in step mode.
3. **Tests first:** tests named `USnnn_ACk_<Behaviour>` are written and seen to **fail** for the right reason, then the
   code is written until **only this unit's tests** (`test_story`) pass. No full suite here.
4. **One review** by the code-reviewer (Sonnet for small changes, Opus for large ones under `balanced`). Critical
   findings are fixed, then a **follow-up review** checks only those findings. At most two rounds.
5. **Record:** the unit becomes ✅, `units_done` + 1, traceability is regenerated, and a metrics row is added. After the
   last unit, the status moves to `testing`.
6. **Commit** `feat(CR-NNN U-NN): …`: proposed in step mode, made locally in auto mode. Never pushed.

**While it runs,** the agent list shows `CR-003-todo-description U-05 Description field` (the coder), then `… U-05
review: …` (the reviewer).

**You see:** an AC → test → ✅ table, files changed, test counts, the review verdict, and the next command.

### 6.7 Testing: `/aidlc-forge:testing [all | all --fresh | fast | US-NNN]`
1. Runs the **full suite once** with `test-all.sh`. If a green run already exists and no code changed since, it
   reuses it instantly. `--fresh` forces a real run.
2. Maps each failure to its story and classifies it: code bug, test bug, environment, or intended change.
3. Runs the **protected-test check** (git): no assertion removed or changed except for ACs the CR marks as changed.
4. Writes `docs/ops/test-report.md`: 8 lines when GREEN, failure details only when RED.
5. **GREEN** → the CR moves to `deploy`. **RED** → it names the fix to make. Auto mode fixes the failing stories and
   runs the suite once more.

It never edits code or tests. You can run it at any time as a regression check.

### 6.8 Deploy: `/aidlc-forge:deploy [staging | production]`
1. Needs a CR in `deploy` and a GREEN test report newer than the last unit. Otherwise it runs testing first.
2. **The devops agent** updates the container, CI workflow and runbook, fills in the **release-readiness table**, and
   writes **release notes**. It uses the test report instead of re-running tests.
3. **Security** checks only what no unit review saw: config, secrets handling, container, CI and infrastructure.
4. **Deploy gate:** the readiness table with blockers (❌) first, then *"Approve deploy gate?"*
5. **It never deploys.** You merge the CR branch through a PR, and your pipeline deploys after its own approval.

**Next:** after deployment, `/aidlc-forge:close CR-NNN`.

### 6.9 Close: `/aidlc-forge:close CR-NNN` (you type it; never automatic)
1. Checks that every unit is ✅, the test report is GREEN, the deploy gate is ✅ (or n/a), and no gate is still 🤖.
2. **Merges the CR into `docs/baseline/`:** new stories, changed ACs replaced, NFRs, a decision-log line, design
   deltas, and its ADRs marked Accepted.
3. Shows the baseline changes and asks *"Close CR-NNN?"*, then regenerates traceability and proposes a commit.

### 6.10 Bug-fix: straight to a tested fix
**You type:** `/aidlc-forge:bug-fix Rejecting a request doesn't release the annual balance` (with no text, it asks you to
describe the bug).

1. Opens a `bug-fix` CR (handle `CR-NNN-fix-<words>`) and branch. The gate is recorded as approved by your command; there's no approval stop.
2. Finds the code path and the **affected story and AC**.
3. **Scope check:** if the "fix" would change agreed behaviour, the contract, data or packages, or needs more than one
   unit, it stops and sends you to `/aidlc-forge:requirements`.
4. Writes a ≤ 20-line fix note: symptom, expected, actual, how to reproduce, affected AC.
5. **Reproduces the bug first:** a test that **must fail** for the bug's reason. If it can't reproduce it, it stops.
6. Minimal fix, with only the story's tests. Tiny fixes are done inline with a self-check; others use the coder and
   one review.
7. The **one full test run**, then the root cause is added to the fix note.
8. Asks **"Commit?"**: `fix(CR-NNN): …`.

### 6.11 Quick: a small change in one go
**You type:** `/aidlc-forge:quick Show the manager's name on each leave request` (with no text, it asks you to describe it).

Like bug-fix, but for small enhancements:
1. Opens a `quick` CR (handle `CR-NNN-<slug>`; one story, **≤ 3 ACs**, no contract, data or package change). Anything bigger goes to
   `/aidlc-forge:planning`, and a bug goes to `/aidlc-forge:bug-fix`.
2. Writes a ≤ 25-line request (ACs and a design note), shows the ACs as an FYI, and carries on without waiting.
3. Tests first, then code: inline with a self-check if tiny, otherwise the coder plus one review.
4. The one full test run, then **"Commit?"**: `feat(CR-NNN): …`.

### 6.12 Init: onboard a project (`/aidlc-forge:init`, once per project)
1. **Inspects:** git, the stack (from the profiles), and the build and test commands. It runs build and fast tests
   once to check them, and looks at the existing CLAUDE.md, settings, CI and docs.
2. **Proposes everything, then asks once "Apply these changes?":**
   - `.aidlc/config.yaml`, after asking your cost profile
   - the managed CLAUDE.md block
   - permissions and plugin enablement in `.claude/settings.json`
   - `scripts/aidlc/*.ps1`, an optional CI caller, `.gitignore` lines, and the docs folders
   - `git init`, if the project has no repo
3. **Migrates** the earlier sample layout (`docs/01-…04-…`, the old `.claude` commands, agents and hooks), asking first.
4. Never commits. Re-run it after a plugin update to refresh the managed files.

### 6.13 Discovery: document an existing codebase (`/aidlc-forge:discovery [area]`)
1. Creates `CR-000-baseline` ("As-is baseline").
2. **The discovery-analyst** maps entry points, routes, rules, persistence, auth and tests, and writes the baseline:
   stories with **observed** ACs (each with its source `file:line`), existing tests mapped with `Covered by:`, NFRs,
   architecture, contract, existing decisions, and **unknowns and risks**. It never changes code. For more than 3
   modules, one agent runs per module, in parallel.
3. Generates traceability and marks the gates 🤖.
4. **You:** `/aidlc-forge:step` to review and ratify the baseline, then `/aidlc-forge:close CR-000`. Then backfill tests for ❌
   stories, or start real work.

### 6.14 Acceptance criteria: draft or review ACs only
Write or review ACs **grounded in your code**, at the level of detail you need, without starting any lifecycle phase.

**You type** one of:
```
/aidlc-forge:acceptance-criteria                                                 # asks for the source and level
/aidlc-forge:acceptance-criteria PROJ-123                                        # a Jira, Azure DevOps, GitHub or Linear ticket
/aidlc-forge:acceptance-criteria Managers can delegate approvals technical      # an idea, with a level
/aidlc-forge:acceptance-criteria docs/specs/delegation.md                        # a document
/aidlc-forge:acceptance-criteria US-004                                          # review a story
/aidlc-forge:acceptance-criteria CR-005                                           # review a CR's request.md
```

**1. Source and level** (one picker, asking only what's missing):

| Source | | Level | For | Contains |
|---|---|---|---|---|
| Ticket link | fetched via a connected tool, `az`/`gh`, or the web (paste it if a login is needed; never asks for credentials) | **Business** | PO, stakeholders | 3–6 plain-language ACs |
| Description | used as given | **Functional** (default) | the whole team | validation, errors (status + code), permissions, edge cases, side effects |
| Document | the named section | **Technical** | developers | Functional + API, data, security, side effects and contract changes (`## Technical criteria`) |
| Existing code | ACs reverse-engineered from the feature | **QA** | testers, automation | Functional + a `.feature` file tagged `@US-NNN @ACn`, reusing your existing step wording |

You can also say a level in your own words: "summary" → Business, "detailed" → Functional, "API" → Technical,
"Gherkin" → QA.

**2. Project analysis** (scaled to the level: a quick look for Business, thorough for Technical and QA). It narrows to
the right module, then extracts **real facts**: roles, fields, limits, status values, messages, error codes,
endpoints, side effects and existing tests. It uses the code's own terms (`LeaveRequest`, not "time-off
application"). If a story already covers the feature, it proposes **Changed ACs** instead of a duplicate. It never
copies secrets.

**3. Writing**, with nothing invented:
- every rule comes from the requirement, from the code (`[from code: path:line]`), or is flagged `[ASSUMPTION]`
- **Conflicts:** where the requirement and the code disagree, for the PO to decide
- **Open questions:** where there's no sensible default
- an 8-point coverage list: happy path, validation (at and just over limits), business rules, errors, permissions,
  edge cases (empty, duplicates, concurrency), side effects, non-functional (only with a real requirement)
- **aidlc house style:** placeholder IDs `US-NEW1`… (real IDs are given when a CR imports the draft), the
  `| # | Given | When | Then |` table, and errors as `status area.code`. Every level produces numbered ACs, so any of
  them can be planned.
- **Bug tickets:** ACs for the correct behaviour, plus one that reproduces the bug

**Review mode** (`US-NNN`, `CR-NNN`, or a file with ACs): the same analysis and checks, then **a findings table**
(AC → problem → fix, with code references) and **the corrected ACs**.

**4. Self-review, as a tester who never saw the chat:** each AC is pass/fail on its own; no vague words (*fast,
appropriate, properly, robust…*); failures and permissions are covered; every rule has a source or a flag; more than
~8 ACs means a proposed split.

**5. Show, then save only on your yes:**
| Target | Saved to |
|---|---|
| a draft | `docs/specs/<ticket-or-slug>.md` |
| QA level | also `<feature_dir>/<slug>.feature`, after a second yes, plus a list of the step definitions it needs |
| a file you gave | that file |
| `CR-NNN` before its requirements gate | its `request.md` |
| `CR-NNN` after its gate | its `request.md`, after asking; the gate goes back to pending for re-approval |
| `US-NNN` in the baseline | never the baseline: `docs/specs/change-us-NNN.md`, to become a CR |

Saved files are lean: stories, ACs, Technical criteria, decisions, Conflicts and Open questions. The project analysis
and code references stay in chat.

**Next:** resolve the Conflicts and Open questions, then run `/aidlc-forge:planning docs/specs/<slug>.md`. It imports the
ACs word for word (a Business draft gets its error codes added as `(assumed)`). Or use `/aidlc-forge:quick` for one story
with ≤ 3 ACs.

**Settings** (in `.aidlc/config.yaml`; `init` detects them): `ac_default_level`, `ac_language`, `ticket_system`,
`ticket_base_url`, `bdd_framework`, `feature_dir` ([§10](#10-configuration-reference-aidlcconfigyaml)).

### 6.15 Status and portfolio
- `/aidlc-forge:status`: this project's open CRs and gates, the units in progress, traceability gaps, the last test
  result, and **the next command**. Haiku; read-only.
- `/aidlc-forge:portfolio [folder]`: every project in one table, plus **Needs attention**: RED runs, 🤖 gates to ratify,
  CRs with no update in 14 days, missing test reports.
- **For free (no AI):** `bash "<plugin>/scripts/portfolio.sh" "<folder>"`

### 6.16 End-to-end example
Goal: *"Employees get an email when their leave is approved or rejected"* in LeaveManagement.

**Option 1: step by step**
```
/aidlc-forge:requirements Employees get an email when their leave is decided
   → 4 questions (defaults offered) → answers → request.md: US-011 with 4 ACs → approve gate          (CR-005)
/aidlc-forge:planning CR-005
   → options: in-process queue vs hosted service vs outbox → choose "outbox"
   → design.md, ADR-009, contract unchanged, units U-21 (outbox), U-22 (sender), U-23 (wiring) → approve gate
/aidlc-forge:implementation next   ×3   → each: tests red → green → review → commit
/aidlc-forge:testing all           → GREEN (73/73) → status deploy
/aidlc-forge:deploy staging        → readiness table + release notes → approve gate → you merge the PR
/aidlc-forge:close CR-005           → stories and ADR-009 merged into docs/baseline
```

**Option 2: automatic**
```
/aidlc-forge:auto Employees get an email when their leave is decided. Use an outbox table and the existing IEmailSender.
   → no questions: plan summary → runs requirements, planning, implementation, testing, deploy
   → auto-run-report.md: 3 units, 3 commits, 73/73 GREEN, readiness table and release notes, 2 decisions to review
/aidlc-forge:step                  → ratify the 🤖 requirements, planning and deploy gates, then merge the PR
```

**Option 3: a small follow-up**
```
/aidlc-forge:quick Include the manager's comment in the rejection email
   → 1 AC, 12 lines → done inline: test red → green → self-check → full suite GREEN → Commit? yes
```

---

## 7. Core concepts

### Change requests (CRs)
Every piece of work is a CR in `docs/changes/CR-NNN-<slug>/`:

| File | Content |
|---|---|
| `state.yaml` | Flat status file: `id` (`CR-NNN`), `handle` (`CR-NNN-<slug>`), `ticket`, `title, track, status, gate_requirements/_by/_date, gate_planning/…, gate_deploy/…, units_total, units_done, branch, updated` |
| `request.md` | The delta stories and ACs, changed ACs, one-line decisions (and the implementation brief) |
| `design.md` | Only when there's a decision, contract change or data change |
| `units.md` | One 4-line context pack per unit |

`docs/baseline/` holds the approved truth. It changes only through `close` or `discovery`; ADRs and the API
contract are updated at planning time.

### Tracks
| Track | Use when | Gates | Build |
|---|---|---|---|
| `bug-fix` | The code contradicts agreed behaviour; 1 unit; no contract, data or package change | none to wait for (commit question) | reproduce first, inline if tiny |
| `quick` | 1 story, ≤ 3 ACs, 1 unit; no contract, data or package change | none to wait for (commit question) | inline if tiny, otherwise the coder |
| `lite` | 1 S unit; no new endpoint, entity, package, ADR or NFR | requirements | coder (TDD) |
| `standard` | Everything else | requirements, planning | S and M: coder (TDD). L: tester → coder |
| `full` | New product, more than 8 units, or a new external system | requirements, planning | as standard, plus a baseline rewrite |

### Status flow and gates
```
requirements → planning → implementation → testing → deploy → closed
```
- Lite, bug-fix and quick skip planning.
- `implementation → testing` when the last unit is ✅. `testing → deploy` when the full run is GREEN.
- **Gates:** `gate_requirements`, `gate_planning` (n/a for lite, bug-fix and quick), `gate_deploy`. The pull-request
  review is the implementation gate, and lives in git.
- **Gate values:** `pending` · `auto` (🤖 set in auto mode, needs ratifying) · `approved` (✅ only on a human yes) · `n/a`.

### CR naming: number plus title
Every change request has a **handle**, `CR-NNN-<slug>`, which is the name you see everywhere:

```
CR-005-admin-login
│  │   └─ slug: 2–4 lowercase kebab-case words from the title (bug fixes: fix-<words>)
│  └───── 3-digit number, zero-padded: next = highest existing + 1
└──────── prefix
```

| Where | Uses |
|---|---|
| Folder, branch | `docs/changes/CR-005-admin-login/` · `aidlc/CR-005-admin-login` |
| `state.yaml` | `id: CR-005` · `handle: CR-005-admin-login` · `ticket: PROJ-123` (optional) |
| Status, portfolio, traceability, reports | **`CR-005-admin-login (PROJ-123)`** |
| Commit scope (short on purpose) | `feat(CR-005 U-12): …` |
| Command arguments | any of `CR-005-admin-login`, `CR-005`, `CR-5`, `CR-05`, or just `admin-login` |

- **Ticket:** when work comes from Jira, Azure DevOps, GitHub or Linear (via `requirements`, `planning <spec>` or
  an `acceptance-criteria` draft), its key is recorded and shown next to the handle.
- **No clashes:** in a git repo, the next number also checks `base_branch`, so a parallel branch's number isn't reused.
- **Older CRs** (`CR-01-todo-table`, created before 3.3.0) keep their names and work everywhere. Lists sort by
  number, so `CR-01` comes before `CR-006`.

### IDs and test names
`CR-NNN` (CR-000 = discovery baseline) · `US-NNN` stories · `AC1…` per story · `NFR-NN` · `ADR-NNN` · `U-NN` units.
Tests are named **`US006_AC04_<Behaviour>`**, so traceability is generated from test names. Legacy tests are mapped
under a story with `Covered by: TestA, TestB`.

### Units and context packs
```
### U-14 Domain: DayPart and half-aware overlap · S · after: U-13 · group: A · ⏳
- ACs: US-006 AC6, AC11–AC14
- Read: src/Api/Domain/LeaveRequest.cs, tests/Api.Tests/LeaveRequestTests.cs, docs/baseline/adr/ADR-005-half-day.md
- Change: DayPart enum; LeaveRequest.DayPart (default Full); half-aware Overlaps
- Done when: the overlap truth table is green; existing Overlaps callers are unchanged
```
- Agents read **only** the files under "Read".
- Status markers: ⏳ not started · 🔨 in progress · ✅ done · ⛔ hard stop.
- Units in the same `group` don't share files, so they can run in parallel.

### Lean documents
Files hold only what a later step reads. Options and reasoning stay in chat. No Q&A transcripts, restated baseline,
empty sections or template guidance.

| Document | Limit |
|---|---|
| `request.md` | ≤ 80 lines (quick ≤ 25, bug-fix ≤ 20) |
| `design.md` | ≤ 60 lines |
| ADR | ≤ 12 lines |
| Context pack | 4 lines |
| Test report | ≤ 8 lines when GREEN |
| Auto-run report | ≤ 30 lines |

---

## 8. Agents
Agents are started by the commands, and named `aidlc-forge:<name>`. The model depends on `cost_profile`
([§11](#11-cost-and-speed)); effort and turn limits are fixed in each agent's file.

| Agent | Role | Used by | Effort | Turn limit | Tools |
|---|---|---|---|---|---|
| `requirements-analyst` | Stories and ACs; IMPORT MODE for direct planning (also imports `acceptance-criteria` drafts: real IDs, ACs word for word); AUTO MODE answers its own questions | requirements, planning, auto, custom-workflow | medium | 20 | read, write |
| `planner` | Options (in chat), design delta, ADRs, contract first, context-packed units | planning, requirements (lite) | medium (high for full-track CRs) | 30 | read, write, web search |
| `tester` | Failing tests from the ACs, for L units | implementation | medium | 20 | read, write, shell |
| `coder` | Implements one unit; TDD mode for S and M units; runs only the unit's tests | implementation, bug-fix, quick, auto, custom-workflow | medium | 40 | read, write, shell |
| `code-reviewer` | One independent review per unit, and follow-ups on fixed findings only. Read-only; never runs tests | implementation, bug-fix, quick | medium | 15 | read, shell (`git diff`/search) |
| `devops` | Container, CI, runbook, release notes, readiness. Never deploys | deploy | low | 20 | read, write, shell |
| `discovery-analyst` | As-is baseline from existing code | discovery | medium | 60 | read, write, shell |

**How agents work** (to keep each run short and cheap):
- **Started with a short prompt:** IDs and paths (CR folder, unit ID, mode, brief), never file contents or rules.
- **CLAUDE.md is never re-read:** agents get it automatically.
- **One parallel batch of reads** in the first turn (config, profile section, context pack, the files it names), and
  no searching for files the context pack already lists. Every turn re-sends the whole context, so fewer turns cost less.
- **Reports are ≤ 10 lines,** with no code, diffs or logs, so the main session's context stays small.
- **Labelled in the agent list:** while an agent runs, Claude Code's agent list shows what it's working on:
  `CR-003-todo-description U-05 Description field` (coder), `… U-05 review: …` (code-reviewer),
  `CR-006-leave-emails planning: Leave emails` (planner), `Discovery: Billing` (discovery-analyst), and so on.
- An agent that reaches its turn limit isn't restarted: it's a hard stop in auto mode, or a question in step mode.
- The analyst, planner, tester and coder follow the requester's `BRIEF:` from auto mode.

---

## 9. Testing and quality
| Rule | Detail |
|---|---|
| **Tests first** | Every unit writes failing tests named after its ACs, sees them fail for the right reason, then implements. |
| **During implementation: the unit's own tests only** | `test_story` for the stories in scope. No full suite per unit or per step. |
| **Full suite once** | In `/aidlc-forge:testing all`, after the last unit. If RED, the failing stories are fixed with story tests, then the suite runs once more. |
| **`test-all.sh` reuses** | A green full run is reused when no code changed since (0.4 s instead of a full run). `--fresh` forces a run. Output is compact; the log goes to `.aidlc/last-test-all.log`. |
| **Stop hook** | Runs `test_fast` after a turn that changed code. It's skipped while a CR is in `implementation`, when nothing changed, or when `test_gate: off`. It guards direct, ad-hoc edits. |
| **Protected-test check** | `git diff` on the test folders since the CR branch point. Removed or changed assertions are allowed only for ACs the CR marks as changed; otherwise it's a hard stop (auto) or a question (step). |
| **One review per unit** | A follow-up review covers only the fixed findings. Deploy never re-reviews code. The reviewer and devops never run tests. |
| **Right-sized review** | Under `review_small_lines` (150) changed lines: Sonnet. Above: Opus (balanced profile). |
| **Tiny changes run inline** (only when you drive: `quick`, `bug-fix`, or `implementation` by hand or via `step`; never in auto mode) | ≤ `tiny_change_lines` (30) lines, and no auth, secrets, personal data, data model, migration or contract change: done in your session with tests first and a **self-check** (every AC has a test, error codes match the contract, empty and boundary input handled, no weakened test, no debug code). No agents. It hands over to the agents if it grows. |
| **Traceability** | `docs/traceability.md` is generated by `trace.sh` from story headings and test names (✅ / 🟡 partial / ❌ no tests). |

---

## 10. Configuration reference (`.aidlc/config.yaml`)
Flat `key: value` lines only (the hooks read them with grep). Don't put comments at the end of value lines.
`{FILE}` and `{ID}` are filled in at run time.

| Key | Example / default | Meaning |
|---|---|---|
| `project` | `LeaveManagement` | Name shown in `portfolio` |
| `stack` | `dotnet-webapi` | Stack profile in `profiles/` |
| `base_branch` | `main` | CR branches are created from it |
| `build` | `dotnet build X.sln --nologo` | Build command |
| `test_fast` | `dotnet test X.sln --filter "…!~Integration…"` | Fast unit subset, under 60 s (used by the Stop hook) |
| `test_all` | `dotnet test X.sln --nologo` | The full suite (testing phase, `test-all.sh`) |
| `test_story` | `dotnet test X.sln --filter "FullyQualifiedName~{ID}"` | One story's tests (`{ID}` = `US006`) |
| `format_file` | `dotnet format whitespace --folder --include {FILE}` | Formats one edited file (empty = off) |
| `run` | `dotnet run --project src/X.Api` | Starts the app |
| `code_dirs` / `test_dirs` / `code_exts` | `src tests` / `tests` / `cs csproj` | What counts as code and tests |
| `contract` | `docs/baseline/api/openapi.yaml` | The living API contract |
| `story_prefix` | `US` | Story ID prefix |
| `track_default` | `standard` | Default track proposal |
| `test_gate` | `on` | `off` disables the Stop hook |
| `parallel_units` | `off` | `on` lets auto mode build independent units in parallel worktrees (needs git) |
| `auto_max_attempts` | `3` | Fix attempts before a hard stop |
| `auto_deploy` | `on` | `off` makes `/aidlc-forge:auto` stop after testing (no deploy step). `custom-workflow` is unaffected: you tick Deploy or not |
| `review_small_lines` | `150` | Below it, the reviewer uses Sonnet (balanced profile) |
| `tiny_change_lines` | `30` | Inline limit for tiny changes (`0` = always use agents) |
| `ac_default_level` | `functional` | Default level for `/aidlc-forge:acceptance-criteria`: `business` · `functional` · `technical` · `qa` |
| `ac_language` | `English` | Language the ACs are written in (code identifiers stay as they are) |
| `ticket_system` / `ticket_base_url` | `none` / – | `jira` · `azure-devops` · `github` · `linear`, and the base URL for bare keys like `PROJ-123` |
| `bdd_framework` / `feature_dir` | `none` / – | e.g. `reqnroll` and `tests/Features`: where QA-level `.feature` files go, and how their steps bind |
| `cost_profile` | `balanced` | `economy` · `balanced` · `quality` ([§11](#11-cost-and-speed)) |

---

## 11. Cost and speed

### Where the tokens go (measured)
| Item | Tokens | Paid |
|---|---|---|
| **Main session, before any work** (Claude Code's system prompt and tools, installed skills and plugins, memory, CLAUDE.md) | ~37,800 | re-sent on **every turn** of the session |
| **Each agent, before any work** | ~8,000 | once per agent start, then re-sent on each of its turns |
| This plugin's always-on command descriptions | ~1,900 | part of the main session's baseline |
| `core.md` rules | ~2,200 | once per command or agent that reads them |
| A story test run (LeaveManagement) | 90–360 | per run |

**How cost builds up:** every tool call is a new model turn, and each turn re-sends the whole context. Cached
context costs about 10% of normal input, but **output and thinking cost the most.** So:

> cost ≈ **turns × context size** + new text read + **output and thinking**

Fewer turns, a smaller context, fewer agent starts, less output, and a cheaper model are the levers. The plugin
applies all five. What's left is on your side: see the habits below.

**Inline versus agents:** an inline tiny change avoids an agent start and re-reading files, so it's **faster**. But
each turn re-sends the main session's ~38k context instead of an agent's ~8k. With the main session on **Sonnet**,
inline costs about the same as an agent. On **Opus**, it costs more. That's why tiny inline is for interactive work
only, and auto runs always use agents.

### Cost profiles (`cost_profile`)
| Profile | requirements-analyst | planner | code-reviewer | tester, coder, devops, discovery-analyst |
|---|---|---|---|---|
| `economy` | Sonnet | Sonnet | Sonnet | Sonnet |
| `balanced` (default) | Opus for full-track CRs only | Opus for standard and full CRs | Opus for changes of 150+ lines | Sonnet |
| `quality` | Opus | Opus | Opus | Sonnet |

`status` and `portfolio` run on Haiku.

### What makes it fast
| Feature | Effect |
|---|---|
| Shortcuts (`bug-fix`, `quick`, direct `planning`) | Small work skips analysis and gates |
| Tiny changes inline (interactive only) | 0 agent hand-offs for ≤ 30-line changes; auto mode uses agents so its main context stays small |
| Effort and turn limits per agent | Routine agents don't over-think; runaway loops are capped |
| One coder for S and M units (tester only for L) | One agent start fewer per M unit, and no second read of the same files |
| Agents read in one parallel batch, skip CLAUDE.md, report in ≤ 10 lines | Fewer turns (each turn re-sends the whole context), ~1k fewer tokens per agent, a smaller main context in auto runs |
| Planner at `medium` effort (`high` only for full track) | Less thinking, which is billed as output |
| Full suite once, plus reuse | No repeated test runs |
| One review per unit | No duplicate reviews |
| Lean documents and context packs | Agents read a few short files instead of the whole docs tree |
| Rules split into `core.md` (~2.2k, including CR naming and agent labels) + detail files (`tiny`, `docs`, `tracks`, `state`, `git`) | Commands and agents read only the rules they need |
| Model routing | Opus only where judgement pays off |
| Optional parallel units | Independent units are built at the same time |

### Habits that save the most
1. Run your session on **Sonnet**, or use **`/fast`**. The main session's ~38k context is re-sent every turn, so
   its model matters most.
2. **Shrink that baseline:** run `/context` in a terminal `claude` session to see what's in it, and disable plugins,
   skills and MCP servers you don't use for development.
3. One CR or unit per session, and **`/clear`** between steps.
4. Use the cheapest command that fits ([§4](#4-which-command-for-which-change)).
5. Don't paste test logs: use `/aidlc-forge:testing` or `test-all.sh`.
6. Check status for free: `bash "<plugin>/scripts/portfolio.sh" <folder>`.
7. Cap unattended runs with `-MaxBudgetUsd`. Costs are logged in `.aidlc/metrics.csv`.

---

## 12. Project files and folders
```
.aidlc/
  config.yaml                 project settings (§10)
  metrics.csv                 one row per unit and per unattended run: date,cr,unit,track,size,mode,result,attempts,tests_added,notes
  last-test-all.txt / .log    the last full run: result, summary, full log (gitignored)
  .last-green                 Stop hook marker (gitignored)
  runs/<timestamp>/           unattended run logs (gitignored)
docs/
  baseline/                   prd.md, stories.md, nfr.md, architecture.md, [data-model.md], api/<contract>, adr/ADR-NNN-*.md
  changes/CR-NNN-<slug>/       one folder per CR, named by its handle (e.g. CR-005-admin-login): state.yaml, request.md, [design.md], units.md
  specs/                      draft or imported specs and ACs (from /aidlc-forge:acceptance-criteria); not counted until a CR imports them
<feature_dir>/*.feature        QA-level Gherkin from /aidlc-forge:acceptance-criteria (only if you saved it; tagged @US-NNN @ACn)
  ops/                        runbook.md, test-report.md, release-notes.md, auto-run-report.md
  traceability.md             generated; never edit by hand
scripts/aidlc/                run-regression.ps1, aidlc-auto.ps1 (managed copies)
CLAUDE.md                     contains the managed <!-- aidlc:start --> … <!-- aidlc:end --> block
```

---

## 13. Git rules
- **Branch per CR:** `aidlc/<handle>` (e.g. `aidlc/CR-005-admin-login`) from `base_branch`. Step mode asks first. Auto mode creates it if the
  working tree is clean, otherwise it's a hard stop.
- **Commits:**
  - auto mode commits locally after each green, reviewed unit (`feat(CR-NNN U-NN): <title> [US-…]`)
  - step mode proposes the message and commits only on a yes
  - bug-fix uses `fix(CR-NNN): …`
- **Never:** push, merge into `base_branch`, commit on `base_branch`, rebase, or reset.
- **Without git:** everything runs, but the protected-test check, per-unit commits and parallel units are reported as
  "skipped (no git)".

---

## 14. Hooks and scripts

### Hooks (installed with the plugin; inactive without `.aidlc/config.yaml`)
| Hook | When | What it does |
|---|---|---|
| `format-on-edit.sh` | After every Edit or Write | Runs `format_file` on the edited file if its extension is in `code_exts`. Never blocks. |
| `test-gate.sh` | When Claude is about to finish a turn | Runs `test_fast` if code changed since the last green run. **Blocks** (exit 2) on failure and shows the failing test with expected and actual values. Skipped while a CR is in `implementation`, or with `test_gate: off`. Has a loop guard. |

### Plugin scripts (`${CLAUDE_PLUGIN_ROOT}/scripts/`)
| Script | Usage | What it does |
|---|---|---|
| `test-all.sh` | `bash test-all.sh [--fresh] [project_dir]` | Runs `test_all` once, with compact output. Reuses a still-valid green run; `--fresh` forces a run. Writes `.aidlc/last-test-all.*`. Exit 0 = green. |
| `trace.sh` | `bash trace.sh [project_dir] > docs/traceability.md` | Stories (baseline plus open CRs, labelled by handle) → tests, with AC coverage, missing legacy tests and orphan tests |
| `portfolio.sh` | `bash portfolio.sh [folder …]` | The status table across projects (CRs by handle plus ticket, in numeric order), plus Needs attention. No AI involved. |
| `lib.sh` | (sourced) | Config reading, path conversion, "changed since", failure summaries |

### Project runner scripts (`scripts/aidlc/`, copied by `init`)
| Script | Parameters | What it does |
|---|---|---|
| `run-regression.ps1` | `-Story US004`, `-Fast` | Runs **one** command (`test_all` by default). Exit 0 = GREEN, 1 = RED. For Task Scheduler, pre-push hooks or CI. |
| `aidlc-auto.ps1` | `-Intent "<text>" \| "continue [CR-NNN]"`, `-Phases a,b` (default `all`), `-MaxBudgetUsd 20` | Runs `/aidlc-forge:auto` headless (or `/aidlc-forge:custom-workflow --phases …` when `-Phases` is given) with **enforced limits**: edits to `.claude/`, `CLAUDE.md` and the config are blocked; push, merge, rebase, reset, `rm -rf`, `bash -c` and `sh -c` are blocked (no blanket `bash` approval); only the local git commands it needs are allowed. Then it re-runs the regression itself, writes `.aidlc/runs/<timestamp>/` (Claude's output and summary, the regression log) and a metrics row with the cost. Exit 0 = GREEN. |

---

## 15. CI
- **Shared workflow** in the marketplace repo: `.github/workflows/aidlc-dotnet.yml` (`workflow_call`), with inputs
  `solution`, `dotnet-version` (default `10.0.x`, the current LTS), `docker`, `health-path`. It restores, builds
  (Release), tests with coverage, uploads the results, and optionally builds a Docker image and smoke-tests the
  health endpoint.
- **Project caller** (`init` writes `.github/workflows/aidlc-ci.yml`): runs on PRs, pushes to main, nightly at 01:00
  UTC, and manually. `init` fills in the real solution, `dotnet-version` from the projects' `TargetFramework`
  (e.g. `net9.0` → `9.0.x`), and `docker: true` only if there's a Dockerfile.
- **Private marketplace repo:** allow other repos to use the shared workflow under **Settings → Actions → General →
  Access**. Pin it to a release tag: `uses: YOUR-ORG/aidlc-forge/.github/workflows/aidlc-dotnet.yml@aidlc-forge--v3.3.2`.
- **Deployment jobs** stay in each project. Protect the `production` environment with required reviewers (the deploy gate).

---

## 16. Stack profiles
`profiles/<stack>.md` holds: how to detect the stack, config defaults for `init`, the conventions agents follow, and
testing patterns.

| Profile | For |
|---|---|
| `dotnet-webapi` | ASP.NET Core APIs. Covers: test_fast strategies, ProblemDetails with stable codes, `TimeProvider`, central package management, EF Core migration rules, atomic check-then-write, architecture tests, modular monoliths, `WebApplicationFactory` |
| `generic` | Any other stack; the commands are filled in by `init` |

To add a stack, create `profiles/<stack>.md` with the same sections.

---

## 17. Safety rules
**Never, in any mode:**
- push, deploy, merge into `base_branch`, or commit on it
- weaken, skip or delete a test to get to green
- invent requirements
- in auto mode: edit `.claude/`, `CLAUDE.md` or `.aidlc/config.yaml`, or close a CR

**Hard stops in auto mode** (it stops and reports instead of working around the problem):
- tests still red after `auto_max_attempts` attempts
- a Critical review finding that can't be fixed within the unit
- an existing test would change for an AC that isn't marked as changed
- a new package, a security issue, or a change outside the context pack
- a contradiction with an accepted ADR
- a dirty working tree when the CR branch is needed
- an agent reached its turn limit

**Human control:**
- Only you set ✅ `approved`. `close`, `init`, `discovery`, `bug-fix`, `quick`, `auto` and `custom-workflow` run only when you type them.
- Production deployment always needs your approval in the pipeline.

**Shell permissions:**
- While a command runs, it pre-approves **only the plugin's own scripts** (`bash "<plugin>/scripts/…"`) plus a few
  read-only or local git commands. It never pre-approves a blanket `bash …`, which would also cover
  `bash -c "<anything>"`.
- The unattended runner (`aidlc-auto.ps1`) also blocks `bash -c` and `sh -c`. A wrapped command would otherwise get
  around its deny rules for `git push`, `merge`, `rebase`, `reset` and `rm -rf`, because Claude Code doesn't look
  inside the wrapped string.
- Every other command follows your normal permission settings. For a hard boundary, use Claude Code's sandboxing.

**Tickets, secrets and outside text:**
- `acceptance-criteria` only **reads** tickets (Jira, Azure DevOps, GitHub, Linear). It never writes to them, and
  **never asks for passwords or tokens**. On a login page, it asks you to paste the ticket instead.
- Ticket and document text is treated as **data, not instructions**.
- Values from `.env`, connection strings or keys are never copied into ACs or documents. Only the fact that a setting
  exists is mentioned.
- Nothing is written without your yes: drafts, `request.md` changes and `.feature` files are shown first.

---

## 18. Troubleshooting and FAQ
| Problem | Fix |
|---|---|
| `/aidlc-forge:…` commands don't appear | Check that it's installed (`claude plugin list`), then run `/reload-plugins` or start a new session. Adding a marketplace alone doesn't install the plugin. |
| "config missing, run /aidlc-forge:init" | The project isn't onboarded. Run `/aidlc-forge:init`. |
| Claude says it can't run `init`, `auto`, `custom-workflow`, `quick`, `bug-fix`, `close` or `discovery` | They're user-only. Type the command yourself. |
| The old `/aidlc-next` and `/aidlc-build` still appear | That's the earlier in-repo sample. Run `/aidlc-forge:init` to migrate it and remove them. |
| Both `/aidlc:…` and `/aidlc-forge:…` commands appear | The session started before the 3.0.0 rename. Run `/reload-plugins` or start a new session. If they persist, run `claude plugin list` and uninstall any old `aidlc@…` entry (see "Upgrading" in §2). |
| `/aidlc-forge:auto` no longer shows the step picker | Since 3.1.0, `auto` runs every remaining step with no questions. Use `/aidlc-forge:custom-workflow` to choose the steps, or `--phases a,b` with it to skip the picker. |
| I don't want `auto` to run the deploy step | Set `auto_deploy: off` in `.aidlc/config.yaml`. `auto` then stops after testing. Or use `/aidlc-forge:custom-workflow` without Deploy for one run. |
| A step feels slow | Use a shortcut (§4), Sonnet or `/fast`, and `/clear` between steps. Check that the project is onboarded (§11). |
| The Stop hook keeps running tests | It's meant to guard ad-hoc edits. It's skipped during implementation. To turn it off completely: `test_gate: off`. |
| "GREEN (reused)" but you want a real run | `/aidlc-forge:testing all --fresh`, or `bash test-all.sh --fresh` |
| An agent hit its turn limit | The unit is probably too big. Split it in `units.md`, or continue in step mode. |
| Runs cost too much | Main session on Sonnet; `/clear` between steps; `cost_profile: economy`; check `/context` for unused plugins and MCP servers; use `quick` and `bug-fix` for small work (§11) |
| Drafted ACs don't show in traceability | Drafts in `docs/specs/` use `US-NEW` placeholder IDs and aren't counted until a CR imports them: `/aidlc-forge:planning docs/specs/<file>.md` |
| Which name do I use for a CR in a command? | Any of these: the full handle (`CR-005-admin-login`), `CR-005`, `CR-5`, `CR-05`, or the slug (`admin-login`). If two match, you're asked. |
| A command asks me to approve one of its own scripts (`bash "…/scripts/….sh"`) | It should be pre-approved. Approve it once, and report the exact command shown, so the rule's quoting can be adjusted for your install path. As a workaround, add an allow rule for that script to `.claude/settings.json`. |
| Claude asks to approve a `bash -c "…"` command during a run | That's intended: wrapped commands are never pre-approved, because they could hide anything. Check what it runs before approving. |
| A ticket link shows a login page | Paste the ticket's title, description, ACs and comments into the chat. Or connect a Jira or Azure DevOps tool, or log in to `gh` or `az`. The command never asks for passwords or tokens. |
| Protected-test check "skipped (no git)" | Run `git init` and make a first commit |
| A 🤖 gate needs ratifying | `/aidlc-forge:step` walks you through it |

---

## 19. Plugin layout (for maintainers)
```
.claude-plugin/plugin.json      name, version, description
skills/<name>/SKILL.md          the 16 commands (acceptance-criteria also has references/: levels, project-analysis, examples)
agents/<name>.md                7 agents (model, effort, maxTurns, tools)
hooks/hooks.json                PostToolUse format, Stop test gate
reference/core.md               rules every command and agent reads (modes, never-rules, CR naming, model routing, agent rules and labels, speed) ≈ 2.2k tokens
reference/tiny.md               tiny changes run inline; read only by bug-fix, quick, implementation
reference/docs.md               lean-document rules and size limits; read only by writers (analyst, planner, quick, bug-fix, planning)
reference/tracks.md             tracks, which entry to use, naming convention
reference/state.md              state.yaml, status flow, gates, phase entry
reference/git.md                branches, commits, protected-test check
profiles/<stack>.md             stack profiles
scripts/                        lib.sh, test-gate.sh, format-on-edit.sh, test-all.sh, trace.sh, portfolio.sh
templates/                      config.yaml, state.yaml, request.md, design.md, units.md, adr.md, baseline.md,
                                runbook.md, claude-md-section.md, scripts/*.ps1, ci/aidlc-ci.yml
```

At repo level (the marketplace folder) there are also: `.claude-plugin/marketplace.json`,
`.github/workflows/aidlc-dotnet.yml` (shared CI), `.gitattributes` (Unix line endings for scripts, so hooks run on
every OS) and `.gitignore`.

**Release steps:**
1. Bump `version` in `plugins/aidlc-forge/.claude-plugin/plugin.json` **and** `.claude-plugin/marketplace.json`.
2. Add a CHANGELOG entry.
3. Run `claude plugin validate . --strict` and `claude plugin validate plugins/aidlc-forge --strict`.
4. Run `claude plugin tag plugins/aidlc-forge` (creates `aidlc-forge--vX.Y.Z`).
5. Push, including the tag: `git push && git push --tags`.

**Naming convention:**
- Commands are named after their scope (project, phase, mode, authoring help, view). Familiar names are kept: `init`, `deploy`,
  `close`, `bug-fix`.
- Agents use `<area>-<role>` or a short familiar role (`planner`, `tester`, `coder`, `devops`).
