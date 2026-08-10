#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/comun.sh"

VERSION=$ENTORNO_NVIM_VERSION
OPT_ROOT=${ENTORNO_NVIM_OPT_ROOT:-"$HOME/.local/opt"}
INSTALL_DIR="$OPT_ROOT/nvim-$VERSION"
ARCHIVE=nvim-linux-x86_64.tar.gz
URL="https://github.com/neovim/neovim/releases/download/v$VERSION/$ARCHIVE"
SHA256=012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628
BINARY_SHA256=$ENTORNO_NVIM_BINARY_SHA256

if [ "$(uname -s)" != Linux ] || [ "$(uname -m)" != x86_64 ]; then
  printf '%s\n' "Error: la instalacion automatica auditada de Neovim $VERSION solo admite Linux x86_64." >&2
  printf '%s\n' "En esta plataforma instala esa version por un medio fiable y define NVIM_BIN." >&2
  exit 1
fi

if [ -e "$INSTALL_DIR" ]; then
  [ -x "$INSTALL_DIR/bin/nvim" ] || {
    printf 'Error: instalacion incompleta: %s\n' "$INSTALL_DIR" >&2
    exit 1
  }
  version_instalada=$("$INSTALL_DIR/bin/nvim" --version | sed -n '1s/^NVIM v//p')
  [ "$version_instalada" = "$VERSION" ] || {
    printf 'Error: %s contiene Neovim %s, no %s.\n' "$INSTALL_DIR" "$version_instalada" "$VERSION" >&2
    exit 1
  }
  entorno_verificar_sha256 "$INSTALL_DIR/bin/nvim" "$BINARY_SHA256"
  printf 'Neovim %s ya esta instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
  exit 0
fi

mkdir -p "$OPT_ROOT"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-neovim.XXXXXX")
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT HUP INT TERM

entorno_descargar "$URL" "$WORK_DIR/$ARCHIVE"
entorno_verificar_sha256 "$WORK_DIR/$ARCHIVE" "$SHA256"
tar -tzf "$WORK_DIR/$ARCHIVE" > "$WORK_DIR/listado.txt"
awk 'BEGIN { ok = 1 }
  /^\// || /(^|\/)\.\.($|\/)/ || $0 !~ /^nvim-linux-x86_64(\/|$)/ {
    print "Ruta no valida: " $0 > "/dev/stderr"; ok = 0
  }
  END { exit(ok ? 0 : 1) }' "$WORK_DIR/listado.txt"
tar -xzf "$WORK_DIR/$ARCHIVE" -C "$WORK_DIR"
entorno_verificar_sha256 "$WORK_DIR/nvim-linux-x86_64/bin/nvim" "$BINARY_SHA256"
printf '%s  %s\n' "$SHA256" "$ARCHIVE" > "$WORK_DIR/nvim-linux-x86_64/.source.sha256"
mv "$WORK_DIR/nvim-linux-x86_64" "$INSTALL_DIR"
printf 'Neovim %s instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
