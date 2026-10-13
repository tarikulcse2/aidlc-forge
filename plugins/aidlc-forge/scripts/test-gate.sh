#!/usr/bin/env bash
# aidlc Stop hook (quality gate).
# If code changed since the last green run, run `test_fast` from .aidlc/config.yaml.
# On failure, exit 2 so Claude sees the failures and keeps fixing instead of finishing.
# Does nothing in projects without .aidlc/config.yaml, so it's safe to enable the plugin everywhere.

. "$(dirname "$0")/lib.sh"
payload="$(cat)"

# Already continuing because of this hook: don't loop.
printf '%s' "$payload" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true' && exit 0

cd "$(to_posix "${CLAUDE_PROJECT_DIR:-$PWD}")" || exit 0
cfg=".aidlc/config.yaml"
[ -f "$cfg" ] || exit 0
[ "$(cfg_get "$cfg" test_gate)" = "off" ] && exit 0

# A CR is being implemented: units run only their own tests, and the full suite runs once in the testing phase.
# Don't test after every turn in the meantime.
for s in docs/changes/*/state.yaml; do
  [ -f "$s" ] && [ "$(cfg_get "$s" status)" = "implementation" ] && exit 0
done

cmd="$(cfg_get "$cfg" test_fast)"
[ -n "$cmd" ] || cmd="$(cfg_get "$cfg" test_all)"
[ -n "$cmd" ] || exit 0

marker=".aidlc/.last-green"
# Nothing changed since the last green run (fast or full), e.g. a docs-only phase: skip.
[ -f "$marker" ] && [ -z "$(code_changed_since "$marker")" ] && exit 0

if output="$(bash -c "$cmd" 2>&1)"; then
  touch "$marker"
  exit 0
fi

{
  echo "aidlc test gate: '$cmd' failed. Fix the code (not the tests) before finishing."
  printf '%s\n' "$output" | failure_details
} >&2
exit 2
