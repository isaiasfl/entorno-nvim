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
    directory=$(CDPATH= cd "$(dirname "$path")" 2>/dev/null && pwd -P) || return 1
    link=$(readlink "$path") || return 1
    case "$link" in
      /*) path=$link ;;
      *) path=$directory/$link ;;
    esac
  done

  directory=$(CDPATH= cd "$(dirname "$path")" 2>/dev/null && pwd -P) || return 1
  printf '%s/%s\n' "$directory" "$(basename "$path")"
}

# Ruta a la que apunta el enlace, aunque ya no exista (carpeta movida o borrada).
link_destination() {
  link=$(readlink "$1") || return 1
  case "$link" in
    /*) printf '%s\n' "$link" ;;
    *) printf '%s/%s\n' "$(dirname "$1")" "$link" ;;
  esac
}

confirm_replace() {
  [ -t 0 ] || return 1
  printf '¿Apuntar entorno-dev a esta copia? [s/N]: '
  IFS= read -r answer || answer=
  case "$answer" in
    s | S | si | Si | SI | sí | Sí) return 0 ;;
    *) return 1 ;;
  esac
}

manual_fix() {
  printf '%s\n' 'Puede seguir usando el entorno desde esta copia con:' "  $SOURCE" >&2
}

[ -x "$SOURCE" ] || {
  printf 'Error: el lanzador no existe o no es ejecutable: %s\n' "$SOURCE" >&2
  exit 1
}

if [ -e "$TARGET" ] || [ -L "$TARGET" ]; then
  if [ ! -L "$TARGET" ]; then
    printf 'Error: %s ya existe y no pertenece a este proyecto; no se ha sobrescrito.\n' "$TARGET" >&2
    manual_fix
    exit 1
  fi

  source_path=$(canonical_path "$SOURCE")
  target_path=$(canonical_path "$TARGET" 2>/dev/null) || target_path=
  if [ "$target_path" != "$source_path" ]; then
    previous=$(link_destination "$TARGET") || previous=
    case "$previous" in
      */bin/entorno-dev) ;;
      *)
        printf 'Error: %s apunta a %s, que no pertenece a entorno-nvim; no se ha sobrescrito.\n' \
          "$TARGET" "${previous:-un destino desconocido}" >&2
        manual_fix
        exit 1
        ;;
    esac
    if [ ! -e "$previous" ]; then
      # La copia anterior se movio o se borro: el enlace esta roto.
      printf 'Aviso: entorno-dev apuntaba a una copia que ya no existe:\n  %s\n' "$previous"
      printf '%s\n' 'Se actualiza para usar esta copia.'
    else
      printf 'Aviso: entorno-dev usa otra copia de entorno-nvim:\n  %s\n' "$previous"
      printf 'Esta copia es:\n  %s\n' "$SOURCE"
      confirm_replace || {
        printf '%s\n' 'Se conserva el enlace existente.' >&2
        manual_fix
        printf '%s\n' 'Para que el comando entorno-dev use esta copia, ejecute:' \
          "  ln -sfn '$SOURCE' '$TARGET'" >&2
        exit 1
      }
    fi
  fi
fi

mkdir -p "$TARGET_DIR"
ln -sfn "$SOURCE" "$TARGET"
printf 'Lanzador instalado: %s -> %s\n' "$TARGET" "$SOURCE"
