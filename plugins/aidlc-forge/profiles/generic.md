# Stack profile: generic

The fallback when no specific profile matches. `/aidlc-forge:init` fills in the commands by asking the human, or by
reading the build files (`package.json` scripts, `pyproject.toml`, `go.mod`, `pom.xml`, `Makefile`).

## Detect
Always matches, so it's checked last.

## Config defaults
| Key | How to fill it |
|---|---|
| build | the project's build or compile command (or `echo no build` for interpreted languages) |
| test_all | the full test command |
| test_fast | the unit-test subset, which must take under 60 s (else the same as test_all) |
| test_story | the test runner's name filter with `{ID}`, e.g. `npm test -- -t "{ID}"` or `pytest -k {ID}` |
| format_file | the formatter for one file with `{FILE}`, or leave it empty |
| code_dirs / test_dirs / code_exts | where the source and tests are, and their file extensions |

## Conventions
- Follow the existing patterns in the codebase. They take priority over general preferences.
- Validate input at the boundaries. Expected errors return stable error codes.
- Inject the clock and external clients so tests are deterministic.
- Tests are named `USnnn_ACk_<behaviour>`, adapted to the language's naming rules, as long as the `USnnn_`
  prefix stays searchable.
