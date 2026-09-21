#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/rutas.sh"
. "$SCRIPT_DIR/lib/plataforma.sh"
ENTORNO_PERFIL=${ENTORNO_PERFIL:-profesor}
case "$ENTORNO_PERFIL" in
  inicial | dwec | si | profesor) ;;
  *) printf 'Error: perfil desconocido: %s\n' "$ENTORNO_PERFIL" >&2; exit 2 ;;
esac
case "${ENTORNO_IA:-0}" in
  0 | 1) ;;
  *) printf '%s\n' 'Error: ENTORNO_IA debe ser 0 o 1.' >&2; exit 2 ;;
esac
DEFAULT_NVIM_BIN="$ENTORNO_TOOLS_ROOT/nvim-$ENTORNO_NVIM_VERSION/bin/nvim"
if [ ! -x "$DEFAULT_NVIM_BIN" ]; then
  DEFAULT_NVIM_BIN=$(command -v nvim 2>/dev/null || printf '%s' "$DEFAULT_NVIM_BIN")
fi
NVIM_BIN=${NVIM_BIN:-"$DEFAULT_NVIM_BIN"}
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION"}
TREE_SITTER_BIN=${TREE_SITTER_BIN:-"$ENTORNO_TOOLS_ROOT/tree-sitter-cli-$ENTORNO_TREE_SITTER_VERSION/bin/tree-sitter"}
LSP_WEB_BIN=${LSP_WEB_BIN:-"$PROJECT_ROOT/tools/lsp-web/node_modules/.bin"}
LSP_PYTHON_BIN=${LSP_PYTHON_BIN:-"$PROJECT_ROOT/tools/lsp-python/node_modules/.bin"}
LSP_BASH_BIN=${LSP_BASH_BIN:-"$PROJECT_ROOT/tools/lsp-bash/node_modules/.bin"}
DEFAULT_LUALS_BIN="$ENTORNO_TOOLS_ROOT/lua-language-server-$ENTORNO_LUALS_VERSION/bin/lua-language-server"
if [ ! -x "$DEFAULT_LUALS_BIN" ] && [ "$(uname -s)" = Darwin ]; then
  DEFAULT_LUALS_BIN=$(command -v lua-language-server 2>/dev/null || printf '%s' "$DEFAULT_LUALS_BIN")
fi
LUALS_BIN=${LUALS_BIN:-"$DEFAULT_LUALS_BIN"}

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

case "$LSP_BASH_BIN" in
  /*) ;;
  *) LSP_BASH_BIN="$PROJECT_ROOT/$LSP_BASH_BIN" ;;
esac

if [ -x "$TREE_SITTER_BIN" ]; then
  TREE_SITTER_DIR=$(dirname "$TREE_SITTER_BIN")
  PATH="$TREE_SITTER_DIR:$PATH"
fi

# Los servidores LSP web y Pyright son lanzadores que invocan `node` por PATH.
# Anteponer el Node vendorizado evita depender del Node del sistema del alumno.
entorno_preferir_node_vendor

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
  "$XDG_ROOT/state/$ENTORNO_PERFIL/nvim/undo" \
  "$XDG_ROOT/state/$ENTORNO_PERFIL/nvim/swap" \
  "$XDG_ROOT/cache/nvim" \
  "$XDG_ROOT/runtime"

chmod 700 "$XDG_ROOT/runtime"

# Guardar solo las rutas de configuracion del escritorio, nunca credenciales.
# Los visores y lazygit recuperan esta ruta; los datos del editor son privados.
if [ "${ENTORNO_DESKTOP_ENV_SAVED:-0}" != 1 ]; then
  export ENTORNO_DESKTOP_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  export ENTORNO_DESKTOP_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  export ENTORNO_DESKTOP_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  export ENTORNO_DESKTOP_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
  export ENTORNO_DESKTOP_ENV_SAVED=1
fi
export XDG_CONFIG_HOME="$PROJECT_ROOT"
export XDG_DATA_HOME="$XDG_ROOT/data"
export XDG_STATE_HOME="$XDG_ROOT/state/$ENTORNO_PERFIL"
export XDG_CACHE_HOME="$XDG_ROOT/cache"
# Wayland, portapapeles y portales necesitan el runtime original del escritorio.
# Los sockets propios se crean explicitamente dentro de XDG_ROOT/runtime.
export NVIM_APPNAME=nvim
export ENTORNO_PERFIL
export ENTORNO_NVIM_ROOT="$PROJECT_ROOT"
export ENTORNO_NVIM_XDG_ROOT="$XDG_ROOT"
export ENTORNO_NVIM_TREE_SITTER_BIN="$TREE_SITTER_BIN"
export ENTORNO_NVIM_LSP_WEB_BIN="$LSP_WEB_BIN"
export ENTORNO_NVIM_LSP_PYTHON_BIN="$LSP_PYTHON_BIN"
export ENTORNO_NVIM_LSP_BASH_BIN="$LSP_BASH_BIN"
export ENTORNO_NVIM_LUALS_BIN="$LUALS_BIN"
export APPIMAGE_EXTRACT_AND_RUN="${APPIMAGE_EXTRACT_AND_RUN:-1}"
export PATH

if [ "${ENTORNO_SIN_LISTEN:-0}" = 1 ]; then
  exec "$NVIM_BIN" "$@"
fi
exec "$NVIM_BIN" --listen "$XDG_ROOT/runtime/nvim-$$" "$@"
