#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
EXAMPLE="$PROJECT_ROOT/examples/examen/examen.md"
OUTPUT="$PROJECT_ROOT/examples/examen/examen.pdf"
TEMPORARY_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-mdpdf-test.XXXXXX")
trap 'rm -rf -- "$TEMPORARY_DIR"' EXIT HUP INT TERM

"$PROJECT_ROOT/scripts/markdown-pdf.sh" "$EXAMPLE" "$OUTPUT"

if command -v pdfinfo >/dev/null 2>&1; then
  PAGES=$(pdfinfo "$OUTPUT" | awk '/^Pages:/ { print $2 }')
  if [ -z "$PAGES" ] || [ "$PAGES" -lt 2 ]; then
    printf 'Error: se esperaban al menos dos páginas y se obtuvieron %s.\n' "${PAGES:-ninguna}" >&2
    exit 1
  fi
fi

if command -v pdftotext >/dev/null 2>&1; then
  TEXT_OUTPUT="$TEMPORARY_DIR/examen.txt"
  pdftotext "$OUTPUT" "$TEXT_OUTPUT"
  for expected in \
    "Examen de ejemplo" \
    "Tabla de puntuación" \
    "Segunda parte" \
    "puntuacion" \
    "Desarrollo Web en Entorno Cliente" \
    "IES Hermenegildo Lanz" \
    "Profesor: Isaías FL" \
    "Página 1 de 2" \
    "Página 2 de 2"
  do
    if ! grep -Fq "$expected" "$TEXT_OUTPUT"; then
      printf 'Error: el PDF no contiene el texto esperado: %s\n' "$expected" >&2
      exit 1
    fi
  done
fi

OPTIONAL_MARKDOWN="$TEMPORARY_DIR/sin-metadatos.md"
OPTIONAL_PDF="$TEMPORARY_DIR/sin-metadatos.pdf"
printf '%s\n' \
  '---' \
  'title: "Documento sin metadatos marginales"' \
  '---' \
  '' \
  '# Documento sin metadatos marginales' \
  '' \
  'Contenido de prueba.' >"$OPTIONAL_MARKDOWN"

"$PROJECT_ROOT/scripts/markdown-pdf.sh" "$OPTIONAL_MARKDOWN" "$OPTIONAL_PDF"

if command -v pdftotext >/dev/null 2>&1; then
  OPTIONAL_TEXT="$TEMPORARY_DIR/sin-metadatos.txt"
  pdftotext "$OPTIONAL_PDF" "$OPTIONAL_TEXT"
  if grep -Fq "Profesor:" "$OPTIONAL_TEXT"; then
    printf '%s\n' "Error: teacher ausente no debe generar un pie de profesor." >&2
    exit 1
  fi
  if ! grep -Fq "Página 1 de 1" "$OPTIONAL_TEXT"; then
    printf '%s\n' "Error: falta la numeración automática sin metadatos opcionales." >&2
    exit 1
  fi
fi

printf '%s\n' "Comprobación Markdown → PDF correcta."
