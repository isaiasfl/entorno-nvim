#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/comun.sh"
. "$SCRIPT_DIR/lib/rutas.sh"

VERSION=$ENTORNO_LUALS_VERSION
ARCHIVE="lua-language-server-$VERSION-linux-x64.tar.gz"
URL="https://github.com/LuaLS/lua-language-server/releases/download/$VERSION/$ARCHIVE"
SHA256=624ae8dd3bfbd5c2ee3ccf2f3547d33aeefa209971cce8c11d48f69fc1ec065a
BINARY_SHA256=$ENTORNO_LUALS_LINUX_X64_BINARY_SHA256
OPT_ROOT=${LUALS_OPT_ROOT:-"$ENTORNO_TOOLS_ROOT"}
INSTALL_DIR="$OPT_ROOT/lua-language-server-$VERSION"

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
  printf '%s\n' "Error: este instalador auditado solo admite Linux x86_64." >&2
  exit 1
fi

if [ -d "$INSTALL_DIR" ]; then
  if [ -x "$INSTALL_DIR/bin/lua-language-server" ] \
    && [ "$(entorno_sha256 "$INSTALL_DIR/bin/lua-language-server")" = "$BINARY_SHA256" ] \
    && [ -f "$INSTALL_DIR/.source.sha256" ] \
    && [ "$(cat "$INSTALL_DIR/.source.sha256")" = "$SHA256  $ARCHIVE" ]; then
    printf '%s\n' "LuaLS $VERSION ya esta instalado y verificado en $INSTALL_DIR"
    exit 0
  fi

  printf '%s\n' "Error: $INSTALL_DIR ya existe, pero no coincide con la instalacion esperada." >&2
  exit 1
fi

mkdir -p "$OPT_ROOT"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-luals.XXXXXX")
STAGING_DIR=$(mktemp -d "$OPT_ROOT/.lua-language-server-$VERSION.XXXXXX")

cleanup() {
  rm -rf "$WORK_DIR"
  if [ -n "${STAGING_DIR:-}" ] && [ -d "$STAGING_DIR" ]; then
    rm -rf "$STAGING_DIR"
  fi
}
trap cleanup EXIT HUP INT TERM

entorno_descargar "$URL" "$WORK_DIR/$ARCHIVE"
entorno_verificar_sha256 "$WORK_DIR/$ARCHIVE" "$SHA256"

if tar -tzf "$WORK_DIR/$ARCHIVE" | awk '
  /^\// || /(^|\/)\.\.($|\/)/ { bad = 1 }
  END { exit bad }
'; then
  :
else
  printf '%s\n' "Error: el tarball contiene una ruta insegura." >&2
  exit 1
fi

tar -xzf "$WORK_DIR/$ARCHIVE" -C "$STAGING_DIR"

if [ ! -x "$STAGING_DIR/bin/lua-language-server" ] || [ ! -f "$STAGING_DIR/LICENSE" ]; then
  printf '%s\n' "Error: el contenido extraido de LuaLS esta incompleto." >&2
  exit 1
fi

if [ "$(entorno_sha256 "$STAGING_DIR/bin/lua-language-server")" != "$BINARY_SHA256" ]; then
  printf '%s\n' "Error: el binario extraido de LuaLS no coincide con el hash esperado." >&2
  exit 1
fi

if [ "$(cd "$STAGING_DIR" && ./bin/lua-language-server --logpath="$WORK_DIR/log" --version)" != "$VERSION" ]; then
  printf '%s\n' "Error: el binario extraido no informa la version $VERSION." >&2
  exit 1
fi

printf '%s  %s\n' "$SHA256" "$ARCHIVE" > "$STAGING_DIR/.source.sha256"
mv "$STAGING_DIR" "$INSTALL_DIR"
STAGING_DIR=

printf '%s\n' "LuaLS $VERSION instalado en $INSTALL_DIR"
