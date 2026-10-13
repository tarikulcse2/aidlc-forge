#!/usr/bin/env bash
# Shared helpers for aidlc scripts. Source it: . "$(dirname "$0")/lib.sh"

# cfg_get FILE KEY: print the value of a flat "key: value" line (CR stripped), or nothing.
cfg_get() {
  [ -f "$1" ] || return 0
  sed -n "s/^$2:[[:space:]]*//p" "$1" | head -n 1 | tr -d '\r'
}

# to_posix PATH: turn a Windows path (C:\x\y) into one Git Bash understands (/c/x/y).
to_posix() {
  local p="$1"
  if command -v cygpath >/dev/null 2>&1; then cygpath -u "$p" 2>/dev/null && return; fi
  printf '%s\n' "$p"
}

# code_changed_since MARKER: print the first code file (code_exts under code_dirs in .aidlc/config.yaml)
# modified after MARKER, or nothing. Run from the project root.
code_changed_since() {
  local cfg=".aidlc/config.yaml" dirs exts name_expr=()
  dirs="$(cfg_get "$cfg" code_dirs)"; [ -n "$dirs" ] || dirs="."
  exts="$(cfg_get "$cfg" code_exts)"
  for e in $exts; do
    [ ${#name_expr[@]} -gt 0 ] && name_expr+=(-o)
    name_expr+=(-name "*.$e")
  done
  [ ${#name_expr[@]} -gt 0 ] || name_expr=(-name '*')
  # shellcheck disable=SC2086
  find $dirs -type f \( "${name_expr[@]}" \) -newer "$1" \
    -not -path '*/bin/*' -not -path '*/obj/*' -not -path '*/node_modules/*' -not -path '*/.git/*' \
    -print -quit 2>/dev/null
}

# failure_details: read test/build output on stdin, print only the useful failure lines (max 40).
failure_details() {
  local output details
  output="$(cat)"
  details="$(printf '%s\n' "$output" | grep -E -i "error [a-z]+[0-9]+|^ +failed |\bfail(ed)?\b|assert|^expected|^actual" | head -n 40)"
  if [ -n "$details" ]; then printf '%s\n' "$details"; else printf '%s\n' "$output" | tail -n 40; fi
}

# cr_dirs [project_dir]: print docs/changes/CR-* folders sorted by CR number (CR-05 and CR-005 both read as 5).
cr_dirs() {
  local root="${1:-.}" d n
  for d in "$root"/docs/changes/CR-*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    n="$(basename "$d" | sed -n 's/^CR-0*\([0-9][0-9]*\).*/\1/p')"
    printf '%s\t%s\n' "${n:-0}" "$d"
  done | sort -n -k1,1 | cut -f2-
}

# cr_label STATE_FILE: the CR's display name: handle (or folder name) plus " (ticket)" when set.
cr_label() {
  local h t
  h="$(cfg_get "$1" handle)"; [ -n "$h" ] && [ "$h" != "CR-NNN-slug" ] || h="$(basename "$(dirname "$1")")"
  t="$(cfg_get "$1" ticket)"
  printf '%s%s' "$h" "${t:+ ($t)}"
}
