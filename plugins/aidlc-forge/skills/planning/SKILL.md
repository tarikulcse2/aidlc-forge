---
name: planning
description: Plan a change - design, ADRs and units of work. Describe the change (or give a spec file) to start directly, or pass CR-NNN.
argument-hint: <describe what to plan, or a spec file path, or CR-NNN>
---

Plan: **$ARGUMENTS**

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.
If the config is missing, stop and suggest `/aidlc-forge:init`.

## 0. Which entry?
| Argument | Entry |
|---|---|
| `CR-NNN` | **Existing CR:** go to step 1 |
| empty | **Existing CR:** the open CR whose `state.yaml` says `status: planning`. If there are several, ask which one. Go to step 1. **If there's none**, ask: *"Describe what you want to plan (a feature or change, ticket text, or a spec file path):"*. Wait for the answer and treat it as direct planning. |
| anything else | **Direct planning:** do steps D1–D4 first, then continue with step 1 |

## Direct planning (D1–D4): requirements imported in one step
D1. **Source:**
   - If the argument is the path of an existing file (a spec, ticket export or Markdown), read it as the source.
   - Otherwise, the argument text is the source.
   - If it's a bug fix of a single unit, suggest `/aidlc-forge:bug-fix`; if it's a small change (one story, ≤ 3 ACs, no contract or
     data change), suggest `/aidlc-forge:quick`. Then stop.

D2. **Open the CR**, as in `/aidlc-forge:requirements` steps 1, 3 and 4: the handle `CR-NNN-<slug>`, a branch (ask first),
    and `state.yaml`, with `ticket:` taken from the source (e.g. an acceptance-criteria draft's source line). The track
    is `standard`, or `full` if the source describes a new product or more than 8 units.

D3. **Import** with the `requirements-analyst` agent (model per core.md: Model routing). Prompt it with `IMPORT MODE.`, the source, the CR folder and
    the track. It writes `request.md` with no questions: each AC comes from the source text, and anything it had
    to fill in is marked `(assumed)` and listed in the decisions table.

D4. **One combined approval.** Show (≤ 15 lines):
   - the stories with their AC counts
   - every `(assumed)` item, plus any Conflicts and Open questions carried from the draft (they must be answered now)
   - changed existing stories
   - the track

   Ask **"Approve the requirements and continue to planning?"**
   - **Yes:** set `gate_requirements: approved`, `gate_requirements_by` (`git config user.name`, plus
     " (direct planning)"), `gate_requirements_date`, status `planning`, and continue with step 1.
   - **No:** ask what to change, have the analyst update `request.md`, and ask again.
   - In AUTO MODE, set `gate_requirements: auto` instead and continue.

## Planning (existing CR, or after D4)
1. **Check:** gate_requirements is `approved`, or `auto` in an auto run. Otherwise stop. If the track is lite, say
   that the design was covered at the requirements gate, and stop.
2. **Delegate** to the `planner` agent (model per core.md: Model routing) with the CR folder and mode (prefix `AUTO MODE.` in auto runs).
   - Step mode: if it returns an options table, show it, wait for a choice, and send the choice back.
3. **Verify:**
   - `units.md` has a context pack for every unit, and every AC from `request.md` is in a unit
   - `design.md`, ADRs and the contract change exist only where needed (`${CLAUDE_PLUGIN_ROOT}/reference/docs.md`)
   - no options debate, empty section or template guidance was written into a file
4. Set `units_total` in `state.yaml` to the number of units.
5. **Planning gate summary** (≤ 15 lines): decisions and ADRs, contract changes, units in order with parallel
   groups, and uncovered ACs (there should be none).
   - Step mode: ask **"Approve planning gate for CR-NNN?"** On yes, set `gate_planning: approved`,
     `gate_planning_by`, `gate_planning_date`, and status `implementation`.
   - AUTO MODE: set `gate_planning: auto`, `gate_planning_by: claude-auto`, the date, and status `implementation`.
6. **Next step:** `/aidlc-forge:implementation <first unit>`, or `/aidlc-forge:auto continue` to implement every unit.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
