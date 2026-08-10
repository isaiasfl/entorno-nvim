#!/bin/sh

entorno_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{ print $1 }'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{ print $1 }'
  else
    printf '%s\n' "Error: se requiere sha256sum o shasum para verificar descargas." >&2
    return 1
  fi
}

entorno_verificar_sha256() {
  archivo=$1
  esperado=$2
  obtenido=$(entorno_sha256 "$archivo") || return 1
  if [ "$obtenido" != "$esperado" ]; then
    printf 'Error: SHA-256 incorrecto para %s.\n' "$archivo" >&2
    printf 'Esperado: %s\nObtenido: %s\n' "$esperado" "$obtenido" >&2
    return 1
  fi
}

entorno_descargar() {
  url=$1
  destino=$2
  command -v curl >/dev/null 2>&1 || {
    printf '%s\n' "Error: se requiere curl; no se ejecutan instaladores remotos alternativos." >&2
    return 1
  }
  curl --fail --location --proto '=https' --tlsv1.2 --output "$destino" "$url"
}
