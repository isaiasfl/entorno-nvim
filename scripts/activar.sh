#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
REPOSITORY=${ENTORNO_NVIM_REPOSITORY:-"$(dirname "$SCRIPT_DIR")"}
USER_HOME=${ENTORNO_NVIM_HOME:-"$HOME"}
CONFIG_PATH="$USER_HOME/.config/nvim"
CONFIG_TARGET="$REPOSITORY/nvim"
USER_BIN="$USER_HOME/.local/bin/nvim"
NVIM_TARGET=${ENTORNO_NVIM_TARGET:-"$USER_HOME/.local/opt/nvim-0.12.4/bin/nvim"}
BACKUP_ROOT=${ENTORNO_NVIM_BACKUP_ROOT:-"$USER_HOME/copias-seguridad"}
STATE_DIR=${ENTORNO_NVIM_STATE_DIR:-"$USER_HOME/.local/state/entorno-nvim"}
TIMESTAMP=${ENTORNO_NVIM_ACTIVATION_TIMESTAMP:-"$(date +%Y%m%d-%H%M%S)"}
BACKUP_DIR="$BACKUP_ROOT/nvim-activa-$TIMESTAMP"

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

local_bin_precedes_system() {
  old_ifs=$IFS
  IFS=:
  set -f
  for entry in $PATH; do
    if [ "$entry" = "$USER_HOME/.local/bin" ]; then
      set +f
      IFS=$old_ifs
      return 0
    fi
    if [ "$entry" = "/usr/local/bin" ]; then
      set +f
      IFS=$old_ifs
      return 1
    fi
  done
  set +f
  IFS=$old_ifs
  return 1
}

case "$TIMESTAMP" in
  '' | *[!0-9-]*) fail "timestamp de activacion no valido" ;;
esac

[ "$(id -u)" -ne 0 ] || fail "no ejecutes este script como root"
[ -f "$CONFIG_TARGET/init.lua" ] || fail "destino de configuracion invalido: $CONFIG_TARGET"
[ -x "$NVIM_TARGET" ] || fail "binario Neovim no ejecutable: $NVIM_TARGET"
local_bin_precedes_system || fail "$USER_HOME/.local/bin debe aparecer antes de /usr/local/bin en PATH"

if same_target "$CONFIG_PATH" "$CONFIG_TARGET" && same_target "$USER_BIN" "$NVIM_TARGET"; then
  printf '%s\n' "La configuracion ya esta activa."
  exit 0
fi

[ ! -e "$BACKUP_DIR" ] || fail "ya existe el backup: $BACKUP_DIR"
mkdir -p "$BACKUP_ROOT" "$USER_HOME/.config" "$USER_HOME/.local/bin" "$STATE_DIR"
mkdir "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR" "$STATE_DIR"

config_moved=0
config_linked=0
bin_moved=0
bin_linked=0
success=0

rollback_partial() {
  [ "$success" -eq 0 ] || return 0

  if [ "$bin_linked" -eq 1 ] && same_target "$USER_BIN" "$NVIM_TARGET"; then
    rm -f "$USER_BIN"
  fi
  if [ "$bin_moved" -eq 1 ] && { [ -e "$BACKUP_DIR/nvim-user-command" ] || [ -L "$BACKUP_DIR/nvim-user-command" ]; }; then
    mv "$BACKUP_DIR/nvim-user-command" "$USER_BIN"
  fi
  if [ "$config_linked" -eq 1 ] && same_target "$CONFIG_PATH" "$CONFIG_TARGET"; then
    rm -f "$CONFIG_PATH"
  fi
  if [ "$config_moved" -eq 1 ] && { [ -e "$BACKUP_DIR/nvim" ] || [ -L "$BACKUP_DIR/nvim" ]; }; then
    mv "$BACKUP_DIR/nvim" "$CONFIG_PATH"
  fi
  rm -f "$BACKUP_DIR/manifest.txt"
  rmdir "$BACKUP_DIR" 2>/dev/null || true
}
trap rollback_partial EXIT HUP INT TERM

config_original=missing
if [ -e "$CONFIG_PATH" ] || [ -L "$CONFIG_PATH" ]; then
  mv "$CONFIG_PATH" "$BACKUP_DIR/nvim"
  config_moved=1
  config_original=present
fi
ln -s "$CONFIG_TARGET" "$CONFIG_PATH"
config_linked=1

bin_original=missing
if [ -e "$USER_BIN" ] || [ -L "$USER_BIN" ]; then
  mv "$USER_BIN" "$BACKUP_DIR/nvim-user-command"
  bin_moved=1
  bin_original=present
fi
ln -s "$NVIM_TARGET" "$USER_BIN"
bin_linked=1

{
  printf 'activated_at=%s\n' "$TIMESTAMP"
  printf 'repository=%s\n' "$REPOSITORY"
  printf 'config_path=%s\n' "$CONFIG_PATH"
  printf 'config_target=%s\n' "$CONFIG_TARGET"
  printf 'config_original=%s\n' "$config_original"
  printf 'user_bin=%s\n' "$USER_BIN"
  printf 'nvim_target=%s\n' "$NVIM_TARGET"
  printf 'bin_original=%s\n' "$bin_original"
} > "$BACKUP_DIR/manifest.txt"
chmod 600 "$BACKUP_DIR/manifest.txt"

state_tmp="$STATE_DIR/ultimo-backup.$$"
printf '%s\n' "$BACKUP_DIR" > "$state_tmp"
chmod 600 "$state_tmp"
mv "$state_tmp" "$STATE_DIR/ultimo-backup"

success=1
trap - EXIT HUP INT TERM

printf '%s\n' "Configuracion activada: $CONFIG_PATH -> $CONFIG_TARGET"
printf '%s\n' "Comando activado: $USER_BIN -> $NVIM_TARGET"
printf '%s\n' "Backup anterior: $BACKUP_DIR"
