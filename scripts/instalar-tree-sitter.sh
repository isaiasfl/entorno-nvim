#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/comun.sh"
. "$SCRIPT_DIR/lib/rutas.sh"

VERSION=$ENTORNO_TREE_SITTER_VERSION
OPT_ROOT=${TREE_SITTER_OPT_ROOT:-"$ENTORNO_TOOLS_ROOT"}
INSTALL_DIR="$OPT_ROOT/tree-sitter-cli-$VERSION"

case "$(uname -s):$(uname -m)" in
  Linux:x86_64)
    PLATFORM=linux-x64
    SHA256=ff1b7f9863f2faafd78dc0e66d902ee85b37f709b314b22c009f51caf233eebd
    BINARY_SHA256=$ENTORNO_TREE_SITTER_LINUX_X64_BINARY_SHA256
    ;;
  Darwin:x86_64)
    PLATFORM=macos-x64
    SHA256=e3c2cdec71bbc60344b25df3dad5da378a174f2292af953ff0d641e06aaee099
    BINARY_SHA256=
    ;;
  Darwin:arm64)
    PLATFORM=macos-arm64
    SHA256=050f41d60a054b608ea392ba14722bba9457bdc0ab11a5706c77f034dafc68ac
    BINARY_SHA256=
    ;;
  *)
    printf 'Error: no hay un artefacto auditado de tree-sitter %s para %s/%s.\n' \
      "$VERSION" "$(uname -s)" "$(uname -m)" >&2
    exit 1
    ;;
esac

ARCHIVE="tree-sitter-cli-$PLATFORM.zip"
URL="https://github.com/tree-sitter/tree-sitter/releases/download/v$VERSION/$ARCHIVE"

if [ -e "$INSTALL_DIR" ]; then
  [ -x "$INSTALL_DIR/bin/tree-sitter" ] || {
    printf 'Error: instalacion incompleta: %s\n' "$INSTALL_DIR" >&2
    exit 1
  }
  version_instalada=$("$INSTALL_DIR/bin/tree-sitter" --version | awk '{ print $2 }')
  [ "$version_instalada" = "$VERSION" ] || {
    printf 'Error: %s contiene tree-sitter %s, no %s.\n' "$INSTALL_DIR" "$version_instalada" "$VERSION" >&2
    exit 1
  }
  if [ -n "$BINARY_SHA256" ]; then
    entorno_verificar_sha256 "$INSTALL_DIR/bin/tree-sitter" "$BINARY_SHA256"
  elif [ ! -f "$INSTALL_DIR/.source.sha256" ] || [ "$(sed -n '1p' "$INSTALL_DIR/.source.sha256")" != "$SHA256  $ARCHIVE" ]; then
    printf 'Error: %s no conserva la procedencia verificada esperada.\n' "$INSTALL_DIR" >&2
    exit 1
  fi
  printf 'tree-sitter CLI %s ya esta instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
  exit 0
fi

command -v unzip >/dev/null 2>&1 || {
  printf '%s\n' "Error: se requiere unzip para instalar tree-sitter CLI." >&2
  exit 1
}
mkdir -p "$OPT_ROOT"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-tree-sitter.XXXXXX")
STAGING_DIR=$(mktemp -d "$OPT_ROOT/.tree-sitter-cli-$VERSION.XXXXXX")
cleanup() {
  rm -rf "$WORK_DIR"
  if [ -n "${STAGING_DIR:-}" ] && [ -d "$STAGING_DIR" ]; then rm -rf "$STAGING_DIR"; fi
}
trap cleanup EXIT HUP INT TERM

entorno_descargar "$URL" "$WORK_DIR/$ARCHIVE"
entorno_verificar_sha256 "$WORK_DIR/$ARCHIVE" "$SHA256"
listado=$(unzip -Z1 "$WORK_DIR/$ARCHIVE")
[ "$listado" = tree-sitter ] || {
  printf '%s\n' "Error: el archivo de tree-sitter no contiene un unico ejecutable esperado." >&2
  exit 1
}
unzip -q "$WORK_DIR/$ARCHIVE" -d "$STAGING_DIR/bin"
chmod 755 "$STAGING_DIR/bin/tree-sitter"
[ "$("$STAGING_DIR/bin/tree-sitter" --version | awk '{ print $2 }')" = "$VERSION" ] || {
  printf '%s\n' "Error: el ejecutable extraido no informa la version esperada." >&2
  exit 1
}
printf '%s  %s\n' "$SHA256" "$ARCHIVE" > "$STAGING_DIR/.source.sha256"
chmod 644 "$STAGING_DIR/.source.sha256"
mv "$STAGING_DIR" "$INSTALL_DIR"
STAGING_DIR=
printf 'tree-sitter CLI %s instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
