#!/bin/sh
set -eu

[ -n "${ENTORNO_TMUX_TEST_FZF_MARKER:-}" ] || exit 2
if [ -e "$ENTORNO_TMUX_TEST_FZF_MARKER" ]; then
  printf '%s\n' repetido >> "$ENTORNO_TMUX_TEST_FZF_MARKER"
  exit 1
fi

printf '%s\n' usado > "$ENTORNO_TMUX_TEST_FZF_MARKER"
awk -F '\t' -v selected="${ENTORNO_TMUX_TEST_FZF_CHOICE:-shell}" '$2 == selected { print; found = 1; exit } END { exit !found }'
