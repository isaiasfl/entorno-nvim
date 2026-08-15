#!/bin/sh
set -eu

[ "$#" -eq 1 ] || exit 0
[ -n "${TMUX:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

session=$1
project=$(tmux show-option -v -t "$session" @entorno_project_root 2>/dev/null) || project=
agent=$(tmux list-panes -s -t "$session" -F '#{@entorno_role}	#{@entorno_agent}' 2>/dev/null |
  awk -F '	' '$1 == "agent" { count++; value = $2 } END { if (count == 1) print value }') || agent=

case "$agent" in
  codex) agent_label=Codex ;;
  opencode) agent_label=OpenCode ;;
  claude) agent_label=Claude ;;
  pi) agent_label=Pi ;;
  shell) agent_label=Shell ;;
  *) agent_label=- ;;
esac

git_label=
if [ -n "$project" ] && [ -d "$project" ] &&
  GIT_OPTIONAL_LOCKS=0 git -C "$project" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$project" symbolic-ref --quiet --short HEAD 2>/dev/null || true)
  if [ -z "$branch" ]; then
    branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$project" rev-parse --short HEAD 2>/dev/null || true)
  fi
  branch=$(printf '%s' "$branch" | LC_ALL=C tr -d '\000-\037\177' | sed 's/[#|]/-/g' | cut -c 1-32)
  if [ -n "$branch" ]; then
    dirty=$(GIT_OPTIONAL_LOCKS=0 git -C "$project" status --porcelain=v1 --untracked-files=no 2>/dev/null |
      sed -n '1p')
    git_label="git:$branch"
    [ -z "$dirty" ] || git_label="$git_label *"
  fi
fi

if [ -n "$git_label" ]; then
  printf '%s | AI:%s' "$git_label" "$agent_label"
else
  printf 'AI:%s' "$agent_label"
fi
