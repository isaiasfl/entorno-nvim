#!/bin/sh
# Instala el diccionario español de Neovim dentro de .xdg, con SHA-256 fijado.
# Funciona igual en cualquier Linux, WSL2 o macOS: no depende de paquetes.
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/comun.sh"
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION"}
case "$XDG_ROOT" in
  /*) ;;
  *) XDG_ROOT="$PROJECT_ROOT/$XDG_ROOT" ;;
esac
SPELL_DIR="$XDG_ROOT/data/nvim/site/spell"

instalar() {
  dic_archivo=$1
  dic_esperado=$2
  dic_destino="$SPELL_DIR/$dic_archivo"
  if [ -f "$dic_destino" ] && [ "$(entorno_sha256 "$dic_destino")" = "$dic_esperado" ]; then
    printf 'Diccionario %s ya instalado y verificado.\n' "$dic_archivo"
    return 0
  fi
  mkdir -p "$SPELL_DIR"
  dic_temporal=$(mktemp "$SPELL_DIR/.$dic_archivo.XXXXXX")
  if ! entorno_descargar "$ENTORNO_SPELL_URL/$dic_archivo" "$dic_temporal" \
    || ! entorno_verificar_sha256 "$dic_temporal" "$dic_esperado"; then
    rm -f "$dic_temporal"
    return 1
  fi
  mv "$dic_temporal" "$dic_destino"
  printf 'Diccionario %s instalado en %s\n' "$dic_archivo" "$SPELL_DIR"
}

instalar es.utf-8.spl "$ENTORNO_SPELL_ES_SPL_SHA256"
# Sugerencias (z=) mas rapidas y precisas; sin el .sug tambien funcionan.
instalar es.utf-8.sug "$ENTORNO_SPELL_ES_SUG_SHA256"
