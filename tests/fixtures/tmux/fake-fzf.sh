#!/bin/sh
set -eu

for argument in "$@"; do
  if [ "$argument" = --help ]; then
    printf '%s\n' '  --footer=STR'
    exit 0
  fi
done

[ -n "${ENTORNO_TMUX_TEST_FZF_MARKER:-}" ] || exit 2
if [ -e "$ENTORNO_TMUX_TEST_FZF_MARKER" ]; then
  printf '%s\n' repetido >> "$ENTORNO_TMUX_TEST_FZF_MARKER"
  exit 1
fi

printf '%s\n' usado > "$ENTORNO_TMUX_TEST_FZF_MARKER"
awk -F '\t' \
  -v selected="${ENTORNO_TMUX_TEST_FZF_CHOICE:-shell}" \
  -v capture="${ENTORNO_TMUX_TEST_FZF_INPUT:-}" '
  {
    if (capture != "") print > capture
    if (!found && $2 == selected) {
      chosen = $0
      found = 1
    }
  }
  END {
    if (found) print chosen
    exit !found
  }
'
