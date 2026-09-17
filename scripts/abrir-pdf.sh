#!/bin/sh
set -eu

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

[ "$#" -eq 1 ] || fail "uso: scripts/abrir-pdf.sh archivo.pdf"

PDF=$1
[ -f "$PDF" ] && [ -s "$PDF" ] || fail "el PDF no existe o está vacío: $PDF"

if [ -n "${ENTORNO_PDF_VIEWER:-}" ]; then
  case "$ENTORNO_PDF_VIEWER" in
    */*)
      [ -f "$ENTORNO_PDF_VIEWER" ] && [ -x "$ENTORNO_PDF_VIEWER" ] ||
        fail "ENTORNO_PDF_VIEWER no es un archivo ejecutable: $ENTORNO_PDF_VIEWER"
      VIEWER=$ENTORNO_PDF_VIEWER
      ;;
    *) VIEWER=$(command -v "$ENTORNO_PDF_VIEWER" 2>/dev/null || true) ;;
  esac
  [ -n "$VIEWER" ] || fail "ENTORNO_PDF_VIEWER no es un ejecutable disponible: $ENTORNO_PDF_VIEWER"
  exec "$VIEWER" "$PDF"
fi

case $(uname -s) in
  Darwin)
    command -v open >/dev/null 2>&1 || fail "no se encontró open para visualizar el PDF"
    exec open "$PDF"
    ;;
  Linux)
    if [ -n "${WSL_DISTRO_NAME:-}" ] || { [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; }; then
      if command -v wslview >/dev/null 2>&1; then
        exec wslview "$PDF"
      elif command -v explorer.exe >/dev/null 2>&1; then
        exec explorer.exe "$PDF"
      fi
    fi
    command -v xdg-open >/dev/null 2>&1 ||
      fail "no se encontró xdg-open; configura ENTORNO_PDF_VIEWER"
    exec xdg-open "$PDF"
    ;;
  *)
    fail "sistema sin visor predeterminado; configura ENTORNO_PDF_VIEWER"
    ;;
esac
