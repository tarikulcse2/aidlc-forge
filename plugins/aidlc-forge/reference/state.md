# state.yaml, status flow, gates and phase entry

## state.yaml (flat `key: value`; scripts grep it; template: `templates/state.yaml`)
`id` (`CR-NNN`), `handle` (`CR-NNN-<slug>`, the displayed name), `ticket` (optional key), `title`, `track`, `status`, `gate_requirements` / `gate_planning` / `gate_deploy` (each with `_by` and `_date`),
`units_total`, `units_done`, `branch`, `updated` (set on every change).

## Status flow
`requirements` → `planning` → `implementation` → `testing` → `deploy` → `closed`
- Lite, bug-fix and quick CRs skip `planning`.
- `implementation` → `testing`: when the last unit is ✅.
- `testing` → `deploy`: when `/aidlc-forge:testing all` is GREEN.

## Gates
- **Names:** gates are named after the phase they close: `gate_requirements`, `gate_planning` (`n/a` for lite,
  bug-fix and quick), `gate_deploy`. The pull-request review is the implementation gate, and it lives in git.
- **Values:** `pending` | `auto` (🤖 set in auto mode; a human must ratify it) | `approved` | `n/a`.
- **Who sets them:** only a human's explicit yes sets `approved`. Record `_by` (`git config user.name`, or
  "human") and `_date`. Auto mode writes `auto` with `_by: claude-auto`. Bug-fix and quick record
  `gate_requirements: approved` with `_by: <user> (via /aidlc-forge:<command>)`.

## Phase entry
| Phase | Needs |
|---|---|
| planning | gate_requirements `approved` (or `auto` in an auto run) |
| implementation | standard/full: gate_planning. Lite, bug-fix and quick: gate_requirements. Either `approved`, or `auto` in an auto run. All dependencies ✅. |
| testing | every unit ✅. Can also be run at any time as a regression check. |
| deploy | status `deploy`, with a GREEN test report |
| close | gate_deploy `approved` or `n/a`. Human-only; never in auto mode. |

In step mode, every `auto` gate is ratified before work continues past it.
