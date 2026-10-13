---
name: requirements
description: AI-DLC phase 1 (requirements). Open a change request (CR) for a feature or change, write its delta stories and ACs, and run the requirements gate. Use when someone asks for a new feature or change in an aidlc project. For a bug, prefer /aidlc-forge:bug-fix; for a small change (1 story, up to 3 ACs), /aidlc-forge:quick.
argument-hint: <intent, feature, change request or bug>
---

Open a change request for: **$ARGUMENTS**

**Setup:** read `${CLAUDE_PLUGIN_ROOT}/reference/core.md` (once per session) and `.aidlc/config.yaml`.
If the config is missing, stop and suggest `/aidlc-forge:init`.

1. **Name it** (core.md: CR naming): the next `CR-NNN` (3 digits), a 2–4 word kebab-case slug, and the handle
   `CR-NNN-<slug>`. If the intent mentions a ticket key or link, keep it for `ticket:`.
2. **Propose a track** (lite, standard or full, see `${CLAUDE_PLUGIN_ROOT}/reference/tracks.md`) with a one-line reason. If it's a bug or a small
   change (one story, ≤ 3 ACs, no contract or data change), say that `/aidlc-forge:bug-fix` or `/aidlc-forge:quick` is faster, and ask once
   whether to switch (in AUTO MODE, continue).
3. **Branch** (git repos only): `aidlc/CR-NNN-<slug>` from `base_branch`.
   - Step mode: ask first.
   - AUTO MODE: create it if `git status --porcelain` is empty, otherwise hard stop.
4. **Create** `docs/changes/CR-NNN-<slug>/state.yaml` from `${CLAUDE_PLUGIN_ROOT}/templates/state.yaml`:
   `id`, `handle`, `ticket` (if any), status `requirements`, the track, the branch, gate_planning `n/a` for lite.
5. **Delegate** to the `requirements-analyst` agent (model per core.md: Model routing). Pass it the intent, CR folder, track, and mode (prefix
   `AUTO MODE.` in auto runs).
   - Step mode: show its clarifying questions **exactly as returned**, stop, and wait for answers. Then send it
     the answers so it can write `request.md`.
6. **Lite track only:** run the `planner` agent (sonnet in every profile, for one unit) to write `units.md` with the single unit
   (requirements gate covers the design for lite CRs).
7. **Requirements gate summary** (≤ 15 lines): new and changed stories with AC counts, NFR changes, assumptions,
   decisions taken by default, open questions, and the track.
   - Step mode: ask **"Approve requirements gate for CR-NNN?"** On yes, set `gate_requirements: approved`, `gate_requirements_by` (`git config user.name`)
     and `gate_requirements_date`, and set status to `planning` (lite: status `implementation`, `units_total: 1`).
   - AUTO MODE: set `gate_requirements: auto`, `gate_requirements_by: claude-auto` and the date, and advance the status the same way.
8. **Next step:** lite → `/aidlc-forge:implementation <U-NN>`; otherwise → `/aidlc-forge:planning CR-NNN`.

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
