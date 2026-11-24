#!/usr/bin/env bash
# Claude Code Stop hook: appends ONE line (timestamp + changed files) to docs/ai-activity.log.
# - no AI call, no network, never blocks the session
# - always exits 0, also without git or outside a git worktree
# - does not read stdin (the hook JSON payload is ignored)
# Manual test:  bash .claude/hooks/log-activity.sh TEST   -> line is tagged "Stop TEST"
{
  dir="${CLAUDE_PROJECT_DIR:-}"
  if [ -z "$dir" ] || [ ! -d "$dir" ]; then
    dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
  fi
  cd "$dir" 2>/dev/null || exit 0
  [ -d docs ] || exit 0

  log="docs/ai-activity.log"
  ts="$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null)"; [ -n "$ts" ] || ts="?"
  tag="Stop"; [ -n "${1:-}" ] && tag="Stop $1"

  info="git: nicht verfuegbar"
  if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # coreutils timeout only (Windows has an unrelated timeout.exe)
    if timeout --version >/dev/null 2>&1; then
      st="$(timeout 5 git -c core.quotepath=off status --short --untracked-files=normal 2>/dev/null)"
    else
      st="$(git -c core.quotepath=off status --short --untracked-files=normal 2>/dev/null)"
    fi
    st="$(printf '%s\n' "$st" | grep -v -e 'docs/ai-activity\.log' -e '^[[:space:]]*$' | sed 's/^[[:space:]]*//')"
    if [ -z "$st" ]; then
      info="git: keine Aenderungen"
    else
      n="$(printf '%s\n' "$st" | wc -l | tr -d '[:space:]')"
      list="$(printf '%s\n' "$st" | head -n 15 | tr '\n' ';' | sed 's/;$//; s/;/; /g')"
      [ "$n" -gt 15 ] 2>/dev/null && list="$list; ... +$((n-15)) weitere"
      info="git: $n Aenderung(en) | $list"
    fi
  fi

  if [ ! -f "$log" ]; then
    printf '%s\n' "# Automatisch vom Claude-Code-Stop-Hook (.claude/hooks/log-activity.sh). Format: Zeit | Ereignis | git-Status (ohne diese Datei)" >> "$log"
  fi
  printf '%s | %s | %s\n' "$ts" "$tag" "$info" >> "$log"
} </dev/null >/dev/null 2>&1
exit 0
