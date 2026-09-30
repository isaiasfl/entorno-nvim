#!/bin/sh
# Cierra una sesion del entorno pidiendo antes a Neovim que salga de forma
# ordenada. Sin esto, kill-session lo mata y deja archivos swap huerfanos.
# Si hay cambios sin guardar, Neovim pregunta en su panel y la sesion sigue.
set -eu

[ "$#" -eq 1 ] || { printf '%s\n' 'Uso: tmux-cerrar-proyecto.sh SESION' >&2; exit 2; }
session=$1

t() {
  if [ -n "${ENTORNO_TMUX_SOCKET:-}" ] && [ -z "${TMUX:-}" ]; then
    command tmux -L "$ENTORNO_TMUX_SOCKET" "$@"
  else
    command tmux "$@"
  fi
}

aviso() {
  if [ -n "${TMUX:-}" ]; then
    t display-message -d 6000 "$1"
  else
    printf '%s\n' "$1" >&2
  fi
}

paneles_nvim() {
  t list-panes -s -t "=$session" -F '#{pane_id} #{pane_current_command}' 2>/dev/null |
    awk '$2 == "nvim" { print $1 }'
}

for pane in $(paneles_nvim); do
  t send-keys -t "$pane" Escape
  t send-keys -t "$pane" -l ':confirm qa'
  t send-keys -t "$pane" Enter
done

intentos=0
while [ -n "$(paneles_nvim)" ] && [ "$intentos" -lt 20 ]; do
  sleep 0.2
  intentos=$((intentos + 1))
done

if [ -n "$(paneles_nvim)" ]; then
  aviso "Neovim tiene cambios sin guardar: el editor pregunta «Save changes?»: y guarda, n descarta. Luego repite Ctrl-a Q"
  exit 1
fi
t kill-session -t "=$session"
