# Baseline document skeletons

`/aidlc-forge:discovery` and full-track CRs create these in `docs/baseline/`. Keep each one short. Baseline documents
describe the current truth, not history (history lives in `docs/changes/` and git).

## prd.md
```
# PRD: <product>
## Problem
## Goals and metrics        | Goal | Metric | Target |
## Personas
## Scope                    In / Out
## Assumptions              A1 ...
## Decision log             | Date | CR | Decision (one line) |
## Unknowns and risks       (reverse-engineered baselines only)
```

## stories.md
```
# Stories
## <Feature area>
## US-NNN <title> (M/S/C) (since CR-NNN)
**As a** ... **I want** ... **so that** ...
| # | Given | When | Then |
|---|---|---|---|
| AC1 | ... | ... | ... |
Covered by: LegacyTestName1, LegacyTestName2      (only for tests not named USnnn_*)
```

## nfr.md
```
| ID | Category | Requirement | How it's verified |
```

## architecture.md
```
# Architecture
## Context (C4 level 1, Mermaid)
## Components (C4 level 2–3, Mermaid)
## Folder layout
## Key flows (sequence diagrams)
## Error model             | Kind | HTTP | Codes |
## Decisions               links to adr/
```
