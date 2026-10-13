<!-- aidlc:start (managed by the aidlc-forge plugin; edit outside these markers) -->
## AI-DLC process
This repo follows AI-DLC using the `aidlc-forge` plugin. Settings are in `.aidlc/config.yaml`, and the rules are in the plugin's `reference/core.md`.

- **Step by step:** `/aidlc-forge:step` runs one step at a time and asks you at every gate.
  **Automatic:** `/aidlc-forge:auto continue` runs every remaining step with no questions. `/aidlc-forge:custom-workflow`
  lets you choose the steps. Unattended: `scripts/aidlc/aidlc-auto.ps1`. It never pushes, deploys or closes.
- **Shortcuts:** `/aidlc-forge:bug-fix <bug>`, `/aidlc-forge:quick <small change>` (one stop: commit), `/aidlc-forge:planning <spec>` (straight to planning).
- **Work** is organised as change requests in `docs/changes/CR-NNN-*/`. The approved truth is in `docs/baseline/`.
- **Never invent requirements.** Code behaviour must trace to an AC. Tests are named `USnnn_ACk_<Behaviour>`.
- **Contract first.** Update the API contract (`contract` in the config) before changing endpoints.
- **Never weaken, skip or delete a test** to get to green.
- Status: `/aidlc-forge:status`. All projects: `/aidlc-forge:portfolio`.
<!-- aidlc:end -->
