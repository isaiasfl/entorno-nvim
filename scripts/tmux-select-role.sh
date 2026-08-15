#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
  printf '%s\n' "Uso: $0 ROL SESION PANEL_ORIGEN" >&2
  exit 2
fi

role=$1
session=$2
origin_pane=$3

show_error() {
  message=$1
  tmux display-message -t "$origin_pane" "$message" 2>/dev/null || :
  printf '%s\n' "$message" >&2
}

panes=$(tmux list-panes -s -t "$session" -F '#{pane_id} #{@entorno_role}') || {
  show_error "Error: no se pudieron consultar los paneles de la sesion"
  exit 1
}

matches=0
selected_pane=
while IFS=' ' read -r pane pane_role; do
  if [ "$pane_role" = "$role" ]; then
    matches=$((matches + 1))
    selected_pane=$pane
  fi
done <<EOF
$panes
EOF

case $matches in
  0)
    show_error "Error: no existe ningun panel con @entorno_role=$role"
    exit 1
    ;;
  1)
    tmux select-pane -t "$selected_pane"
    ;;
  *)
    show_error "Error: hay mas de un panel con @entorno_role=$role"
    exit 1
    ;;
esac
