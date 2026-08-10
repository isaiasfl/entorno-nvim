#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
EXAMPLE="$PROJECT_ROOT/examples/examen/examen.md"
OUTPUT="$PROJECT_ROOT/examples/examen/examen.pdf"
TEMPORARY_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-mdpdf-test.XXXXXX")
trap 'rm -rf "$TEMPORARY_DIR"' EXIT HUP INT TERM

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

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

SPACED_DIR="$TEMPORARY_DIR/ruta con espacios"
mkdir -p "$SPACED_DIR"
OPTIONAL_MARKDOWN="$SPACED_DIR/sin metadatos.md"
OPTIONAL_PDF="$SPACED_DIR/sin metadatos.pdf"
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

PARTIAL_MARKDOWN="$SPACED_DIR/metadatos parciales.md"
PARTIAL_PDF="$SPACED_DIR/metadatos parciales.pdf"
LONG_URL='https://example.invalid/ruta/sin/espacios/abcdefghijklmnopqrstuvwxyz'
LONG_URL="${LONG_URL}0123456789abcdefghijklmnopqrstuvwxyz0123456789"
LONG_HASH='aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
LONG_HASH="${LONG_HASH}aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
printf '%s\n' \
  '---' \
  'title: "Metadatos parciales"' \
  'module: '\''Módulo "Especial"; grupo {A}'\''' \
  'teacher: '\''Isaías "FL"'\''' \
  '---' \
  '' \
  '# Metadatos parciales' \
  '' \
  '| Identificador | Valor |' \
  '| --- | --- |' \
  "| URL larga | $LONG_URL |" \
  "| Hash | $LONG_HASH |" \
  >"$PARTIAL_MARKDOWN"

"$PROJECT_ROOT/scripts/markdown-pdf.sh" "$PARTIAL_MARKDOWN" "$PARTIAL_PDF"

ESCAPED_HTML="$SPACED_DIR/metadatos escapados.html"
printf '%s\n' '# Prueba de escape CSS' |
  pandoc --from=markdown --to=html5 --standalone \
    --metadata=title=Prueba \
    --metadata='module=Módulo "Especial" \ prueba' \
    --lua-filter="$PROJECT_ROOT/markdown/filters/metadata-css.lua" \
    --template="$PROJECT_ROOT/markdown/templates/documento.html" \
    --output="$ESCAPED_HTML"
grep -Fq -- '--cabecera-izquierda: "Módulo \"Especial\" \\ prueba";' "$ESCAPED_HTML" ||
  fail "el filtro no escapó las comillas o barras inversas para CSS"

if command -v pdftotext >/dev/null 2>&1; then
  PARTIAL_TEXT="$SPACED_DIR/metadatos parciales.txt"
  pdftotext "$PARTIAL_PDF" "$PARTIAL_TEXT"
  grep -Fq 'Módulo “Especial”; grupo {A}' "$PARTIAL_TEXT" ||
    fail "module con caracteres especiales no llegó correctamente a la cabecera"
  grep -Fq 'Profesor: Isaías “FL”' "$PARTIAL_TEXT" ||
    fail "teacher con caracteres especiales no llegó correctamente al pie"
  if grep -Fq 'centre' "$PARTIAL_TEXT"; then
    fail "centre ausente generó contenido inesperado"
  fi
  grep -Fq 'Página 1 de 1' "$PARTIAL_TEXT" || fail "falta numeración en el documento parcial"
fi

BROWSER_ERROR="$TEMPORARY_DIR/navegador-ausente.log"
if CHROMIUM_BIN="$TEMPORARY_DIR/chromium-inexistente" \
  "$PROJECT_ROOT/scripts/markdown-pdf.sh" "$OPTIONAL_MARKDOWN" "$OPTIONAL_PDF" \
  >"$BROWSER_ERROR" 2>&1; then
  fail "un CHROMIUM_BIN inexistente no produjo error"
fi
grep -Fq 'CHROMIUM_BIN no es un navegador ejecutable' "$BROWSER_ERROR" ||
  fail "la ausencia de navegador no produjo un error claro"

NVIM_TEST_COMMAND="+lua local ok, err = pcall(dofile, vim.env.ENTORNO_NVIM_MARKDOWN_PDF_TEST);"
NVIM_TEST_COMMAND="${NVIM_TEST_COMMAND} if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end"
ENTORNO_NVIM_MARKDOWN_PDF_TEST="$PROJECT_ROOT/tests/comprobar_markdown_pdf.lua" \
  "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
  "$NVIM_TEST_COMMAND" \
  "+qa"

printf '%s\n' "Comprobación Markdown → PDF correcta."
