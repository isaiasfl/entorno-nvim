#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
EXAMPLE="$PROJECT_ROOT/examples/examen/examen.md"
OUTPUT="$PROJECT_ROOT/examples/examen/examen.pdf"

"$PROJECT_ROOT/scripts/markdown-pdf.sh" "$EXAMPLE" "$OUTPUT"

if command -v pdfinfo >/dev/null 2>&1; then
  PAGES=$(pdfinfo "$OUTPUT" | awk '/^Pages:/ { print $2 }')
  if [ -z "$PAGES" ] || [ "$PAGES" -lt 2 ]; then
    printf 'Error: se esperaban al menos dos páginas y se obtuvieron %s.\n' "${PAGES:-ninguna}" >&2
    exit 1
  fi
fi

if command -v pdftotext >/dev/null 2>&1; then
  TEXT_OUTPUT=${TMPDIR:-/tmp}/entorno-nvim-mdpdf-text.$$
  trap 'rm -f -- "$TEXT_OUTPUT"' EXIT HUP INT TERM
  pdftotext "$OUTPUT" "$TEXT_OUTPUT"
  for expected in "Examen de ejemplo" "Tabla de puntuación" "Segunda parte" "puntuacion" "Página 1 de"; do
    if ! grep -Fq "$expected" "$TEXT_OUTPUT"; then
      printf 'Error: el PDF no contiene el texto esperado: %s\n' "$expected" >&2
      exit 1
    fi
  done
fi

printf '%s\n' "Comprobación Markdown → PDF correcta."
