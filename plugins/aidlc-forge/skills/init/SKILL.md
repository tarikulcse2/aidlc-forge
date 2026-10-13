---
name: init
description: Onboard a project to AI-DLC - detect the stack and test layout, write .aidlc/config.yaml, the CLAUDE.md section, permissions, runner scripts and CI caller. Run once per project; re-run to refresh managed files after a plugin update.
argument-hint: [stack profile, e.g. dotnet-webapi]
disable-model-invocation: true
---

Onboard this project to AI-DLC (stack hint: **$ARGUMENTS**). This is always step-by-step: show every file
change and ask before writing. Never commit.

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` and the profiles in `${CLAUDE_PLUGIN_ROOT}/profiles/`.

## 1. Inspect (read only)
- **git:** is this a repo? What's the default branch (`git symbolic-ref refs/remotes/origin/HEAD`, else `main`)? Is the working tree clean?
- **Stack:** use `$ARGUMENTS`, or detect it with the "Detect" section of each profile. Otherwise use `generic`.
- From the matching profile, work out the build, test, format and run commands, and the fast test layer.
  Run `build` and `test_fast` once to confirm they work, and note their duration.
- **Existing setup:**
  - `CLAUDE.md`
  - `.claude/settings.json`
  - `.github/workflows/`
  - `docs/`. The earlier layout `docs/01-requirements`, `docs/02-design`, `docs/03-tasks`, `docs/04-ops`
    gets the migration in step 4.

## 2. Propose (show it all, then ask "Apply these changes?")
1. `.aidlc/config.yaml`, from `${CLAUDE_PLUGIN_ROOT}/templates/config.yaml`, filled in. Ask which `cost_profile` to use:
   `economy` (cheapest, Sonnet for everything), `balanced` (default, Opus only for big or judgement work) or `quality`.
   Fill in the acceptance-criteria settings from what you detect, and ask only what you can't detect:
   - `ticket_system` and `ticket_base_url`: Jira, Azure DevOps, GitHub, Linear or none. Look for issue links in the
     README and commits, and the git remote.
   - `bdd_framework` and `feature_dir`: Reqnroll, SpecFlow, Cucumber, Behave or none (look for `*.feature` files and packages)
   - `ac_default_level` (business, functional, technical or qa; default functional) and `ac_language`
2. `CLAUDE.md`: add or replace the block between `<!-- aidlc:start -->` and `<!-- aidlc:end -->`, using
   `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-section.md`. Never touch text outside the markers.
3. `.claude/settings.json`: merge (never replace):
   - `permissions.allow`: `Bash(<first two words of each configured command>:*)`, e.g. `Bash(dotnet build:*)`,
     plus `Bash(git status:*)`, `Bash(git diff:*)`, `Bash(git log:*)` and `Bash(git merge-base:*)`
   - `permissions.ask`: `Bash(git commit:*)`, `Bash(git push:*)`
   - `extraKnownMarketplaces` and `enabledPlugins` for `aidlc-forge@aidlc-forge`, so teammates get the plugin.
     Ask for the marketplace git URL if it can't be found from `claude plugin marketplace list`.
4. `scripts/aidlc/run-regression.ps1` and `scripts/aidlc/aidlc-auto.ps1`, copied from
   `${CLAUDE_PLUGIN_ROOT}/templates/scripts/`. Keep their "managed by the aidlc-forge plugin" header.
5. `.github/workflows/aidlc-ci.yml` from `${CLAUDE_PLUGIN_ROOT}/templates/ci/aidlc-ci.yml` (ask first, and
   only if the project uses GitHub). Fill in `solution` with the real solution file. Set `dotnet-version` from the
   projects' `TargetFramework` (`net9.0` → `9.0.x`, `net10.0` → `10.0.x`; with several, use the highest). Set `docker` to
   `true` only if there's a `Dockerfile`. If the target framework is out of support, say so in one line.
6. `.gitignore`: add `.aidlc/runs/`, `.aidlc/.last-green`, `.aidlc/last-test-all.*` and `TestResults/` if they're missing.
7. Folders `docs/baseline/`, `docs/changes/` and `docs/ops/` (with a `.gitkeep` where a folder would be empty).
8. **No git:** offer `git init` (never commit). Without git, the protected-test check, per-unit commits and
   parallel units are disabled.

## 3. Apply
Write the files, then run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/portfolio.sh"` to confirm the config is readable.

## 4. Migration from the earlier sample layout (only if `docs/01-requirements` exists; ask first)
| Earlier | New |
|---|---|
| `docs/01-requirements/{prd,user-stories,nfr}.md` | `docs/baseline/{prd,stories,nfr}.md` |
| `docs/02-design/*` (architecture, data-model, api/, adr/) | `docs/baseline/*` |
| `docs/03-tasks/units.md`: done units | keep as history in `docs/baseline/units-history.md` |
| `docs/03-tasks/units.md`: open units of a CR | `docs/changes/CR-NNN-<slug>/units.md`, with a context pack per unit |
| CR sections inside the PRD and stories (`CR-001`, `CR-002`, ...) | `docs/changes/CR-NNN-<slug>/request.md` + `state.yaml`, with the gates as recorded |
| `docs/04-ops/*` | `docs/ops/*` |
| `.claude/agents`, `.claude/commands`, `.claude/hooks` from the sample | remove them, because the plugin replaces them (ask first) |

After migrating, run `test_all` and `trace.sh`, and report what moved.

## 5. Next step
- Code exists but `docs/baseline/` is empty: `/aidlc-forge:discovery`
- New project: `/aidlc-forge:requirements <product idea>` (track full)

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
