---
name: discovery
description: AI-DLC brownfield onboarding. Reverse-engineer the as-is baseline (stories, ACs, NFRs, architecture, contract, decisions) of an existing codebase for human review, as CR-000.
argument-hint: [area to focus on, e.g. a module or folder]  (default: whole repo)
disable-model-invocation: true
allowed-tools: Bash(bash "${CLAUDE_PLUGIN_ROOT}/scripts/*)
---

Reverse-engineer the as-is baseline of this codebase (focus: **$ARGUMENTS**, default the whole repo).

**Setup:** `.aidlc/config.yaml` must exist (otherwise run `/aidlc-forge:init`). `docs/baseline/stories.md` must not
exist yet, or the focus must be an area it doesn't cover yet.

1. Create `docs/changes/CR-000-baseline/state.yaml` from `${CLAUDE_PLUGIN_ROOT}/templates/state.yaml`, with
   `id: CR-000`, `handle: CR-000-baseline`, track `full`, status `requirements`, and the title "As-is baseline".
2. **Delegate** to the `discovery-analyst` agent with the focus.
   - For a modular codebase with more than 3 modules, run one agent per module (they can run in parallel),
     each writing a section of `stories.md`. Then merge the sections and number the stories consistently.
3. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/trace.sh" > docs/traceability.md`.
4. Set gate_requirements and gate_planning to `auto` (`_by: claude-discovery`), gate_deploy `n/a`, `units_total: 0`, and status `deploy`.
   A human ratifies the baseline with `/aidlc-forge:step`, then closes CR-000 with `/aidlc-forge:close CR-000`.
5. **Summary:** features, stories and ACs, the share of stories covered by tests (from trace.sh), and the top
   risks and unknowns. Suggest:
   - backfilling tests for ❌ stories as a lite CR (`/aidlc-forge:requirements Backfill tests for US-...`)
   - starting real work with `/aidlc-forge:requirements <change>`

**Last line of your report (step mode only, not in auto runs):**
`Tip: run /clear before the next step. Everything it needs is in the files.`
