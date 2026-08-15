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

render_help() {
  project=$(clean_label "${ENTORNO_HELP_PROJECT:-sin proyecto}")
  context=${ENTORNO_HELP_CONTEXT:-general}

  printf '%s\n' \
    'ENTORNO-NVIM' \
    "Proyecto: $project" \
    "Contexto: $context" \
    '' \
    'TMUX' \
    '  a agente   i selector IA   n editor' \
    '  t terminal g lazygit       s sesiones' \
    ''

  case "$context" in
    editor)
      printf '%s\n' \
        'NEOVIM' \
        '  <leader>ff  buscar archivos' \
        '  <leader>fg  buscar texto' \
        '  <leader>gg  abrir lazygit' \
        '  <leader>ac  enviar contexto IA'
      ;;
    agent*)
      printf '%s\n' \
        'IA' \
        '  Ctrl-a i  selector IA' \
        '  Ctrl-a n  volver al editor' \
        '  Ctrl-a a  volver al agente activo'
      ;;
    terminal)
      printf '%s\n' \
        'TERMINAL' \
        '  Ctrl-a n  editor     Ctrl-a a  agente' \
        '  Ctrl-a g  lazygit    Ctrl-a i  selector IA'
      ;;
    git)
      printf '%s\n' \
        'GIT' \
        '  q          cerrar lazygit' \
        '  ?          ayuda de lazygit' \
        '  Ctrl-a n   editor    Ctrl-a t  terminal'
      ;;
    *)
      printf '%s\n' \
        'GENERAL' \
        '  Ctrl-a n  editor     Ctrl-a a  agente' \
        '  Ctrl-a t  terminal   Ctrl-a g  lazygit'
      ;;
  esac

  printf '\n%s\n' 'Esc/q cerrar'
}

wait_to_close() {
  [ -t 0 ] && [ -t 1 ] || return 0
  saved_stty=$(stty -g 2>/dev/null || true)
  [ -n "$saved_stty" ] || return 0
  trap 'stty "$saved_stty" 2>/dev/null || :; exit 0' HUP INT TERM
  stty -echo -icanon min 1 time 0
  escape=$(printf '\033')
  while :; do
    key=$(dd bs=1 count=1 2>/dev/null || true)
    case "$key" in
      q | "$escape") break ;;
    esac
  done
  stty "$saved_stty"
  trap - HUP INT TERM
}

if [ "$#" -eq 1 ] && [ "$1" = --render ]; then
  render_help
  wait_to_close
  exit 0
fi
if [ "$#" -eq 2 ] && [ "$1" = --context ]; then
  detect_context "$2"
  exit $?
fi

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

tmux display-popup -E -b simple -w 50 -h 18 \
  -c "$target_client" \
  -t "$origin_pane" \
  -e "ENTORNO_HELP_PROJECT=$(clean_label "$project")" \
  -e "ENTORNO_HELP_CONTEXT=$context" \
  -e "ENTORNO_NVIM_ROOT=$project_root" \
  'exec "$ENTORNO_NVIM_ROOT/scripts/tmux-ayuda.sh" --render' 2>/dev/null || :
exit 0
