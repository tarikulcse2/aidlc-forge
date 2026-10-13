# Tracks, naming, and which entry to use

## Tracks (one per CR; `/aidlc-forge:requirements` proposes one)
| Track | Use when | Documents | Gates | Build |
|---|---|---|---|---|
| **bug-fix** | The code contradicts an agreed (or unambiguous) behaviour; one unit; no contract, data or package change. Opened only by `/aidlc-forge:bug-fix` | `request.md` (fix note ≤ 20 lines) + `units.md` (one unit) | none to wait for (the command is the request) and "Commit?" at the end | `coder` TDD, reproducing test first |
| **quick** | One story, ≤ 3 new or changed ACs, one unit; no contract, data or package change. Opened only by `/aidlc-forge:quick` | `request.md` (≤ 25 lines) + `units.md` (one unit) | none to wait for (the command is the request) and "Commit?" at the end | `coder` TDD |
| **lite** | One S unit; no new endpoint, entity, package, ADR or NFR | `request.md` (with a design note) + `units.md` | gate_requirements (covers the design) | `coder` TDD |
| **standard** | Everything else | `request.md` → `design.md` + `units.md` | gate_requirements, gate_planning | S and M units: `coder` TDD. L units: `tester` → `coder` |
| **full** | New product, more than 8 units, or a new external system | also writes or rewrites the baseline `prd.md`, `nfr.md` and `architecture.md` | gate_requirements, gate_planning | as standard |

The `code-reviewer` agent reviews every unit on every track. The deploy gate applies when a CR is deployed.

## Which entry to use (fastest first)
1. Trivial (typo, config, message): ask Claude directly. The test-gate hook is the safety net.
2. A bug: `/aidlc-forge:bug-fix`
3. A small change: `/aidlc-forge:quick`
4. Requirements already written: `/aidlc-forge:planning <spec>`
5. Trusted defaults: `/aidlc-forge:auto`
6. Large or risky: step by step (`/aidlc-forge:step`)

## Naming convention
Names describe the **scope** they act on:

| Scope | Commands (`/aidlc-forge:<name>`) | Owning agent |
|---|---|---|
| Project, once | `init`, `discovery` | `discovery-analyst` |
| CR lifecycle phase, in SDLC order | `requirements` → `planning` → `implementation` → `testing` → `deploy` → `close` | `requirements-analyst`, `planner`, `tester` + `coder` + `code-reviewer`, –, `devops`, – |
| Ways of running the lifecycle | `step` (one step at a time), `auto` (every step, no questions), `custom-workflow` (you choose the steps) | – |
| Shortcuts into the lifecycle | `bug-fix`, `quick` (enter at implementation), `planning <spec>` (enters at planning) | as the phase entered |
| Authoring help (no lifecycle phase) | `acceptance-criteria` (draft or review ACs) | – (runs inline) |
| Read-only views | `status`, `portfolio` | – |

- Familiar names are kept where they exist: `init`, `deploy`, `close`, `bug-fix`.
- Status values and gate keys use the phase names.
- Agents are named `<area>-<role>` (e.g. `requirements-analyst`), or by a short familiar role (`planner`, `tester`, `coder`, `devops`).
- Documents are named after what they contain.
