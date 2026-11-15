#!/bin/sh
# Instalador de una linea para el alumnado.
#
#   curl -fsSL https://raw.githubusercontent.com/isaiasfl/entorno-nvim/main/install.sh | bash
#
# Solo descarga o actualiza el repositorio y entrega el control al instalador
# real (scripts/instalar-alumno.sh), que verifica cada binario con SHA-256.
# No usa sudo ni ejecuta nada que no sea Git y el propio entorno.
set -eu

REPO=${ENTORNO_NVIM_URL:-https://github.com/isaiasfl/entorno-nvim.git}
RAMA=${ENTORNO_NVIM_RAMA:-main}
DESTINO=${ENTORNO_NVIM_DIR:-$HOME/entorno-nvim}

fallo() {
  printf '\nError: %s\n' "$1" >&2
  shift
  [ "$#" -eq 0 ] || printf '%s\n' "$@" >&2
  exit 1
}

# Con `curl ... | bash` la entrada estandar es este script: las preguntas del
# instalador tienen que leer del terminal. Se comprueba en un subshell porque
# un `exec` fallido cerraria el propio script.
ENTRADA=/dev/null
if (exec 9</dev/tty) 2>/dev/null; then
  ENTRADA=/dev/tty
fi

# Git es imprescindible para descargar el entorno. Si falta se ofrece
# instalarlo, siempre con confirmacion: nunca se usa sudo a escondidas.
if ! command -v git >/dev/null 2>&1; then
  case "$(sed -n 's/^ID=//p' /etc/os-release 2>/dev/null | tr -d '"')" in
    debian | ubuntu | pop) COMANDO='sudo apt-get update && sudo apt-get install -y git' ;;
    arch | cachyos | omarchy) COMANDO='sudo pacman -S --needed git' ;;
    *) COMANDO='' ;;
  esac
  printf '\n%s\n' '------------------------------------------------------------'
  printf 'Falta Git, necesario para descargar el entorno\n'
  if [ -n "$COMANDO" ]; then
    printf 'Se ejecutara:  %s\n' "$COMANDO"
    printf 'Escribe s y Enter para instalarlo, o Enter para cancelar.\n'
  else
    printf 'Instalalo con el gestor de tu sistema y repite este comando.\n'
  fi
  printf '%s\n' '------------------------------------------------------------'
  printf '> '
  RESPUESTA=
  IFS= read -r RESPUESTA <"$ENTRADA" || RESPUESTA=
  [ -n "$COMANDO" ] || exit 1
  case "$RESPUESTA" in
    s | S | si | Si | SI | sí | Sí | y | Y) sh -c "$COMANDO" || exit 1 ;;
    *) fallo 'Git sigue sin estar instalado; no se ha modificado nada.' ;;
  esac
  command -v git >/dev/null 2>&1 || fallo 'Git no quedo disponible despues de instalarlo.'
fi

if [ -d "$DESTINO/.git" ]; then
  printf 'El entorno ya esta en %s: se actualiza.\n\n' "$DESTINO"
  cd "$DESTINO" || fallo "no se puede entrar en $DESTINO"
  TAREA=./scripts/actualizar.sh
else
  if [ -e "$DESTINO" ]; then
    fallo "$DESTINO ya existe y no es un repositorio Git." \
      'Muevelo o borralo, o indique otra carpeta con ENTORNO_NVIM_DIR.'
  fi
  printf 'Descargando el entorno en %s...\n\n' "$DESTINO"
  git clone --quiet --branch "$RAMA" "$REPO" "$DESTINO" ||
    fallo 'no se pudo descargar el repositorio.' 'Compruebe la conexion y repita.'
  cd "$DESTINO" || fallo "no se puede entrar en $DESTINO"
  TAREA=./scripts/instalar-alumno.sh
fi

[ -x "$TAREA" ] || fallo "la copia descargada no incluye $TAREA"

# Se ejecuta como hijo, no con exec, para poder relevar la shell al final.
# La marca evita que el instalador repita el aviso del PATH: aquí se resuelve.
export ENTORNO_NVIM_BOOTSTRAP=1
set +e
"$TAREA" <"$ENTRADA"
estado=$?
set -e
[ "$estado" -eq 0 ] || exit "$estado"

# Un script no puede cambiar el PATH de la terminal que lo lanzo. Si
# entorno-dev ya existe pero aun no se encuentra, se abre una shell nueva.
if ! command -v entorno-dev >/dev/null 2>&1 && [ -x "$HOME/.local/bin/entorno-dev" ] && [ -t 1 ]; then
  nueva=${SHELL:-/bin/bash}
  [ -x "$nueva" ] || nueva=/bin/bash
  printf '\nSe abre una terminal nueva para que entorno-dev este disponible.\n'
  # La entrada debe ser el terminal: heredando la tuberia de `curl`, bash
  # arrancaria no interactivo y no leeria ~/.bashrc. El PATH se pasa ademas de
  # forma explicita para no depender de los archivos de inicio del shell.
  exec env PATH="$HOME/.local/bin:$PATH" "$nueva" -l <"$ENTRADA"
fi
