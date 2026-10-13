# Git rules

- **Branch:** each CR is built on `aidlc/<handle>` (e.g. `aidlc/CR-005-admin-login`), created from `base_branch`.
  - Step mode: ask before creating it.
  - Auto mode: create it if the working tree is clean, otherwise hard stop.
- **Commits:** after each green, reviewed unit:
  - auto mode commits locally with `feat(CR-NNN U-NN): <title> [US-xxx, ...]`
  - step mode proposes that message and commits only on a yes
  - bug-fix uses `fix(CR-NNN): ...`
  - never push
- **Protected-test check:** `git diff $(git merge-base HEAD <base_branch>) -- <test_dirs>`, plus uncommitted changes.
  Removed or changed assertions are allowed only for ACs that the CR marks as changed *(CR-NNN)*. Anything else is
  ⚠ a weakened test: a hard stop in auto mode, or a question to the human in step mode.
- **No git:** the process still runs. Checks that need git are reported as "skipped (no git)".
