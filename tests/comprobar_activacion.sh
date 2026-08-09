#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-activacion.XXXXXX")
TEST_HOME="$TEST_ROOT/home"
TEST_REPOSITORY="$TEST_ROOT/repositorio"
TEST_BACKUPS="$TEST_ROOT/backups"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

mkdir -p \
  "$TEST_HOME/.config/nvim" \
  "$TEST_HOME/.local/bin" \
  "$TEST_HOME/.local/opt/nvim-0.12.4/bin" \
  "$TEST_REPOSITORY/nvim"
printf '%s\n' 'configuracion-anterior' > "$TEST_HOME/.config/nvim/init.lua"
printf '%s\n' 'configuracion-nueva' > "$TEST_REPOSITORY/nvim/init.lua"
printf '%s\n' '#!/bin/sh' 'printf "NVIM v0.12.4\n"' > "$TEST_HOME/.local/opt/nvim-0.12.4/bin/nvim"
chmod 755 "$TEST_HOME/.local/opt/nvim-0.12.4/bin/nvim"

ENTORNO_NVIM_HOME="$TEST_HOME" \
ENTORNO_NVIM_REPOSITORY="$TEST_REPOSITORY" \
ENTORNO_NVIM_BACKUP_ROOT="$TEST_BACKUPS" \
ENTORNO_NVIM_ACTIVATION_TIMESTAMP=20260809-000000 \
PATH="$TEST_HOME/.local/bin:/usr/local/bin:/usr/bin:/bin" \
  "$PROJECT_ROOT/scripts/activar.sh" >/dev/null

BACKUP="$TEST_BACKUPS/nvim-activa-20260809-000000"
[ "$(readlink -f "$TEST_HOME/.config/nvim")" = "$(readlink -f "$TEST_REPOSITORY/nvim")" ]
[ "$(readlink -f "$TEST_HOME/.local/bin/nvim")" = "$(readlink -f "$TEST_HOME/.local/opt/nvim-0.12.4/bin/nvim")" ]
[ "$(sed -n '1p' "$BACKUP/nvim/init.lua")" = "configuracion-anterior" ]
[ "$(sed -n '1p' "$TEST_HOME/.local/state/entorno-nvim/ultimo-backup")" = "$BACKUP" ]

ENTORNO_NVIM_HOME="$TEST_HOME" \
ENTORNO_NVIM_REPOSITORY="$TEST_REPOSITORY" \
  "$PROJECT_ROOT/scripts/restaurar.sh" >/dev/null

[ ! -L "$TEST_HOME/.config/nvim" ]
[ "$(sed -n '1p' "$TEST_HOME/.config/nvim/init.lua")" = "configuracion-anterior" ]
[ ! -e "$TEST_HOME/.local/bin/nvim" ]
[ -f "$BACKUP/nvim/init.lua" ]

printf '%s\n' "Comprobacion de activacion y restauracion correcta."
