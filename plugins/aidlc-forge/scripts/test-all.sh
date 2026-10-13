#!/usr/bin/env bash
# Run the full test suite (`test_all` from .aidlc/config.yaml) once, and print only a compact result.
#   bash test-all.sh [--fresh] [project_dir]
#
# By default it REUSES: if the last full run was green and no code file changed since, it prints that result
# instantly and doesn't run the suite again. --fresh forces a real run (e.g. a flaky environment, a new machine).
# (--reuse is still accepted; it's the default now.)
# Writes .aidlc/last-test-all.txt (date, command, result, summary) and the full log to .aidlc/last-test-all.log.
# A green run also refreshes the Stop hook's marker, because the fast tests are a subset of the full suite.
# Exit code: 0 = green (or reused green), 1 = red or not configured.

. "$(dirname "$0")/lib.sh"
reuse=1
case "$1" in
  --fresh) reuse=0; shift ;;
  --reuse) shift ;;
esac
cd "$(to_posix "${1:-${CLAUDE_PROJECT_DIR:-$PWD}}")" || exit 1

cfg=".aidlc/config.yaml"
rec=".aidlc/last-test-all.txt"
log=".aidlc/last-test-all.log"
cmd="$(cfg_get "$cfg" test_all)"
[ -n "$cmd" ] || { echo "RED: no test_all in $cfg (run /aidlc-forge:init)"; exit 1; }

if [ "$reuse" -eq 1 ] && [ -f "$rec" ] && [ "$(cfg_get "$rec" result)" = "green" ] && [ -z "$(code_changed_since "$rec")" ]; then
  echo "GREEN (reused): $(cfg_get "$rec" summary) - no code changes since the full run at $(cfg_get "$rec" date)"
  exit 0
fi

start=$(date +%s)
if output="$(bash -c "$cmd" 2>&1)"; then result=green; else result=red; fi
secs=$(( $(date +%s) - start ))
printf '%s\n' "$output" > "$log"

# Test-runner summary lines (e.g. dotnet "Passed!  - Failed: 0, Passed: 60 ..."), joined.
summary="$(printf '%s\n' "$output" | tr -d '\r' | grep -E -i "^(passed|failed)!|tests? (passed|failed)|[0-9]+ (passed|failed)" \
  | sed 's/ - [^ ]*\.dll.*//; s/[[:space:]]\+/ /g' | head -n 5 | paste -sd ';' -)"
[ -n "$summary" ] || summary="(no summary line found; see $log)"

mkdir -p .aidlc
{
  echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "command: $cmd"
  echo "result: $result"
  echo "seconds: $secs"
  echo "summary: $summary"
} > "$rec"

if [ "$result" = green ]; then
  touch .aidlc/.last-green
  echo "GREEN: $summary (${secs}s)"
  exit 0
fi
echo "RED: $summary (${secs}s). Full log: $log"
printf '%s\n' "$output" | failure_details
exit 1
