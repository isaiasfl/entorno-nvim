#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
XDG_ROOT="$PROJECT_ROOT/.xdg"

if ! command -v nvim >/dev/null 2>&1; then
  printf '%s\n' "Error: nvim no esta disponible en PATH." >&2
  exit 1
fi

mkdir -p \
  "$XDG_ROOT/data/nvim" \
  "$XDG_ROOT/state/nvim/undo" \
  "$XDG_ROOT/state/nvim/swap" \
  "$XDG_ROOT/cache/nvim"

export XDG_CONFIG_HOME="$PROJECT_ROOT"
export XDG_DATA_HOME="$XDG_ROOT/data"
export XDG_STATE_HOME="$XDG_ROOT/state"
export XDG_CACHE_HOME="$XDG_ROOT/cache"
export ENTORNO_NVIM_ROOT="$PROJECT_ROOT"
export APPIMAGE_EXTRACT_AND_RUN="${APPIMAGE_EXTRACT_AND_RUN:-1}"

exec nvim "$@"
