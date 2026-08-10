#!/bin/sh
set -eu

TMUX_SOCKET=${ENTORNO_TMUX_SOCKET:-entorno-nvim}

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

tmux_cmd() {
  command tmux -L "$TMUX_SOCKET" "$@"
}

[ -n "${TMUX:-}" ] || fail "este lanzador debe ejecutarse dentro de tmux"
[ -n "${TMUX_PANE:-}" ] || fail "no se pudo identificar el panel tmux actual"
[ "$#" -gt 0 ] || fail "uso: scripts/agente.sh [--name identidad] [--process proceso] comando [argumentos]"

identity=
expected_process=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --name)
      [ "$#" -ge 3 ] || fail "--name requiere una identidad y un comando"
      identity=$2
      shift 2
      ;;
    --process)
      [ "$#" -ge 3 ] || fail "--process requiere un nombre y un comando"
      expected_process=$2
      shift 2
      ;;
    *) break ;;
  esac
done
[ "$#" -gt 0 ] || fail "falta el comando del agente"
[ -n "$identity" ] || identity=${1##*/}
[ -n "$expected_process" ] || expected_process=${1##*/}

for value in "$identity" "$expected_process"; do
  case "$value" in
    '' | *[!A-Za-z0-9._-]*) fail "identidad o proceso de agente no valido: $value" ;;
  esac
done

command -v "$1" >/dev/null 2>&1 || fail "comando de agente no disponible: $1"
role=$(tmux_cmd show-option -p -v -t "$TMUX_PANE" @entorno_role 2>/dev/null || true)
[ "$role" = "agent" ] || fail "el panel actual no tiene @entorno_role=agent"

tmux_cmd set-option -p -t "$TMUX_PANE" @entorno_agent_command "$identity"
tmux_cmd set-option -p -t "$TMUX_PANE" @entorno_agent_process "$expected_process"

launcher_pid=$$
(
  trap '' HUP INT TERM
  while kill -0 "$launcher_pid" 2>/dev/null; do
    sleep 1
  done
  tmux_cmd set-option -p -u -t "$TMUX_PANE" @entorno_agent_command 2>/dev/null || true
  tmux_cmd set-option -p -u -t "$TMUX_PANE" @entorno_agent_process 2>/dev/null || true
) </dev/null >/dev/null 2>&1 &

exec "$@"
