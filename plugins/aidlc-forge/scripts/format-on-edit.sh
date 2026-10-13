#!/usr/bin/env bash
# aidlc PostToolUse hook: run `format_file` from .aidlc/config.yaml on the file Claude just edited,
# when its extension is listed in `code_exts`. Never blocks Claude: always exits 0.

. "$(dirname "$0")/lib.sh"
payload="$(cat)"

cd "$(to_posix "${CLAUDE_PROJECT_DIR:-$PWD}")" || exit 0
cfg=".aidlc/config.yaml"
[ -f "$cfg" ] || exit 0

cmd="$(cfg_get "$cfg" format_file)"
[ -n "$cmd" ] || exit 0

file="$(printf '%s' "$payload" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
file="$(printf '%s' "$file" | sed 's#\\\\#/#g')"   # JSON-escaped backslashes -> forward slashes
[ -n "$file" ] && [ -f "$file" ] || exit 0

ext="${file##*.}"
case " $(cfg_get "$cfg" code_exts) " in
  *" $ext "*) bash -c "${cmd//\{FILE\}/\"$file\"}" >/dev/null 2>&1 ;;
esac

exit 0
