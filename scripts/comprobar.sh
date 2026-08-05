#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
HEALTH_REPORT="$PROJECT_ROOT/.xdg/checkhealth.txt"
TEST_FILE="$PROJECT_ROOT/tests/comprobar_nucleo.lua"

export ENTORNO_NVIM_HEALTH_REPORT="$HEALTH_REPORT"
export ENTORNO_NVIM_TEST_FILE="$TEST_FILE"

"$SCRIPT_DIR/arrancar.sh" --headless \
  "+lua local ok, err = pcall(dofile, vim.env.ENTORNO_NVIM_TEST_FILE); if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end" \
  "+qa"

git -C "$PROJECT_ROOT" check-ignore -q .xdg/state/nvim/undo/prueba
git -C "$PROJECT_ROOT" check-ignore -q .xdg/state/nvim/swap/prueba

"$SCRIPT_DIR/arrancar.sh" --headless \
  "+checkhealth" \
  "+lua vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), vim.env.ENTORNO_NVIM_HEALTH_REPORT)" \
  "+qa"

if grep -q "ERROR" "$HEALTH_REPORT"; then
  printf '%s\n' "Error: checkhealth contiene errores. Informe: $HEALTH_REPORT" >&2
  exit 1
fi

printf '\n%s\n' "Comprobacion correcta. Informe: $HEALTH_REPORT"
