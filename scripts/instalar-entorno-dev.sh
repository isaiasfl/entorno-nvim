#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
SOURCE="$PROJECT_ROOT/bin/entorno-dev"
TARGET_DIR="$HOME/.local/bin"
TARGET="$TARGET_DIR/entorno-dev"

canonical_path() {
  path=$1
  while [ -L "$path" ]; do
    directory=$(CDPATH= cd "$(dirname "$path")" && pwd -P) || return 1
    link=$(readlink "$path") || return 1
    case "$link" in
      /*) path=$link ;;
      *) path=$directory/$link ;;
    esac
  done

  directory=$(CDPATH= cd "$(dirname "$path")" && pwd -P) || return 1
  printf '%s/%s\n' "$directory" "$(basename "$path")"
}

[ -x "$SOURCE" ] || {
  printf 'Error: el lanzador no existe o no es ejecutable: %s\n' "$SOURCE" >&2
  exit 1
}

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  if [ ! -L "$TARGET" ]; then
    printf 'Error: %s ya existe y no pertenece a este proyecto; no se ha sobrescrito.\n' "$TARGET" >&2
    exit 1
  fi

  source_path=$(canonical_path "$SOURCE")
  target_path=$(canonical_path "$TARGET") || target_path=
  if [ "$target_path" != "$source_path" ]; then
    printf 'Error: %s apunta a otro entorno; no se ha sobrescrito.\n' "$TARGET" >&2
    exit 1
  fi
fi

mkdir -p "$TARGET_DIR"
ln -sfn "$SOURCE" "$TARGET"
printf 'Lanzador instalado: %s -> %s\n' "$TARGET" "$SOURCE"
