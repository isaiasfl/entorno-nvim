#!/bin/sh
set -eu

TMUX_SOCKET=${ENTORNO_TMUX_SOCKET:-}
MAX_BYTES=${ENTORNO_AGENT_CONTEXT_MAX_BYTES:-32768}

tmux_cmd() {
  if [ -n "$TMUX_SOCKET" ]; then
    command tmux -L "$TMUX_SOCKET" "$@"
  else
    command tmux "$@"
  fi
}

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

[ "$#" -eq 1 ] || fail "uso: scripts/enviar-contexto-agente.sh archivo"
command -v tmux >/dev/null 2>&1 || fail "tmux no esta instalado"
case "$MAX_BYTES" in
  '' | *[!0-9]*) fail "ENTORNO_AGENT_CONTEXT_MAX_BYTES debe ser un entero positivo" ;;
  0) fail "ENTORNO_AGENT_CONTEXT_MAX_BYTES debe ser mayor que cero" ;;
esac
[ -n "${TMUX:-}" ] || fail "Neovim no esta dentro de una sesion tmux; el contexto se conserva en $1"
[ -n "${TMUX_PANE:-}" ] || fail "no se pudo identificar el panel tmux actual; el contexto se conserva en $1"

context_file=$1
[ -f "$context_file" ] && [ ! -L "$context_file" ] || fail "el contexto no es un archivo regular: $context_file"

mode=$(stat -c '%a' "$context_file" 2>/dev/null || stat -f '%Lp' "$context_file" 2>/dev/null || true)
[ "$mode" = "600" ] || fail "el contexto debe tener permisos 0600; se conserva en $context_file"

size=$(wc -c < "$context_file" | tr -d ' ')
[ "$size" -le "$MAX_BYTES" ] || fail "el contexto supera el limite de $MAX_BYTES bytes; se conserva en $context_file"
[ "$(wc -l < "$context_file" | tr -d ' ')" -eq 0 ] || fail "el contexto contiene saltos de linea reales; se conserva en $context_file"
size_without_cr=$(tr -d '\r' < "$context_file" | wc -c | tr -d ' ')
[ "$size_without_cr" = "$size" ] || fail "el contexto contiene retornos de carro; se conserva en $context_file"

session_id=$(tmux_cmd display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null || true)
[ -n "$session_id" ] || fail "no se pudo localizar la sesion tmux; el contexto se conserva en $context_file"

agent_panes=$(tmux_cmd list-panes -s -t "$session_id" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "agent" { print $1 }')
agent_count=$(printf '%s\n' "$agent_panes" | awk 'NF { count++ } END { print count + 0 }')
[ "$agent_count" -eq 1 ] || fail "se esperaba un panel con rol agent y se encontraron $agent_count; el contexto se conserva en $context_file"
agent_pane=$agent_panes

buffer_name="entorno-agent-context-$$"
tmux_cmd load-buffer -b "$buffer_name" "$context_file" || fail "no se pudo cargar el contexto; se conserva en $context_file"

if ! tmux_cmd paste-buffer -p -d -b "$buffer_name" -t "$agent_pane"; then
  tmux_cmd delete-buffer -b "$buffer_name" 2>/dev/null || true
  fail "no se pudo pegar el contexto; se conserva en $context_file"
fi

rm -f -- "$context_file"
printf '%s\n' "Contexto pegado en $agent_pane; revisalo y pulsa Enter para enviarlo."
