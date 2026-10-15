# aidlc-forge

A Claude Code plugin marketplace containing the **aidlc-forge** plugin, the AI-Driven Development Life Cycle for
Claude Code, plus the shared CI workflow that projects call.

**📖 Full documentation: [plugins/aidlc-forge/README.md](plugins/aidlc-forge/README.md).** It covers install, quick start, every
command, run modes, concepts, agents, testing, configuration, cost and speed, files, git, hooks and scripts, CI,
safety, and troubleshooting.

**What's inside the `aidlc-forge` plugin (v3.6.1):**
- **16 commands** (`/aidlc-forge:…`):
  - project setup: `init`, `discovery`
  - lifecycle: `requirements` → `planning` → `implementation` → `testing` → `deploy` → `close`
  - shortcuts: `bug-fix`, `quick`
  - authoring help: `acceptance-criteria`
  - run modes: `step`, `auto`, `custom-workflow`
  - views: `status`, `portfolio`
- **7 agents:** `requirements-analyst`, `planner`, `tester`, `coder`, `code-reviewer`, `devops`, `discovery-analyst`
- **2 hooks:** format on edit, and a test gate before Claude finishes
- **Project scripts** (copied by `/aidlc-forge:init`): `watch.ps1` (live progress view), `aidlc-auto.ps1` (unattended runs, with live output and a notification), `run-regression.ps1`, `statusline.sh` (live status line) and `agent-rows.ps1` (agent rows with progress, time and token count)

```
.claude-plugin/marketplace.json           marketplace manifest
plugins/aidlc-forge/                      the plugin (skills, agents, hooks, scripts, templates, profiles)
plugins/aidlc-forge/README.md             the complete documentation
plugins/aidlc-forge/CHANGELOG.md          version history
.github/workflows/aidlc-dotnet.yml        shared CI (workflow_call) for .NET projects
.gitattributes                            keeps Unix line endings for scripts (hooks work on every OS)
.gitignore                                editor, OS and temp files
```

## Install
```
claude plugin marketplace add YOUR-ORG/aidlc-forge
claude plugin install aidlc-forge@aidlc-forge --scope user
```
- **From a local folder:** `claude plugin marketplace add "<path-to>/aidlc-forge"`
- **Then:** run `/reload-plugins` (or start a new session), and `/aidlc-forge:init` in each project.

## Before the first publish
- [ ] Replace `YOUR-ORG` with your GitHub user or org in this README, `plugins/aidlc-forge/README.md` and
      `plugins/aidlc-forge/templates/ci/aidlc-ci.yml`
- [ ] Set the real owner and author in `.claude-plugin/marketplace.json` and `plugins/aidlc-forge/.claude-plugin/plugin.json`
      (currently "Platform Team")
- [ ] License: add a `LICENSE` file matching `"license": "MIT"` in `plugin.json`, or change it (e.g. `"proprietary"`
      for an internal tool)
- [ ] Smoke test in one onboarded project: `/aidlc-forge:status`, a small `/aidlc-forge:quick`, `/aidlc-forge:acceptance-criteria`

## Maintain
1. Push this folder to a git repo your team can read, e.g. `YOUR-ORG/aidlc-forge`. `.gitattributes` keeps the bash
   scripts' Unix line endings, so the hooks work for teammates on Windows, macOS and Linux.
2. For each release:
   - bump `version` in `plugins/aidlc-forge/.claude-plugin/plugin.json` **and** `.claude-plugin/marketplace.json`
   - add a CHANGELOG entry
   - validate:
     ```
     claude plugin validate . --strict
     claude plugin validate plugins/aidlc-forge --strict
     ```
   - run `claude plugin tag plugins/aidlc-forge`, which creates the tag `aidlc-forge--vX.Y.Z` that projects' CI callers pin to
3. Projects update with `claude plugin marketplace update aidlc-forge`, then
   `claude plugin update aidlc-forge@aidlc-forge`. Re-running `/aidlc-forge:init` in a project refreshes its managed scripts
   and its CLAUDE.md block.
