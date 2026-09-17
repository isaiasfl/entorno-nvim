#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/comun.sh"
. "$SCRIPT_DIR/lib/rutas.sh"
. "$SCRIPT_DIR/lib/plataforma.sh"

VERSION=$ENTORNO_NODE_VERSION
if [ -z "${ENTORNO_NODE_PLATFORM:-}" ]; then
  printf 'Error: no hay Node %s fijado para %s %s.\n' "$VERSION" "$ENTORNO_OS" "$ENTORNO_ARCH" >&2
  printf '%s\n' "Plataformas con artefacto auditado: linux-x64, linux-arm64, darwin-arm64, darwin-x64." >&2
  printf '%s\n' "En otra plataforma instala Node >=$ENTORNO_NODE_MAJOR <$((ENTORNO_NODE_MAJOR + 1)) con Corepack y dejalo en PATH." >&2
  exit 1
fi

INSTALL_DIR=$(entorno_node_dir)
ARCHIVE=$(entorno_node_archive)
SHA256=$(entorno_node_checksum)
URL="https://nodejs.org/dist/v$VERSION/$ARCHIVE"
MARKER="$INSTALL_DIR/.source.sha256"

if [ -e "$INSTALL_DIR" ]; then
  if [ -x "$INSTALL_DIR/bin/node" ] && [ "$("$INSTALL_DIR/bin/node" --version 2>/dev/null)" = "v$VERSION" ] \
    && [ -f "$MARKER" ] && [ "$(sed -n '1p' "$MARKER")" = "$SHA256" ]; then
    printf 'Node %s ya esta instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
    exit 0
  fi
  printf 'Error: %s existe pero no es un Node %s verificado.\n' "$INSTALL_DIR" "$VERSION" >&2
  printf '%s\n' "Elimina ese directorio y vuelve a ejecutar este instalador." >&2
  exit 1
fi

mkdir -p "$ENTORNO_TOOLS_ROOT"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-node.XXXXXX")
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT HUP INT TERM

entorno_descargar "$URL" "$WORK_DIR/$ARCHIVE"
entorno_verificar_sha256 "$WORK_DIR/$ARCHIVE" "$SHA256"

top=$ARCHIVE
top=${top%.tar.xz}
top=${top%.tar.gz}
case "$ARCHIVE" in
  *.tar.xz) tar -tJf "$WORK_DIR/$ARCHIVE" > "$WORK_DIR/listado.txt" ;;
  *.tar.gz) tar -tzf "$WORK_DIR/$ARCHIVE" > "$WORK_DIR/listado.txt" ;;
  *)
    printf 'Error: formato de archivo no contemplado: %s\n' "$ARCHIVE" >&2
    exit 1
    ;;
esac
awk -v top="$top" 'BEGIN { ok = 1 }
  /^\// || /(^|\/)\.\.($|\/)/ || $0 !~ ("^" top "(/|$)") {
    print "Ruta no valida: " $0 > "/dev/stderr"; ok = 0
  }
  END { exit(ok ? 0 : 1) }' "$WORK_DIR/listado.txt"

case "$ARCHIVE" in
  *.tar.xz) tar -xJf "$WORK_DIR/$ARCHIVE" -C "$WORK_DIR" ;;
  *.tar.gz) tar -xzf "$WORK_DIR/$ARCHIVE" -C "$WORK_DIR" ;;
esac

[ -x "$WORK_DIR/$top/bin/node" ] || {
  printf 'Error: el archivo no contiene bin/node.\n' >&2
  exit 1
}
[ -x "$WORK_DIR/$top/bin/corepack" ] || {
  printf 'Error: el Node %s no incluye Corepack; no se puede fijar pnpm.\n' "$VERSION" >&2
  exit 1
}
version_extraida=$("$WORK_DIR/$top/bin/node" --version)
[ "$version_extraida" = "v$VERSION" ] || {
  printf 'Error: el binario extraido es %s y se esperaba v%s.\n' "$version_extraida" "$VERSION" >&2
  exit 1
}

printf '%s\n' "$SHA256" > "$WORK_DIR/$top/.source.sha256"
mv "$WORK_DIR/$top" "$INSTALL_DIR"
printf 'Node %s instalado y verificado en %s\n' "$VERSION" "$INSTALL_DIR"
