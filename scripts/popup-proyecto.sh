#!/bin/sh
set -eu

[ "$#" -eq 3 ] || {
  printf '%s\n' "Error: uso interno: popup-proyecto.sh cliente pane sesion" >&2
  exit 1
}

target_client=$1
target_pane=$2
target_session=$3

root_entry=$(tmux show-environment -t "$target_session" ENTORNO_NVIM_ROOT 2>/dev/null) || {
  printf '%s\n' "Error: tmux no conoce ENTORNO_NVIM_ROOT para esta sesion." >&2
  exit 1
}
case "$root_entry" in
  ENTORNO_NVIM_ROOT=*) project_root=${root_entry#*=} ;;
  *)
    printf '%s\n' "Error: ENTORNO_NVIM_ROOT no es valida en esta sesion." >&2
    exit 1
    ;;
esac

[ -n "$project_root" ] && [ -x "$project_root/scripts/proyecto.sh" ] || {
  printf '%s\n' "Error: la raiz de entorno-nvim no contiene scripts/proyecto.sh." >&2
  exit 1
}

pane_directory=$(tmux display-message -p -t "$target_pane" '#{pane_current_path}')
exec tmux display-popup -E -b simple -T " Proyectos " -w 85% -h 75% \
  -c "$target_client" \
  -t "$target_pane" \
  -d "$pane_directory" \
  -e "ENTORNO_SOURCE_CLIENT=$target_client" \
  -e "ENTORNO_SOURCE_SESSION=$target_session" \
  -e "ENTORNO_NVIM_ROOT=$project_root" \
  'exec "$ENTORNO_NVIM_ROOT/scripts/proyecto.sh"'
