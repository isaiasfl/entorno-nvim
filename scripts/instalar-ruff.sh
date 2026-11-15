#!/bin/sh
set -eu

# Instala Ruff (linter y formateador de Python) como binario oficial verificado
# dentro de .tools/. No usa pip, pipx, sudo ni el gestor de paquetes, porque
# Debian 13 y Ubuntu 26.04 no lo empaquetan. Es opcional: sin ruff el entorno
# conserva errores y completado de Python, solo pierde el formato al guardar.

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/comun.sh"
. "$SCRIPT_DIR/lib/rutas.sh"

VERSION=$ENTORNO_RUFF_VERSION
OPT_ROOT=${RUFF_OPT_ROOT:-"$ENTORNO_TOOLS_ROOT"}
INSTALL_DIR="$OPT_ROOT/ruff-$VERSION"

case "$(uname -s):$(uname -m)" in
  Linux:x86_64)
    PLATFORM=x86_64-unknown-linux-gnu
    SHA256=$ENTORNO_RUFF_LINUX_X64_SHA256
    ;;
  Linux:aarch64 | Linux:arm64)
    PLATFORM=aarch64-unknown-linux-gnu
    SHA256=$ENTORNO_RUFF_LINUX_ARM64_SHA256
    ;;
  Darwin:*)
    printf '%s\n' "En macOS no hay un artefacto auditado de Ruff en este entorno." \
      "Instalelo con su gestor habitual (brew install ruff) o con pipx; es opcional." >&2
    exit 1
    ;;
  *)
    printf 'Error: no hay artefacto auditado de Ruff %s para %s/%s.\n' \
      "$VERSION" "$(uname -s)" "$(uname -m)" >&2
    exit 1
    ;;
esac

ARCHIVE="ruff-$PLATFORM.tar.gz"
URL="https://github.com/astral-sh/ruff/releases/download/$VERSION/$ARCHIVE"

if [ -e "$INSTALL_DIR" ]; then
  [ -x "$INSTALL_DIR/bin/ruff" ] || {
    printf 'Error: instalacion incompleta: %s\n' "$INSTALL_DIR" >&2
    exit 1
  }
  version_instalada=$("$INSTALL_DIR/bin/ruff" --version | awk '{ print $2 }')
  [ "$version_instalada" = "$VERSION" ] || {
    printf 'Error: %s contiene ruff %s, no %s.\n' "$INSTALL_DIR" "$version_instalada" "$VERSION" >&2
    exit 1
  }
  esperado="$SHA256  $ARCHIVE"
  if [ ! -f "$INSTALL_DIR/.source.sha256" ] || [ "$(sed -n '1p' "$INSTALL_DIR/.source.sha256")" != "$esperado" ]; then
    printf 'Error: %s no conserva la procedencia verificada esperada.\n' "$INSTALL_DIR" >&2
    exit 1
  fi
  printf 'ruff %s ya esta instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
  exit 0
fi

command -v tar >/dev/null 2>&1 || {
  printf '%s\n' "Error: se requiere tar para instalar Ruff." >&2
  exit 1
}
mkdir -p "$OPT_ROOT"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-ruff.XXXXXX")
STAGING_DIR=$(mktemp -d "$OPT_ROOT/.ruff-$VERSION.XXXXXX")
cleanup() {
  rm -rf "$WORK_DIR"
  if [ -n "${STAGING_DIR:-}" ] && [ -d "$STAGING_DIR" ]; then rm -rf "$STAGING_DIR"; fi
}
trap cleanup EXIT HUP INT TERM

entorno_descargar "$URL" "$WORK_DIR/$ARCHIVE"
entorno_verificar_sha256 "$WORK_DIR/$ARCHIVE" "$SHA256"

listado=$(tar tzf "$WORK_DIR/$ARCHIVE")
[ "$listado" = "ruff-$PLATFORM/
ruff-$PLATFORM/ruff" ] || {
  printf '%s\n' "Error: el archivo de Ruff no contiene el unico ejecutable esperado." >&2
  exit 1
}

mkdir -p "$STAGING_DIR/bin"
tar xzf "$WORK_DIR/$ARCHIVE" -C "$STAGING_DIR" --strip-components=1
chmod 755 "$STAGING_DIR/ruff"
[ "$("$STAGING_DIR/ruff" --version | awk '{ print $2 }')" = "$VERSION" ] || {
  printf '%s\n' "Error: el ejecutable extraido no informa la version esperada." >&2
  exit 1
}
mv "$STAGING_DIR/ruff" "$STAGING_DIR/bin/ruff"
printf '%s  %s\n' "$SHA256" "$ARCHIVE" > "$STAGING_DIR/.source.sha256"
chmod 644 "$STAGING_DIR/.source.sha256"
mv "$STAGING_DIR" "$INSTALL_DIR"
STAGING_DIR=
printf 'ruff %s instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
printf 'Neovim lo detecta con el arranque del entorno; no modifica el sistema.\n'
