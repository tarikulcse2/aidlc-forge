#!/usr/bin/env bash
# AI-DLC status across one or many projects, as Markdown on stdout.
#   bash portfolio.sh [dir ...]
# A dir that contains .aidlc/config.yaml is reported as a project. Any other dir is scanned for projects
# up to 3 levels deep. Default: the current project.

. "$(dirname "$0")/lib.sh"

roots=("$@"); [ ${#roots[@]} -gt 0 ] || roots=("${CLAUDE_PROJECT_DIR:-$PWD}")
projects=()
for r in "${roots[@]}"; do
  r="$(to_posix "$r")"
  if [ -f "$r/.aidlc/config.yaml" ]; then projects+=("$r"); continue; fi
  while IFS= read -r c; do projects+=("$(dirname "$(dirname "$c")")"); done < <(
    find "$r" -maxdepth 4 -path '*/.aidlc/config.yaml' -not -path '*/node_modules/*' 2>/dev/null | sort)
done

gate() { case "$1" in approved) echo "✅" ;; auto) echo "🤖" ;; n/a) echo "–" ;; pending|"") echo "⏳" ;; *) echo "$1" ;; esac; }

echo "| Project | CR | Title | Track | Status | Requirements gate | Planning gate | Deploy gate | Units | Updated | Last test run |"
echo "|---|---|---|---|---|---|---|---|---|---|---|"
attention=""
for p in "${projects[@]}"; do
  name="$(cfg_get "$p/.aidlc/config.yaml" project)"; [ -n "$name" ] || name="$(basename "$p")"
  reg="–"
  if [ -f "$p/docs/ops/test-report.md" ]; then
    reg="$(grep -m1 -E '^\| *Verdict' "$p/docs/ops/test-report.md" | cut -d'|' -f3 | sed 's/^ *//; s/ *$//')"
    when="$(grep -m1 -E '^\| *Date' "$p/docs/ops/test-report.md" | cut -d'|' -f3 | sed 's/^ *//; s/ *$//' | cut -c1-10)"
    reg="${reg:-?} ${when}"
    case "$reg" in *RED*) attention+="- **$name**: the last regression is RED"$'\n' ;; esac
  fi
  open=0
  while IFS= read -r crd; do s="$crd/state.yaml"
    [ -f "$s" ] || continue
    g() { cfg_get "$s" "$1"; }
    [ "$(g status)" = "closed" ] && continue
    open=$((open + 1))
    echo "| $name | $(cr_label "$s") | $(g title) | $(g track) | $(g status) | $(gate "$(g gate_requirements)") | $(gate "$(g gate_planning)") | $(gate "$(g gate_deploy)") | $(g units_done)/$(g units_total) | $(g updated) | $reg |"
    for k in gate_requirements gate_planning gate_deploy; do
      [ "$(g $k)" = "auto" ] && attention+="- **$name $(cr_label "$s")**: the ${k#gate_} gate was auto-approved and needs a human to ratify it (\`/aidlc-forge:step\`)"$'\n'
    done
  done < <(cr_dirs "$p")
  [ "$open" -eq 0 ] && echo "| $name | – | no open change requests | | | | | | | | $reg |"
done

[ ${#projects[@]} -eq 0 ] && echo "| (no projects with .aidlc/config.yaml found) | | | | | | | | | | |"
if [ -n "$attention" ]; then echo; echo "**Needs attention**"; printf '%s' "$attention"; fi
