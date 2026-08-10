#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
NVIM_BIN=${NVIM_BIN:-"$HOME/.local/opt/nvim-$ENTORNO_NVIM_VERSION/bin/nvim"}
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION"}
TREE_SITTER_BIN=${TREE_SITTER_BIN:-"$HOME/.local/opt/tree-sitter-cli-$ENTORNO_TREE_SITTER_VERSION/bin/tree-sitter"}
LSP_WEB_BIN=${LSP_WEB_BIN:-"$PROJECT_ROOT/tools/lsp-web/node_modules/.bin"}
LSP_PYTHON_BIN=${LSP_PYTHON_BIN:-"$PROJECT_ROOT/tools/lsp-python/node_modules/.bin"}
LUALS_BIN=${LUALS_BIN:-"$HOME/.local/opt/lua-language-server-$ENTORNO_LUALS_VERSION/bin/lua-language-server"}

case "$XDG_ROOT" in
  /*) ;;
  *) XDG_ROOT="$PROJECT_ROOT/$XDG_ROOT" ;;
esac

case "$LSP_WEB_BIN" in
  /*) ;;
  *) LSP_WEB_BIN="$PROJECT_ROOT/$LSP_WEB_BIN" ;;
esac

case "$LSP_PYTHON_BIN" in
  /*) ;;
  *) LSP_PYTHON_BIN="$PROJECT_ROOT/$LSP_PYTHON_BIN" ;;
esac

if [ ! -x "$TREE_SITTER_BIN" ]; then
  printf '%s\n' "Error: TREE_SITTER_BIN no es un ejecutable: $TREE_SITTER_BIN" >&2
  exit 1
fi

for executable in \
  tailwindcss-language-server \
  typescript-language-server \
  vscode-html-language-server \
  vscode-css-language-server \
  vscode-json-language-server
do
  if [ ! -x "$LSP_WEB_BIN/$executable" ]; then
    printf '%s\n' "Error: falta $LSP_WEB_BIN/$executable; ejecuta scripts/instalar-lsp-web.sh." >&2
    exit 1
  fi
done

if [ ! -x "$LSP_PYTHON_BIN/pyright-langserver" ]; then
  printf '%s\n' "Error: falta $LSP_PYTHON_BIN/pyright-langserver; ejecuta scripts/instalar-lsp-python.sh." >&2
  exit 1
fi

if [ ! -x "$LUALS_BIN" ]; then
  printf '%s\n' "Error: LUALS_BIN no es un ejecutable: $LUALS_BIN; ejecuta scripts/instalar-luals.sh." >&2
  exit 1
fi

TREE_SITTER_DIR=$(dirname "$TREE_SITTER_BIN")
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
export ENTORNO_NVIM_LSP_WEB_BIN="$LSP_WEB_BIN"
export ENTORNO_NVIM_LSP_PYTHON_BIN="$LSP_PYTHON_BIN"
export ENTORNO_NVIM_LUALS_BIN="$LUALS_BIN"
export APPIMAGE_EXTRACT_AND_RUN="${APPIMAGE_EXTRACT_AND_RUN:-1}"
export PATH

exec "$NVIM_BIN" "$@"
