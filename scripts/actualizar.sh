#!/bin/sh
# Actualiza entorno-nvim y repite la instalacion con el perfil recordado.
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
# Las librerias se cargan despues de git pull y de corregir finales de linea:
# en una copia antigua con CRLF todavia no se pueden ejecutar.
PERFIL_GUARDADO=${ENTORNO_PERFIL_GUARDADO:-"$PROJECT_ROOT/.xdg/perfil-alumno"}
TMUX_SOCKET=${ENTORNO_TMUX_SOCKET:-entorno-nvim}

uso() {
  cat <<'EOF'
Uso: ./scripts/actualizar.sh [--completo]

Descarga la última versión de entorno-nvim y repite la instalación con el
perfil que elegiste (DWEC o SI). Antes:
  - repara archivos alterados solo por finales de línea de Windows (^M);
  - restaura nvim/lazy-lock.json si se modificó sin querer;
  - ofrece cerrar las sesiones abiertas del entorno (guarda antes tu trabajo).

  --completo   reinstala con el instalador completo del profesor
  -h, --help   muestra esta ayuda
EOF
}

fallo() {
  printf '\nError: %s\n' "$1" >&2
  shift
  [ "$#" -eq 0 ] || printf '%s\n' "$@" >&2
  exit 1
}

preguntar_si() {
  [ -t 0 ] || return 1
  printf '%s [S/n]: ' "$1"
  IFS= read -r respuesta || return 1
  case "$respuesta" in
    '' | s | S | si | Si | SI | sí | Sí | y | Y) return 0 ;;
    *) return 1 ;;
  esac
}

# Archivos del repositorio con CRLF en disco cuyo contenido es igual al de
# Git salvo el final de línea: se vuelven a escribir con LF.
normalizar_finales() {
  git ls-files --eol | grep 'w/crlf' | grep 'eol=lf' | cut -f2- | while IFS= read -r archivo; do
    [ -f "$archivo" ] || continue
    git diff --ignore-cr-at-eol --quiet -- "$archivo" || continue
    rm -f "$archivo"
    git checkout -q -- "$archivo"
    printf 'Final de línea corregido: %s\n' "$archivo"
  done
}

cerrar_sesiones() {
  sesiones=$(tmux -L "$TMUX_SOCKET" list-sessions -F '#S' 2>/dev/null) || return 0
  [ -n "$sesiones" ] || return 0
  case "${TMUX:-}" in
    *"/$TMUX_SOCKET,"*)
      fallo 'estás dentro de una sesión del entorno.' \
        'Sal con Ctrl-a y después d, y ejecuta de nuevo desde una terminal normal:' \
        "  $PROJECT_ROOT/scripts/actualizar.sh"
      ;;
  esac
  printf '\n%s\n' 'Sesiones abiertas del entorno (usan la versión anterior):'
  printf '  %s\n' $sesiones
  printf '%s\n' 'Guarda tu trabajo en Neovim antes de cerrarlas.'
  if preguntar_si '¿Cerrarlas ahora?'; then
    tmux -L "$TMUX_SOCKET" kill-server 2>/dev/null || true
    printf '%s\n' 'Sesiones cerradas.'
  else
    printf '%s\n' 'Se mantienen abiertas. Ciérralas antes de volver a usarlas con:' \
      "  tmux -L $TMUX_SOCKET kill-server"
  fi
}

main() {
  completo=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --completo) completo=1 ;;
      -h | --help | --ayuda) uso; exit 0 ;;
      *) printf 'Error: opción desconocida: %s\n' "$1" >&2; uso >&2; exit 2 ;;
    esac
    shift
  done

  [ "$(id -u)" -ne 0 ] || fallo 'no ejecutes la actualización como root ni con sudo.'
  command -v git >/dev/null 2>&1 || fallo 'Git no está instalado.'
  cd "$PROJECT_ROOT"
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || fallo "$PROJECT_ROOT no es un repositorio Git." \
      'Vuelve a descargarlo con: git clone https://github.com/isaiasfl/entorno-nvim.git'

  printf '%s\n' 'ACTUALIZAR ENTORNO-NVIM' "Carpeta: $PROJECT_ROOT"

  printf '\n%s\n' '1/4 Revisando cambios locales...'
  normalizar_finales
  if ! git diff --quiet -- nvim/lazy-lock.json; then
    git checkout -q -- nvim/lazy-lock.json
    printf '%s\n' 'Restaurado nvim/lazy-lock.json: las versiones de plugins las fija el entorno.'
  fi
  cambios=$(git status --porcelain --untracked-files=no)
  if [ -n "$cambios" ]; then
    printf '%s\n' "$cambios" >&2
    fallo 'hay archivos del entorno modificados (lista de arriba).' \
      'El entorno no debe editarse a mano. Si no necesitas esos cambios, descártalos:' \
      '  git restore .' \
      'Si quieres conservarlos aparte: git stash' \
      'Después repite: ./scripts/actualizar.sh'
  fi

  printf '\n%s\n' '2/4 Sesiones abiertas...'
  cerrar_sesiones

  printf '\n%s\n' '3/4 Descargando la última versión (git pull --ff-only)...'
  antes=$(git rev-parse HEAD)
  git pull --ff-only || fallo 'no se pudo actualizar de forma segura.' \
    'Suele deberse a no tener conexión o a commits propios hechos en esta carpeta.' \
    'Copia el mensaje anterior y pide ayuda al profesor, o vuelve a clonar el' \
    'entorno en otra carpeta.'
  despues=$(git rev-parse HEAD)
  normalizar_finales
  if [ "$antes" = "$despues" ]; then
    printf '%s\n' 'Ya tenías la última versión.'
  else
    printf '%s\n' 'Novedades:'
    git log --format='  - %s' "$antes..$despues" | head -n 15
  fi
  . "$SCRIPT_DIR/lib/versiones.sh"
  . "$SCRIPT_DIR/lib/rutas.sh"
  . "$SCRIPT_DIR/lib/plataforma.sh"
  if entorno_ruta_windows_wsl "$PROJECT_ROOT"; then
    printf '\n'
    entorno_explicar_ruta_windows "$PROJECT_ROOT"
  fi

  printf '\n%s\n' '4/4 Reinstalando lo que haya cambiado...'
  if [ "$completo" -eq 1 ]; then
    exec "$SCRIPT_DIR/instalar.sh" --yes
  fi
  perfil=
  if [ -r "$PERFIL_GUARDADO" ]; then
    perfil=$(sed -n '1p' "$PERFIL_GUARDADO")
  fi
  case "$perfil" in
    dwec | si) exec "$SCRIPT_DIR/instalar-alumno.sh" --perfil "$perfil" --yes ;;
    *) exec "$SCRIPT_DIR/instalar-alumno.sh" ;;
  esac
}

# Todo el cuerpo esta en main: git pull puede reescribir este archivo mientras
# se ejecuta y la shell ya lo tiene leido completo.
main "$@"
