#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION"}

all_locked=1
plugin_count=0
while IFS=' ' read -r plugin commit; do
  [ -n "$plugin" ] || continue
  plugin_count=$((plugin_count + 1))
  actual=$(git -C "$XDG_ROOT/data/nvim/lazy/$plugin" rev-parse HEAD 2>/dev/null || true)
  if [ "$actual" != "$commit" ]; then all_locked=0; break; fi
done <<EOF
$(sed -n 's/^[[:space:]]*"\([^"]*\)":.*"commit": "\([0-9a-f]*\)".*/\1 \2/p' "$PROJECT_ROOT/nvim/lazy-lock.json")
EOF

if [ "$all_locked" -eq 1 ] && [ "$plugin_count" -gt 0 ]; then
  printf '%s\n' "Plugins Neovim ya instalados en las revisiones fijadas."
  exit 0
fi

# restore respeta lazy-lock.json; no actualiza las revisiones fijadas.
"$SCRIPT_DIR/arrancar.sh" --headless "+Lazy! restore" "+qa"
