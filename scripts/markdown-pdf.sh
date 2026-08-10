#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
STYLE=${MDPDF_STYLE:-"$PROJECT_ROOT/markdown/styles/examen.css"}
TEMPLATE=${MDPDF_TEMPLATE:-"$PROJECT_ROOT/markdown/templates/documento.html"}
METADATA_FILTER="$PROJECT_ROOT/markdown/filters/metadata-css.lua"

usage() {
  printf '%s\n' "Uso: $0 archivo.md [salida.pdf]" >&2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 2
fi

for dependency in pandoc; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    printf 'Error: falta la dependencia requerida: %s.\n' "$dependency" >&2
    exit 127
  fi
done

INPUT=$1
if [ ! -f "$INPUT" ]; then
  printf 'Error: no existe el Markdown: %s\n' "$INPUT" >&2
  exit 1
fi

if [ ! -f "$STYLE" ]; then
  printf 'Error: no existe el estilo: %s\n' "$STYLE" >&2
  exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
  printf 'Error: no existe la plantilla: %s\n' "$TEMPLATE" >&2
  exit 1
fi

if [ ! -f "$METADATA_FILTER" ]; then
  printf 'Error: no existe el filtro de metadatos: %s\n' "$METADATA_FILTER" >&2
  exit 1
fi

case "$INPUT" in
  /*) ;;
  *) INPUT="$(pwd)/$INPUT" ;;
esac
INPUT_DIR=$(CDPATH= cd "$(dirname "$INPUT")" && pwd)
INPUT="$INPUT_DIR/$(basename "$INPUT")"

if [ "$#" -eq 2 ]; then
  OUTPUT=$2
else
  OUTPUT=${INPUT%.*}.pdf
fi

case "$OUTPUT" in
  /*) ;;
  *) OUTPUT="$(pwd)/$OUTPUT" ;;
esac
OUTPUT_DIR=$(dirname "$OUTPUT")
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR=$(CDPATH= cd "$OUTPUT_DIR" && pwd)
OUTPUT="$OUTPUT_DIR/$(basename "$OUTPUT")"

if [ -n "${CHROMIUM_BIN:-}" ]; then
  if [ ! -f "$CHROMIUM_BIN" ] || [ ! -x "$CHROMIUM_BIN" ]; then
    printf 'Error: CHROMIUM_BIN no es un navegador ejecutable: %s\n' "$CHROMIUM_BIN" >&2
    exit 127
  fi
  BROWSER=$CHROMIUM_BIN
elif command -v chromium >/dev/null 2>&1; then
  BROWSER=$(command -v chromium)
elif command -v google-chrome >/dev/null 2>&1; then
  BROWSER=$(command -v google-chrome)
elif [ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
  BROWSER="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
elif [ -x "/Applications/Chromium.app/Contents/MacOS/Chromium" ]; then
  BROWSER="/Applications/Chromium.app/Contents/MacOS/Chromium"
else
  printf '%s\n' "Error: falta Chromium o Google Chrome para imprimir el HTML." >&2
  exit 127
fi

TMP_BASE=${TMPDIR:-/tmp}
TMP_DIR=$(mktemp -d "$TMP_BASE/entorno-nvim-mdpdf.XXXXXX")
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM
HTML="$TMP_DIR/documento.html"
BROWSER_LOG="$TMP_DIR/chromium.log"

pandoc "$INPUT" \
  --from=markdown+fenced_divs \
  --to=html5 \
  --standalone \
  --embed-resources \
  --resource-path="$INPUT_DIR:$PROJECT_ROOT" \
  --lua-filter="$METADATA_FILTER" \
  --template="$TEMPLATE" \
  --css="$STYLE" \
  --highlight-style=tango \
  --output="$HTML"

if ! "$BROWSER" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --allow-file-access-from-files \
  --user-data-dir="$TMP_DIR/browser-profile" \
  --print-to-pdf="$OUTPUT" \
  "file://$HTML" >"$BROWSER_LOG" 2>&1; then
  printf '%s\n' "Error: Chromium no pudo generar el PDF:" >&2
  sed -n '1,80p' "$BROWSER_LOG" >&2
  exit 1
fi

if [ ! -s "$OUTPUT" ]; then
  printf 'Error: el PDF no se creó o está vacío: %s\n' "$OUTPUT" >&2
  exit 1
fi

printf 'PDF generado: %s\n' "$OUTPUT"
