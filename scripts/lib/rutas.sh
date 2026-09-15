#!/bin/sh
# Requiere SCRIPT_DIR y versiones.sh. No crea directorios ni modifica HOME.
ENTORNO_ROOT=$(dirname "$SCRIPT_DIR")
ENTORNO_TOOLS_ROOT=${ENTORNO_TOOLS_ROOT:-"$ENTORNO_ROOT/.tools"}
case "$ENTORNO_TOOLS_ROOT" in
  /*) ;;
  *) ENTORNO_TOOLS_ROOT="$ENTORNO_ROOT/$ENTORNO_TOOLS_ROOT" ;;
esac
export ENTORNO_TOOLS_ROOT
