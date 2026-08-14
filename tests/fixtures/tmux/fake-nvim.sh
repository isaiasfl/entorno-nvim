#!/bin/sh

if [ -n "${ENTORNO_TMUX_TEST_NVIM_ARGS_FILE:-}" ]; then
  printf '%s\n' "$#" > "$ENTORNO_TMUX_TEST_NVIM_ARGS_FILE"
fi

exit 0
