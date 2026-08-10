#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")

tmux_session_environment() {
  tmux_environment_name=$1
  tmux_environment_line=$(command tmux show-environment "$tmux_environment_name" 2>/dev/null) || return 1
  case "$tmux_environment_line" in
    "$tmux_environment_name"=*) printf '%s\n' "${tmux_environment_line#*=}" ;;
    *) return 1 ;;
  esac
}

# Un pane no recibe retroactivamente el entorno guardado en su sesion. El popup
# conserva TMUX y TMUX_PANE, por lo que puede recuperar aqui los valores que no
# estuvieran exportados en la shell desde la que se abrio.
if [ -n "${TMUX:-}" ]; then
  if [ -z "${ENTORNO_TMUX_SOCKET:-}" ]; then
    ENTORNO_TMUX_SOCKET=$(tmux_session_environment ENTORNO_TMUX_SOCKET) || ENTORNO_TMUX_SOCKET=
  fi
  if [ -z "${ENTORNO_TMUX_PROJECT_ROOTS:-}" ]; then
    ENTORNO_TMUX_PROJECT_ROOTS=$(tmux_session_environment ENTORNO_TMUX_PROJECT_ROOTS) || ENTORNO_TMUX_PROJECT_ROOTS=
  fi
  if [ -z "${ENTORNO_TMUX_PROJECT_DEPTH:-}" ]; then
    ENTORNO_TMUX_PROJECT_DEPTH=$(tmux_session_environment ENTORNO_TMUX_PROJECT_DEPTH) || ENTORNO_TMUX_PROJECT_DEPTH=
  fi
  if [ -z "${NVIM_BIN:-}" ]; then
    NVIM_BIN=$(tmux_session_environment NVIM_BIN) || NVIM_BIN=
  fi
fi

TMUX_CONFIG="$PROJECT_ROOT/tmux/tmux.conf"
TMUX_SOCKET=${ENTORNO_TMUX_SOCKET:-entorno-nvim}
MAX_DEPTH=${ENTORNO_TMUX_PROJECT_DEPTH:-5}

tmux_cmd() {
  command tmux -L "$TMUX_SOCKET" "$@"
}

tmux_new_session() {
  command tmux -L "$TMUX_SOCKET" -f "$TMUX_CONFIG" new-session "$@"
}

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

canonical_directory() {
  directory_operand=$1
  case "$directory_operand" in
    -*) directory_operand=./$directory_operand ;;
  esac
  CDPATH= cd "$directory_operand" 2>/dev/null && pwd -P
}

project_from_directory() {
  directory=$(canonical_directory "$1") || fail "no existe el directorio: $1"
  git_root=$(git -C "$directory" rev-parse --show-toplevel 2>/dev/null || true)
  if [ -n "$git_root" ]; then
    canonical_directory "$git_root"
  else
    printf '%s\n' "$directory"
  fi
}

find_projects() {
  roots=${ENTORNO_TMUX_PROJECT_ROOTS:-}
  [ -n "$roots" ] || fail "define ENTORNO_TMUX_PROJECT_ROOTS con raices separadas por dos puntos"
  command -v fzf >/dev/null 2>&1 || fail "fzf no esta disponible"

  if command -v fd >/dev/null 2>&1; then
    fd_bin=fd
  elif command -v fdfind >/dev/null 2>&1; then
    fd_bin=fdfind
  else
    fail "se requiere fd o fdfind para seleccionar proyectos"
  fi

  candidates=$(mktemp "${TMPDIR:-/tmp}/entorno-nvim-proyectos.XXXXXX")
  chmod 600 "$candidates"
  trap 'rm -f "$candidates"' EXIT HUP INT TERM

  remaining=$roots
  while :; do
    root=${remaining%%:*}
    if [ "$remaining" = "$root" ]; then
      last=1
    else
      last=0
      remaining=${remaining#*:}
    fi

    [ -n "$root" ] || fail "ENTORNO_TMUX_PROJECT_ROOTS contiene una raiz vacia"
    root=$(canonical_directory "$root") || fail "raiz de proyectos inexistente: $root"

    "$fd_bin" --hidden --type directory --max-depth "$MAX_DEPTH" '^\.git$' "$root" 2>/dev/null |
      while IFS= read -r marker; do
        project_from_directory "$(dirname "$marker")"
      done >> "$candidates"

    "$fd_bin" --hidden --type file --max-depth "$MAX_DEPTH" '^\.git$' "$root" 2>/dev/null |
      while IFS= read -r marker; do
        project_from_directory "$(dirname "$marker")"
      done >> "$candidates"

    [ "$last" -eq 0 ] || break
  done

  sorted=$(mktemp "${TMPDIR:-/tmp}/entorno-nvim-proyectos-ordenados.XXXXXX")
  chmod 600 "$sorted"
  sort -u "$candidates" > "$sorted"
  mv "$sorted" "$candidates"

  [ -s "$candidates" ] || fail "no se encontraron repositorios Git en las raices configuradas"
  selection=$(fzf --prompt='Proyecto> ' < "$candidates") || exit 0
  [ -n "$selection" ] || exit 0
  printf '%s\n' "$selection"
}

session_name() {
  base=$(basename "$1")
  base=$(printf '%s' "$base" | tr -c '[:alnum:]_-' '_')
  checksum=$(printf '%s' "$1" | cksum)
  checksum=${checksum%% *}
  printf '%s-%s\n' "$base" "$checksum"
}

start_editor() {
  pane=$1
  nvim_command=${NVIM_BIN:-nvim}
  nvim_path=$(command -v "$nvim_command" 2>/dev/null || true)
  [ -n "$nvim_path" ] && [ -x "$nvim_path" ] || fail "NVIM_BIN no es ejecutable: $nvim_command"

  quoted=$(printf '%s' "$nvim_path" | sed "s/'/'\\\\''/g")
  quoted_socket=$(printf '%s' "$TMUX_SOCKET" | sed "s/'/'\\\\''/g")
  quoted_root=$(printf '%s' "$PROJECT_ROOT" | sed "s/'/'\\\\''/g")
  tmux_cmd send-keys -l -t "$pane" \
    "export ENTORNO_TMUX_SOCKET='$quoted_socket' ENTORNO_NVIM_ROOT='$quoted_root'; '$quoted' ."
  tmux_cmd send-keys -t "$pane" Enter
}

[ "$#" -le 1 ] || fail "uso: scripts/proyecto.sh [ruta]"
command -v tmux >/dev/null 2>&1 || fail "tmux no esta instalado"
command -v git >/dev/null 2>&1 || fail "Git no esta disponible"
[ -f "$TMUX_CONFIG" ] || fail "falta la configuracion: $TMUX_CONFIG"
case "$MAX_DEPTH" in
  '' | *[!0-9]*) fail "ENTORNO_TMUX_PROJECT_DEPTH debe ser un entero positivo" ;;
  0) fail "ENTORNO_TMUX_PROJECT_DEPTH debe ser mayor que cero" ;;
esac

if [ "$#" -eq 1 ]; then
  project=$(project_from_directory "$1")
else
  project=$(find_projects)
fi
[ -n "$project" ] || exit 0

session=$(session_name "$project")

if tmux_cmd list-sessions >/dev/null 2>&1; then
  tmux_cmd source-file "$TMUX_CONFIG"
fi

if ! tmux_cmd has-session -t "=$session" 2>/dev/null; then
  tmux_new_session -d -s "$session" -n work -c "$project"
  editor_pane=$(tmux_cmd display-message -p -t "=$session:1.1" '#{pane_id}')
  tmux_cmd split-window -v -p 25 -t "$editor_pane" -c "$project" >/dev/null
  agent_pane=$(tmux_cmd split-window -h -p 35 -t "$editor_pane" -c "$project" -P -F '#{pane_id}')
  tmux_cmd set-option -p -t "$editor_pane" @entorno_role editor
  tmux_cmd set-option -p -t "$agent_pane" @entorno_role agent
  tmux_cmd select-pane -t "$editor_pane"
  start_editor "$editor_pane"
fi

tmux_cmd set-environment -t "=$session" ENTORNO_TMUX_SOCKET "$TMUX_SOCKET"
tmux_cmd set-environment -t "=$session" ENTORNO_NVIM_ROOT "$PROJECT_ROOT"
tmux_cmd set-environment -t "=$session" ENTORNO_TMUX_PROJECT_DEPTH "$MAX_DEPTH"
if [ -n "${ENTORNO_TMUX_PROJECT_ROOTS:-}" ]; then
  tmux_cmd set-environment -t "=$session" ENTORNO_TMUX_PROJECT_ROOTS "$ENTORNO_TMUX_PROJECT_ROOTS"
fi
if [ -n "${NVIM_BIN:-}" ]; then
  tmux_cmd set-environment -t "=$session" NVIM_BIN "$NVIM_BIN"
fi

if [ "${ENTORNO_TMUX_NO_ATTACH:-0}" = "1" ]; then
  printf '%s\n' "$session"
elif [ -n "${TMUX:-}" ]; then
  current_socket=${TMUX%%,*}
  target_socket=$(tmux_cmd display-message -p '#{socket_path}')
  if [ "$current_socket" != "$target_socket" ]; then
    fail "tmux anidado no admitido: separa la sesion actual y ejecuta proyecto.sh desde una terminal externa"
  fi
  tmux_cmd switch-client -t "=$session"
else
  exec tmux -L "$TMUX_SOCKET" attach-session -t "=$session"
fi
