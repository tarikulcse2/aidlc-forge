#!/usr/bin/env bash
# Managed by the aidlc-forge plugin (templates/scripts/statusline.sh, v3.5.0). Re-run /aidlc-forge:init to update.
# Claude Code status line for aidlc-forge: one live line about the current AI-DLC run, e.g.
#   aidlc ▶ CR-006-admin-login · implementation · U-12 (2/3) · coder: green after 1 attempt · 00:16:40
# Reads the status line JSON on stdin (for the project dir), then .aidlc/progress.log and the CR's state.yaml.
# Prints nothing when the project has no aidlc run. Read-only, no AI. Must be fast: it runs every ~2 seconds.
# Installed by /aidlc-forge:init into .claude/settings.local.json as:
#   "statusLine": { "type": "command", "command": "bash \"<project>/scripts/aidlc/statusline.sh\"", "refreshInterval": 3 }

input="$(cat 2>/dev/null)"
dir="$(printf '%s' "$input" | sed -n 's/.*"project_dir"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$dir" ] || dir="$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$dir" ] || dir="${CLAUDE_PROJECT_DIR:-$PWD}"
dir="$(printf '%s' "$dir" | sed 's#\\\\#/#g')"
command -v cygpath >/dev/null 2>&1 && dir="$(cygpath -u "$dir" 2>/dev/null || printf '%s' "$dir")"
cd "$dir" 2>/dev/null || exit 0
log=.aidlc/progress.log
[ -f "$log" ] || exit 0

# Lines of the current run (since the last RUN START).
run="$(awk '/[|] RUN START [|]/ { buf = "" } { buf = buf $0 "\n" } END { printf "%s", buf }' "$log")"
[ -n "$run" ] || exit 0
first="$(printf '%s' "$run" | head -n 1)"
last="$(printf '%s' "$run" | tail -n 1)"
field() { printf '%s' "$1" | cut -d'|' -f"$2" | sed 's/^ *//; s/ *$//'; }
to_s() { date -u -d "$1" +%s 2>/dev/null || echo 0; }
hms() { printf '%02d:%02d:%02d' $(( $1 / 3600 )) $(( $1 % 3600 / 60 )) $(( $1 % 60 )); }
now="$(date -u +%s)"
t_start="$(to_s "$(field "$first" 1)")"
t_last="$(to_s "$(field "$last" 1)")"

# Finished run: show it for 30 minutes, then go quiet.
if [ "$(field "$last" 3)" = "RUN COMPLETE" ] || [ "$(field "$last" 3)" = "RUNNER VERDICT" ]; then
  [ $(( now - t_last )) -le 1800 ] || exit 0
  printf 'aidlc 🏁 %s · %s\n' "$(field "$last" 2)" "$(field "$last" 4)"
  exit 0
fi

handle="$(printf '%s' "$run" | awk -F'|' '{ h = $2; gsub(/^ +| +$/, "", h); if (h != "-") last = h } END { print last }')"
status=""; units=""
state="docs/changes/$handle/state.yaml"
if [ -n "$handle" ] && [ -f "$state" ]; then
  status="$(sed -n 's/^status:[[:space:]]*//p' "$state" | head -n 1 | tr -d '\r')"
  done_n="$(sed -n 's/^units_done:[[:space:]]*//p' "$state" | head -n 1 | tr -d '\r')"
  total_n="$(sed -n 's/^units_total:[[:space:]]*//p' "$state" | head -n 1 | tr -d '\r')"
  [ -n "$total_n" ] && [ "$total_n" != "0" ] && units="${done_n:-0}/${total_n}"
fi

# Current unit: the last UNIT START without a later DONE/STOP for the same unit.
unit="$(printf '%s' "$run" | awk -F'|' '
  { ev = $3; gsub(/^ +| +$/, "", ev); d = $4; gsub(/^ +| +$/, "", d); split(d, w, " ") }
  ev == "UNIT START" { cur = d; id = w[1] }
  (ev == "UNIT DONE" || ev == "UNIT STOP") && w[1] == id { cur = ""; id = "" }
  END { print cur }')"
unit_id="$(printf '%s' "$unit" | awk '{print $1}')"

# Unit title, without the id and a trailing "(n/m)".
unit_title="$(printf '%s' "$unit" | sed "s/^${unit_id} *//; s/ *([0-9]*\/[0-9]*)$//" | cut -c1-40)"

# Latest activity: the newest PROGRESS line for the current unit (or, between units, the newest event),
# skipping the unit's own UNIT START (its title is shown already).
act="$(printf '%s' "$run" | awk -F'|' -v uid="$unit_id" '
  { ev = $3; gsub(/^ +| +$/, "", ev); d = $4; gsub(/^ +| +$/, "", d); split(d, w, " ") }
  ev == "PROGRESS" && (uid == "" || w[1] == uid) { a = d; next }
  ev == "UNIT START" && w[1] == uid { a = ""; next }
  ev != "PROGRESS" { a = (uid == "" ? ev ": " d : a) }
  END { print a }')"
act="$(printf '%s' "$act" | sed "s/^${unit_id} //" | cut -c1-60)"

line="aidlc ▶ ${handle:-new CR}"
[ -n "$status" ] && line="$line · $status"
[ -n "$unit_id" ] && line="$line · $unit_id${unit_title:+ $unit_title}${units:+ ($units)}"
[ -z "$unit_id" ] && [ -n "$units" ] && line="$line · units $units"
[ -n "$act" ] && line="$line · $act"
[ "$t_start" -gt 0 ] && line="$line · $(hms $(( now - t_start )))"
quiet=$(( (now - t_last) / 60 ))
[ "$t_last" -gt 0 ] && [ "$quiet" -ge 10 ] && line="$line · ⚠ no events for ${quiet} min"
printf '%s\n' "$line"
exit 0
