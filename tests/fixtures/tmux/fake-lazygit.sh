#!/bin/sh
set -eu

[ -n "${ENTORNO_TMUX_TEST_LAZYGIT_CWD:-}" ] || exit 2
/bin/pwd -P > "$ENTORNO_TMUX_TEST_LAZYGIT_CWD"
exec /bin/sleep 60
