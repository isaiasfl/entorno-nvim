#!/bin/sh
set -eu

fail() {
  tmux display-message -t "${origin_pane:-}" "Error: $*" 2>/dev/null || :
  exit 1
}

clean_label() {
  printf '%s' "$1" | LC_ALL=C tr -d '\000-\037\177' | sed 's/[|]/-/g' | cut -c 1-32
}

detect_context() {
  context_pane=$1
  context_window=$(tmux display-message -p -t "$context_pane" '#{window_id}' 2>/dev/null) || return 1
  window_role=$(tmux show-option -w -v -t "$context_window" @entorno_window_role 2>/dev/null || true)
  pane_role=$(tmux show-option -p -v -t "$context_pane" @entorno_role 2>/dev/null || true)
  if [ "$window_role" = git ]; then
    printf '%s\n' git
    return
  fi
  case "$pane_role" in
    editor | terminal) printf '%s\n' "$pane_role" ;;
    agent)
      active_agent=$(tmux show-option -p -v -t "$context_pane" @entorno_agent 2>/dev/null || true)
      if [ -n "$active_agent" ]; then
        printf 'agent/%s\n' "$active_agent"
      else
        printf '%s\n' agent
      fi
      ;;
    *) printf '%s\n' general ;;
  esac
}

category_rows() {
  case "${ENTORNO_HELP_CONTEXT:-general}" in
    editor) first=NEOVIM ;;
    agent*) first=IA ;;
    terminal) first=TERMINAL ;;
    git) first=GIT ;;
    *) first=TMUX ;;
  esac
  for category in "$first" NEOVIM MOVIMIENTO TMUX IA GIT TERMINAL; do
    case " ${seen:-} " in *" $category "*) continue ;; esac
    seen="${seen:-} $category"
    case "$category" in
      NEOVIM) description='Edicion, busqueda y temas' ;;
      MOVIMIENTO) description='Paneles, splits y tamanos' ;;
      TMUX) description='Ventanas y sesiones' ;;
      IA) description='Agentes y contexto' ;;
      GIT) description='Lazygit' ;;
      TERMINAL) description='Acceso al terminal' ;;
    esac
    printf '%-12s %s\t%s\n' "$category" "$description" "$category"
  done
}

action_rows() {
  case "$1" in
    TMUX)
      printf '%s\n' \
        'CTRL-A a     Ir al panel agente' \
        'CTRL-A i     Abrir selector IA' \
        'CTRL-A n     Ir a Neovim' \
        'CTRL-A t     Ir al terminal' \
        'CTRL-A g     Abrir lazygit' \
        'CTRL-A s     Gestionar sesiones' \
        'CTRL-A ?     Abrir esta ayuda'
      ;;
    NEOVIM)
      printf '%s\n' \
        'SPACE ff     Buscar archivos' \
        'SPACE fg     Buscar texto' \
        'SPACE gg     Abrir lazygit' \
        'SPACE ac     Enviar contexto a IA' \
        'SPACE ut     Elegir tema visual' \
        '             Catppuccin / Tokyo Night / Kanagawa'
      ;;
    IA)
      printf '%s\n' \
        'CTRL-A a     Volver al agente activo' \
        'CTRL-A i     Abrir selector IA' \
        'CTRL-A n     Volver a Neovim' \
        'SPACE ac     Enviar contexto desde Neovim'
      ;;
    GIT)
      printf '%s\n' \
        'CTRL-A g     Abrir o volver a lazygit' \
        'SPACE gg     Abrir lazygit desde Neovim' \
        'q            Cerrar lazygit' \
        '?            Ayuda propia de lazygit'
      ;;
    TERMINAL)
      printf '%s\n' \
        'CTRL-A t     Ir al terminal' \
        'CTRL-A n     Ir a Neovim' \
        'CTRL-A a     Ir al agente' \
        'CTRL-A g     Abrir lazygit' \
        'CTRL-A |     Dividir horizontalmente' \
        'CTRL-A -     Dividir verticalmente'
      ;;
    MOVIMIENTO)
      printf '%s\n' \
        'CTRL-A h/j/k/l  Navegar paneles tmux' \
        'CTRL-A H/J/K/L  Redimensionar paneles' \
        'CTRL-h/j/k/l    Navegar splits de Neovim' \
        'CTRL-A z        Maximizar o restaurar panel'
      ;;
    *) return 1 ;;
  esac
}

header() {
  printf 'ENTORNO-NVIM\nProyecto: %s\nContexto: %s' \
    "$(clean_label "${ENTORNO_HELP_PROJECT:-sin proyecto}")" \
    "${ENTORNO_HELP_CONTEXT:-general}"
}

fzf_select() {
  prompt=$1
  help_text=$2
  level=${3:-root}
  bindings='q:print(__quit__)+accept'
  [ "$level" = actions ] && bindings='q:print(__quit__)+accept,enter:ignore'
  if fzf --help 2>/dev/null | grep -q -- '--footer='; then
    fzf --no-sort --layout=reverse --delimiter='\t' --with-nth=1 \
      --header="$(header)" --header-first --footer="$help_text" \
      --footer-border=none --info=hidden --no-separator --no-scrollbar \
      --gutter=' ' --pointer='>' --prompt="$prompt" \
      --bind="$bindings"
  else
    fallback_header=$(printf '%s\n\n%s' "$(header)" "$help_text")
    fzf --no-sort --layout=reverse --delimiter='\t' --with-nth=1 \
      --header="$fallback_header" --info=hidden \
      --pointer='>' --prompt="$prompt" --bind="$bindings"
  fi
}

run_fzf() {
  while :; do
    selected=$(category_rows | fzf_select 'Categoria> ' 'Enter abrir   Esc/q cerrar') || return 0
    [ "$selected" = __quit__ ] && return 0
    category=${selected#*	}
    selected=$(action_rows "$category" | sed 's/$/\tinfo/' |
      fzf_select "$category> " 'Esc volver   q cerrar' actions) || continue
    [ "$selected" = __quit__ ] && return 0
  done
}

run_posix() {
  escape=$(printf '\033')
  while :; do
    clear 2>/dev/null || printf '\033[2J\033[H'
    header
    printf '\n\nCATEGORIAS\n\n'
    category_rows | awk -F '\t' '{ printf "  %s\n", $1 }'
    printf '\n[n] Neovim [m] Movimiento [t] tmux [i] IA [g] Git [e] Terminal\n'
    printf 'Pulsa categoria; Esc/q cierra: '
    choice=$(read_key) || return 0
    case "$choice" in
      n | N) category=NEOVIM ;; m | M) category=MOVIMIENTO ;;
      t | T) category=TMUX ;; i | I) category=IA ;;
      g | G) category=GIT ;; e | E) category=TERMINAL ;;
      q | Q | "$escape") return 0 ;; *) continue ;;
    esac
    clear 2>/dev/null || printf '\033[2J\033[H'
    printf 'ENTORNO-NVIM > %s\nProyecto: %s\n\n' "$category" \
      "$(clean_label "${ENTORNO_HELP_PROJECT:-sin proyecto}")"
    action_rows "$category"
    printf '\nEnter/Esc volver; q cerrar'
    choice=$(read_key) || return 0
    case "$choice" in q | Q) return 0 ;; esac
  done
}

read_key() {
  saved_stty=$(stty -g 2>/dev/null) || return 1
  trap 'stty "$saved_stty" 2>/dev/null || :; exit 0' HUP INT TERM
  stty -echo -icanon min 1 time 0
  key=$(dd bs=1 count=1 2>/dev/null) || key=
  stty "$saved_stty"
  trap - HUP INT TERM
  printf '%s' "$key"
}

run_interface() {
  if command -v fzf >/dev/null 2>&1 && [ -t 0 ] && [ -t 2 ]; then
    run_fzf
  else
    run_posix
  fi
}

case "${1:-}" in
  --categories) category_rows; exit 0 ;;
  --actions) [ "$#" -eq 2 ] || exit 2; action_rows "$2"; exit $? ;;
  --interface) [ "$#" -eq 1 ] || exit 2; run_interface; exit 0 ;;
  --context) [ "$#" -eq 2 ] || exit 2; detect_context "$2"; exit $? ;;
esac

[ "$#" -eq 2 ] || fail "uso interno: tmux-ayuda.sh cliente pane"
target_client=$1
origin_pane=$2
target_session=$(tmux display-message -p -t "$origin_pane" '#{session_id}' 2>/dev/null) ||
  fail "no se pudo identificar la sesion actual"
context=$(detect_context "$origin_pane") || fail "no se pudo detectar el contexto actual"

project=$(tmux show-option -v -t "$target_session" @entorno_project_name 2>/dev/null || true)
[ -n "$project" ] || project=${target_session#\$}
root_entry=$(tmux show-environment -t "$target_session" ENTORNO_NVIM_ROOT 2>/dev/null) ||
  fail "tmux no conoce ENTORNO_NVIM_ROOT para esta sesion"
case "$root_entry" in
  ENTORNO_NVIM_ROOT=*) project_root=${root_entry#*=} ;;
  *) fail "ENTORNO_NVIM_ROOT no es valida en esta sesion" ;;
esac
[ -x "$project_root/scripts/tmux-ayuda.sh" ] || fail "no se encuentra el helper de ayuda"

tmux display-popup -E -b rounded -w 58 -h 18 \
  -c "$target_client" \
  -t "$origin_pane" \
  -e "ENTORNO_HELP_PROJECT=$(clean_label "$project")" \
  -e "ENTORNO_HELP_CONTEXT=$context" \
  -e "ENTORNO_NVIM_ROOT=$project_root" \
  'exec "$ENTORNO_NVIM_ROOT/scripts/tmux-ayuda.sh" --interface' 2>/dev/null || :
exit 0
