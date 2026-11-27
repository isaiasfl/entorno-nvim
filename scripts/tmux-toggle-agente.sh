#!/bin/sh
set -eu

TMUX_SOCKET=${ENTORNO_TMUX_SOCKET:-}

tmux_cmd() {
  if [ -n "$TMUX_SOCKET" ]; then
    command tmux -L "$TMUX_SOCKET" "$@"
  else
    command tmux "$@"
  fi
}

origin_pane=${1:-${TMUX_PANE:-}}

show_error() {
  message=$1
  if [ -n "$origin_pane" ]; then
    tmux_cmd display-message -t "$origin_pane" "$message" 2>/dev/null || :
  fi
  printf '%s\n' "$message" >&2
}

[ -n "${TMUX:-}" ] || {
  printf '%s\n' "Error: no esta dentro de una sesion tmux" >&2
  exit 1
}
[ -n "$origin_pane" ] || {
  printf '%s\n' "Error: no se pudo identificar el panel tmux actual" >&2
  exit 1
}

session=$(tmux_cmd display-message -p -t "$origin_pane" '#{session_id}' 2>/dev/null) || {
  show_error "Error: no se pudo identificar la sesion actual"
  exit 1
}

panes=$(tmux_cmd list-panes -s -t "$session" -F '#{pane_id}|#{window_id}|#{@entorno_role}' 2>/dev/null) || {
  show_error "Error: no se pudieron consultar los paneles de la sesion"
  exit 1
}

agent_pane=
agent_window=
agent_count=0
editor_pane=
editor_window=
editor_count=0

while IFS='|' read -r pane_id window_id pane_role; do
  case "$pane_role" in
    agent)
      agent_pane=$pane_id
      agent_window=$window_id
      agent_count=$((agent_count + 1))
      ;;
    editor)
      editor_pane=$pane_id
      editor_window=$window_id
      editor_count=$((editor_count + 1))
      ;;
  esac
done <<EOF
$panes
EOF

if [ "$agent_count" -eq 0 ]; then
  show_error "No hay panel de agente IA en esta sesion"
  exit 1
fi
if [ "$agent_count" -ne 1 ]; then
  show_error "Error: hay mas de un panel con @entorno_role=agent"
  exit 1
fi
if [ "$editor_count" -ne 1 ]; then
  show_error "Error: no se pudo identificar un unico panel editor"
  exit 1
fi

if [ "$agent_window" = "$editor_window" ]; then
  # Ocultar el panel agente en una ventana auxiliar sin cerrar el proceso.
  tmux_cmd break-pane -d -s "$agent_pane" -n "ia"
  if [ "$origin_pane" = "$agent_pane" ]; then
    tmux_cmd select-pane -t "$editor_pane"
  fi
  printf '%s\n' "Panel IA ocultado"
else
  # Recuperar el panel agente a la derecha del editor sin robar el foco.
  tmux_cmd join-pane -d -h -l 30% -s "$agent_pane" -t "$editor_pane"
  printf '%s\n' "Panel IA mostrado"
fi
