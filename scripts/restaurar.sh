#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/versiones.sh"
REPOSITORY=${ENTORNO_NVIM_REPOSITORY:-"$(dirname "$SCRIPT_DIR")"}
USER_HOME=${ENTORNO_NVIM_HOME:-"$HOME"}
CONFIG_PATH="$USER_HOME/.config/nvim"
CONFIG_TARGET="$REPOSITORY/nvim"
USER_BIN="$USER_HOME/.local/bin/nvim"
NVIM_TARGET=${ENTORNO_NVIM_TARGET:-"$USER_HOME/.local/opt/nvim-$ENTORNO_NVIM_VERSION/bin/nvim"}
STATE_DIR=${ENTORNO_NVIM_STATE_DIR:-"$USER_HOME/.local/state/entorno-nvim"}

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

same_target() {
  [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ]
}

case "$USER_HOME" in
  / | '') fail "directorio personal no valido" ;;
  /*) ;;
  *) fail "el directorio personal debe ser absoluto" ;;
esac

[ "$(id -u)" -ne 0 ] || fail "no ejecutes este script como root"
[ "$#" -le 1 ] || fail "uso: scripts/restaurar.sh [directorio-backup]"

if [ "$#" -eq 1 ]; then
  BACKUP_DIR=$1
elif [ -f "$STATE_DIR/ultimo-backup" ]; then
  BACKUP_DIR=$(sed -n '1p' "$STATE_DIR/ultimo-backup")
else
  fail "indica el backup que debe restaurarse"
fi

[ -d "$BACKUP_DIR" ] || fail "backup inexistente: $BACKUP_DIR"
[ -f "$BACKUP_DIR/manifest.txt" ] || fail "falta el manifiesto del backup"
same_target "$CONFIG_PATH" "$CONFIG_TARGET" || fail "$CONFIG_PATH no apunta a la configuracion de este repositorio"
same_target "$USER_BIN" "$NVIM_TARGET" || fail "$USER_BIN no apunta a Neovim $ENTORNO_NVIM_VERSION"

config_original=$(sed -n 's/^config_original=//p' "$BACKUP_DIR/manifest.txt")
bin_original=$(sed -n 's/^bin_original=//p' "$BACKUP_DIR/manifest.txt")
[ "$config_original" = "present" ] || [ "$config_original" = "missing" ] || fail "estado original de configuracion invalido"
[ "$bin_original" = "present" ] || [ "$bin_original" = "missing" ] || fail "estado original del comando invalido"

config_tmp="$USER_HOME/.config/.nvim-restauracion.$$"
bin_tmp="$USER_HOME/.local/bin/.nvim-restauracion.$$"
trap 'rm -rf "$config_tmp" "$bin_tmp"' EXIT HUP INT TERM

if [ "$config_original" = "present" ]; then
  [ -e "$BACKUP_DIR/nvim" ] || [ -L "$BACKUP_DIR/nvim" ] || fail "el backup no contiene la configuracion anterior"
  cp -R -P -p "$BACKUP_DIR/nvim" "$config_tmp"
fi
if [ "$bin_original" = "present" ]; then
  [ -e "$BACKUP_DIR/nvim-user-command" ] || [ -L "$BACKUP_DIR/nvim-user-command" ] || fail "el backup no contiene el comando anterior"
  cp -R -P -p "$BACKUP_DIR/nvim-user-command" "$bin_tmp"
fi

rm -f "$CONFIG_PATH" "$USER_BIN"
if [ "$config_original" = "present" ]; then
  mv "$config_tmp" "$CONFIG_PATH"
fi
if [ "$bin_original" = "present" ]; then
  mv "$bin_tmp" "$USER_BIN"
fi

rm -f "$STATE_DIR/ultimo-backup"
trap - EXIT HUP INT TERM

printf '%s\n' "Configuracion anterior restaurada desde $BACKUP_DIR"
printf '%s\n' "El backup se conserva y puede reutilizarse."
