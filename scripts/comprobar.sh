#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
HEALTH_REPORT="$PROJECT_ROOT/.xdg/checkhealth.txt"

export ENTORNO_NVIM_HEALTH_REPORT="$HEALTH_REPORT"

"$SCRIPT_DIR/arrancar.sh" --headless \
  "+lua assert(vim.fn.stdpath('config') == vim.env.ENTORNO_NVIM_ROOT .. '/nvim', 'configuracion XDG incorrecta')" \
  "+lua assert(package.loaded['config.options'], 'config.options no se cargo')" \
  "+lua assert(package.loaded['config.keymaps'], 'config.keymaps no se cargo')" \
  "+lua assert(package.loaded['config.autocmds'], 'config.autocmds no se cargo')" \
  "+lua local m = vim.fn.maparg('jk', 'i', false, true); assert(m.rhs == '<Esc>', 'jk no equivale a Esc'); assert(m.silent == 1, 'jk no es silencioso'); assert(m.desc == 'Salir del modo insertar', 'descripcion de jk incorrecta')" \
  "+lua assert(vim.tbl_isempty(vim.fn.maparg('kj', 'i', false, true)), 'kj no debe estar mapeado')" \
  "+lua assert(vim.tbl_isempty(vim.fn.maparg('<Esc>', 'i', false, true)), 'Esc no debe estar remapeado en insertar')" \
  "+qa"

"$SCRIPT_DIR/arrancar.sh" --headless \
  "+checkhealth" \
  "+lua vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), vim.env.ENTORNO_NVIM_HEALTH_REPORT)" \
  "+qa"

if grep -q "ERROR" "$HEALTH_REPORT"; then
  printf '%s\n' "Error: checkhealth contiene errores. Informe: $HEALTH_REPORT" >&2
  exit 1
fi

printf '\n%s\n' "Comprobacion correcta. Informe: $HEALTH_REPORT"
