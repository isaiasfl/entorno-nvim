#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
NVIM_BIN=${NVIM_BIN:-"$HOME/.local/opt/nvim-0.12.4/bin/nvim"}
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/0.12.4"}
TREE_SITTER_BIN=${TREE_SITTER_BIN:-"$HOME/.local/opt/tree-sitter-cli-0.26.11/bin/tree-sitter"}

case "$XDG_ROOT" in
  /*) ;;
  *) XDG_ROOT="$PROJECT_ROOT/$XDG_ROOT" ;;
esac

if [ ! -x "$TREE_SITTER_BIN" ]; then
  printf '%s\n' "Error: TREE_SITTER_BIN no es un ejecutable: $TREE_SITTER_BIN" >&2
  exit 1
fi

TREE_SITTER_DIR=$(dirname -- "$TREE_SITTER_BIN")
PATH="$TREE_SITTER_DIR:$PATH"

case "$NVIM_BIN" in
  */*)
    if [ ! -x "$NVIM_BIN" ]; then
      printf '%s\n' "Error: NVIM_BIN no es un ejecutable: $NVIM_BIN" >&2
      exit 1
    fi
    ;;
  *)
    if ! command -v "$NVIM_BIN" >/dev/null 2>&1; then
      printf '%s\n' "Error: NVIM_BIN no esta disponible en PATH: $NVIM_BIN" >&2
      exit 1
    fi
    ;;
esac

mkdir -p \
  "$XDG_ROOT/data/nvim" \
  "$XDG_ROOT/state/nvim/undo" \
  "$XDG_ROOT/state/nvim/swap" \
  "$XDG_ROOT/cache/nvim" \
  "$XDG_ROOT/runtime"

chmod 700 "$XDG_ROOT/runtime"

export XDG_CONFIG_HOME="$PROJECT_ROOT"
export XDG_DATA_HOME="$XDG_ROOT/data"
export XDG_STATE_HOME="$XDG_ROOT/state"
export XDG_CACHE_HOME="$XDG_ROOT/cache"
export XDG_RUNTIME_DIR="$XDG_ROOT/runtime"
export ENTORNO_NVIM_ROOT="$PROJECT_ROOT"
export ENTORNO_NVIM_XDG_ROOT="$XDG_ROOT"
export ENTORNO_NVIM_TREE_SITTER_BIN="$TREE_SITTER_BIN"
export APPIMAGE_EXTRACT_AND_RUN="${APPIMAGE_EXTRACT_AND_RUN:-1}"
export PATH

exec "$NVIM_BIN" "$@"
