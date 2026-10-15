#!/usr/bin/env bash
# Append one event to .aidlc/progress.log, the live progress of a run (read by scripts/aidlc/watch.ps1).
#   bash progress.sh "<handle>" "<EVENT>" "<detail>"
# EVENT is one of: RUN START, STEP START, STEP DONE, UNIT START, UNIT DONE, UNIT STOP, TESTS, HARD STOP, RUN COMPLETE
# (written by the main session), or PROGRESS (written by agents: tests red/green, attempts, review verdict).
# Line format: 2026-10-13T10:00:00Z | CR-006-leave-emails | UNIT DONE | U-02 Outbox table 2/3 in 00:02:25
# Durations: STEP DONE, UNIT DONE, UNIT STOP and RUN COMPLETE get " in HH:MM:SS", measured from the matching
#   STEP START (same step name), UNIT START (same U-NN) or RUN START. The logged line is printed on stdout,
#   so the caller can repeat it (e.g. in chat).
# Never fails the caller: logging must not break a run.

. "$(dirname "$0")/lib.sh"
cd "$(to_posix "${CLAUDE_PROJECT_DIR:-$PWD}")" 2>/dev/null || exit 0
[ -d .aidlc ] || exit 0
log=.aidlc/progress.log
handle="${1:--}"; event="${2:-NOTE}"; detail="${3:-}"
# Keep each entry on one line, and the separator unambiguous.
detail="$(printf '%s' "$detail" | tr '\r\n|' '  /' | cut -c1-200)"
now_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
now_s="$(date -u +%s)"

# start_of PATTERN: timestamp (epoch seconds) of the last log line matching PATTERN (an awk regex; use [|] for a
# literal pipe), counting only lines since the last RUN START, so an earlier run never matches.
start_of() {
  [ -f "$log" ] || return 0
  local ts
  ts="$(awk -v pat="$1" '/[|] RUN START [|]/ { last = "" } $0 ~ pat { last = $0 } END { if (last != "") print last }' "$log" |
        cut -d"|" -f1 | tr -d " ")"
  [ -n "$ts" ] && date -u -d "$ts" +%s 2>/dev/null
}
hms() { printf '%02d:%02d:%02d' $(( $1 / 3600 )) $(( $1 % 3600 / 60 )) $(( $1 % 60 )); }

start=""
case "$event" in
  "STEP DONE")
    step="$(printf '%s' "$detail" | sed 's/[: ].*//')"
    [ -n "$step" ] && start="$(start_of "[|] STEP START [|] ${step}( |:|\$)")" ;;
  "UNIT DONE"|"UNIT STOP")
    unit="$(printf '%s' "$detail" | grep -oE '^U-[0-9]+')"
    [ -n "$unit" ] && start="$(start_of "[|] UNIT START [|] ${unit}( |:|\$)")" ;;
  "RUN COMPLETE")
    start="$(start_of '[|] RUN START [|]')" ;;
esac
if [ -n "$start" ] && [ "$start" -le "$now_s" ] && ! printf '%s' "$detail" | grep -qE ' in [0-9]{2}:[0-9]{2}:[0-9]{2}$'; then
  detail="$detail in $(hms $(( now_s - start )))"
fi

line="$(printf '%s | %s | %s | %s' "$now_iso" "$handle" "$event" "$detail")"
printf '%s\n' "$line" >> "$log" 2>/dev/null
printf '%s\n' "$line"
exit 0
