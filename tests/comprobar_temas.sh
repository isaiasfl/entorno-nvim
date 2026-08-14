#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-temas.XXXXXX")
THEME_STATE="$TEST_ROOT/state/entorno-nvim/theme"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

ENTORNO_NVIM_THEME_STATE="$THEME_STATE" \
  "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
  "+lua local ok, err = pcall(dofile, '$PROJECT_ROOT/tests/comprobar_temas.lua'); if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end" \
  +qa

[ "$(sed -n '1p' "$THEME_STATE")" = "kanagawa" ]
printf '%s\n' "tokyo" >"$THEME_STATE"

ENTORNO_NVIM_THEME_STATE="$THEME_STATE" \
  "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
  "+lua assert(require('config.theme').current == 'tokyo', 'no cargo el tema persistido'); assert(vim.g.colors_name == 'tokyonight-night', 'no cargo Tokyo Night persistido')" \
  +qa

printf '%s\n' "Comprobacion de temas Neovim correcta."
