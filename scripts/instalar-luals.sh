#!/bin/sh
set -eu

VERSION=3.19.0
ARCHIVE="lua-language-server-$VERSION-linux-x64.tar.gz"
URL="https://github.com/LuaLS/lua-language-server/releases/download/$VERSION/$ARCHIVE"
SHA256=624ae8dd3bfbd5c2ee3ccf2f3547d33aeefa209971cce8c11d48f69fc1ec065a
BINARY_SHA256=39d9c9f8937d619c482f1fb2b7a4cce46a85b7a35cbe67cef7e2555aff3dc4f1
OPT_ROOT=${LUALS_OPT_ROOT:-"$HOME/.local/opt"}
INSTALL_DIR="$OPT_ROOT/lua-language-server-$VERSION"

if [ "$(uname -s)" != "Linux" ] || [ "$(uname -m)" != "x86_64" ]; then
  printf '%s\n' "Error: este instalador auditado solo admite Linux x86_64." >&2
  exit 1
fi

if [ -d "$INSTALL_DIR" ]; then
  if [ -x "$INSTALL_DIR/bin/lua-language-server" ] \
    && [ "$(sha256sum "$INSTALL_DIR/bin/lua-language-server" | awk '{ print $1 }')" = "$BINARY_SHA256" ] \
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

curl --fail --location --proto '=https' --tlsv1.2 --output "$WORK_DIR/$ARCHIVE" "$URL"
printf '%s  %s\n' "$SHA256" "$WORK_DIR/$ARCHIVE" | sha256sum --check

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

if [ "$(sha256sum "$STAGING_DIR/bin/lua-language-server" | awk '{ print $1 }')" != "$BINARY_SHA256" ]; then
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
