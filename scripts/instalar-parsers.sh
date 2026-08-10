#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/versiones.sh"
export ENTORNO_PARSERS
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION"}

missing=
for parser in $ENTORNO_PARSERS; do
  [ -f "$XDG_ROOT/data/nvim/site/parser/$parser.so" ] || missing="$missing $parser"
done
if [ -z "$missing" ]; then
  printf '%s\n' "Parsers Tree-sitter ya instalados: $ENTORNO_PARSERS"
  exit 0
fi

"$SCRIPT_DIR/arrancar.sh" --headless \
  "+lua require('nvim-treesitter').install(vim.split(vim.env.ENTORNO_PARSERS, ' ', { trimempty = true })):wait(300000)" \
  "+qa"
