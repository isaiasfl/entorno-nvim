#!/bin/sh
set -eu

fail() {
  tmux display-message -t "${origin_pane:-}" "Error: $*" 2>/dev/null || :
  exit 1
}

[ "$#" -eq 2 ] || fail "uso interno: popup-agente.sh cliente pane"
target_client=$1
origin_pane=$2
target_session=$(tmux display-message -p -t "$origin_pane" '#{session_id}' 2>/dev/null) ||
  fail "no se pudo identificar la sesion actual"

panes=$(tmux list-panes -s -t "$target_session" -F '#{pane_id}|#{@entorno_role}' 2>/dev/null) ||
  fail "no se pudieron consultar los paneles de la sesion"
agent_pane=
agent_panes=0
while IFS='|' read -r pane_id pane_role; do
  [ "$pane_role" = agent ] || continue
  agent_pane=$pane_id
  agent_panes=$((agent_panes + 1))
done <<EOF
$panes
EOF

[ "$agent_panes" -gt 0 ] || fail "no existe ningun panel con @entorno_role=agent"
[ "$agent_panes" -eq 1 ] || fail "hay mas de un panel con @entorno_role=agent"
selector_state=$(tmux show-option -p -v -t "$agent_pane" @entorno_selector_state 2>/dev/null || true)
[ "$selector_state" = ready ] ||
  fail "el selector IA no esta esperando; usa Ctrl-a a para volver al agente activo"

root_entry=$(tmux show-environment -t "$target_session" ENTORNO_NVIM_ROOT 2>/dev/null) ||
  fail "tmux no conoce ENTORNO_NVIM_ROOT para esta sesion"
case "$root_entry" in
  ENTORNO_NVIM_ROOT=*) project_root=${root_entry#*=} ;;
  *) fail "ENTORNO_NVIM_ROOT no es valida en esta sesion" ;;
esac
[ -x "$project_root/scripts/selector-agente.sh" ] ||
  fail "no se encuentra el selector de agentes"

agent_style=$(tmux select-pane -g -t "$agent_pane" 2>/dev/null || true)
[ -n "$agent_style" ] || agent_style=default
restore_agent_style() {
  tmux select-pane -t "$agent_pane" -P "$agent_style" 2>/dev/null || :
}
trap 'restore_agent_style' EXIT HUP INT TERM
tmux select-pane -t "$agent_pane" -P 'fg=colour0,bg=colour0'

tmux display-popup -E -b simple -w 30 -h 11 \
  -c "$target_client" \
  -t "$origin_pane" \
  -e "ENTORNO_AGENT_TARGET_PANE=$agent_pane" \
  -e "ENTORNO_AGENT_SELECTOR_POPUP=1" \
  -e "ENTORNO_NVIM_ROOT=$project_root" \
  'choice=$("$ENTORNO_NVIM_ROOT/scripts/selector-agente.sh" --choose-only) || exit 0
  [ -n "$choice" ] || exit 0
  case "$choice" in
    codex) input=Codex ;;
    opencode) input=OpenCode ;;
    claude) input=Claude ;;
    pi) input=Pi ;;
    shell) input=Shell ;;
    exit) exit 0 ;;
    *) exit 1 ;;
  esac
  tmux send-keys -t "$ENTORNO_AGENT_TARGET_PANE" C-u
  tmux send-keys -l -t "$ENTORNO_AGENT_TARGET_PANE" "$input"
  tmux send-keys -t "$ENTORNO_AGENT_TARGET_PANE" Enter' 2>/dev/null || :

trap - EXIT HUP INT TERM
restore_agent_style
# Esc, el cierre del cliente y una segunda invocacion mientras el popup sigue
# activo pueden hacer que display-popup devuelva 1. Tras superar las
# validaciones anteriores son cierres normales de UX, no errores de run-shell.
exit 0
