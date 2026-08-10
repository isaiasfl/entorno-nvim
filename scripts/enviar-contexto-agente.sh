#!/bin/sh
set -eu

TMUX_SOCKET=${ENTORNO_TMUX_SOCKET:-entorno-nvim}
MAX_BYTES=${ENTORNO_AGENT_CONTEXT_MAX_BYTES:-32768}
DEFAULT_ALLOWED_COMMANDS="codex opencode claude pi jarvis-coder"
KNOWN_SHELLS="bash sh dash zsh fish ksh tcsh nu"

tmux_cmd() {
  command tmux -L "$TMUX_SOCKET" "$@"
}

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

in_list() {
  sought=$1
  values=$2
  old_ifs=$IFS
  IFS=' ,:'
  set -f
  for value in $values; do
    if [ "$sought" = "$value" ]; then
      set +f
      IFS=$old_ifs
      return 0
    fi
  done
  set +f
  IFS=$old_ifs
  return 1
}

[ "$#" -eq 1 ] || fail "uso: scripts/enviar-contexto-agente.sh archivo"
command -v tmux >/dev/null 2>&1 || fail "tmux no esta instalado"
case "$MAX_BYTES" in
  '' | *[!0-9]*) fail "ENTORNO_AGENT_CONTEXT_MAX_BYTES debe ser un entero positivo" ;;
  0) fail "ENTORNO_AGENT_CONTEXT_MAX_BYTES debe ser mayor que cero" ;;
esac
[ -n "${TMUX:-}" ] || fail "Neovim no esta dentro de una sesion tmux; el contexto se conserva en $1"
[ -n "${TMUX_PANE:-}" ] || fail "no se pudo identificar el panel tmux actual; el contexto se conserva en $1"
[ -n "${ENTORNO_AGENT_CONTEXT_DIR:-}" ] || fail "falta ENTORNO_AGENT_CONTEXT_DIR; el contexto se conserva en $1"

context_file=$1
[ -f "$context_file" ] && [ ! -L "$context_file" ] || fail "el contexto no es un archivo regular: $context_file"
[ -d "$ENTORNO_AGENT_CONTEXT_DIR" ] && [ ! -L "$ENTORNO_AGENT_CONTEXT_DIR" ] ||
  fail "ENTORNO_AGENT_CONTEXT_DIR no es un directorio regular"
context_directory=$(CDPATH= cd "$(dirname "$context_file")" 2>/dev/null && pwd -P) ||
  fail "no se pudo resolver el directorio del contexto: $context_file"
allowed_directory=$(CDPATH= cd "$ENTORNO_AGENT_CONTEXT_DIR" 2>/dev/null && pwd -P) ||
  fail "no se pudo resolver ENTORNO_AGENT_CONTEXT_DIR"
[ "$context_directory" = "$allowed_directory" ] ||
  fail "el contexto esta fuera del directorio runtime permitido: $context_file"
directory_mode=$(
  stat -c '%a' "$allowed_directory" 2>/dev/null ||
    stat -f '%Lp' "$allowed_directory" 2>/dev/null || true
)
[ "$directory_mode" = "700" ] || fail "el directorio de contexto debe tener permisos 0700: $allowed_directory"
context_name=$(basename "$context_file")
case "$context_name" in
  context-*.json) ;;
  *) fail "nombre de contexto no valido: $context_name" ;;
esac
context_identifier=${context_name#context-}
context_identifier=${context_identifier%.json}
context_pid=${context_identifier%%-*}
context_nonce=${context_identifier#*-}
[ "$context_nonce" != "$context_identifier" ] || fail "nombre de contexto no valido: $context_name"
case "$context_pid" in
  '' | *[!0-9]*) fail "nombre de contexto no valido: $context_name" ;;
esac
case "$context_nonce" in
  '' | *[!0-9]*) fail "nombre de contexto no valido: $context_name" ;;
esac

mode=$(stat -c '%a' "$context_file" 2>/dev/null || stat -f '%Lp' "$context_file" 2>/dev/null || true)
[ "$mode" = "600" ] || fail "el contexto debe tener permisos 0600; se conserva en $context_file"

size=$(wc -c < "$context_file" | tr -d ' ')
[ "$size" -le "$MAX_BYTES" ] || fail "el contexto supera el limite de $MAX_BYTES bytes; se conserva en $context_file"
[ "$(wc -l < "$context_file" | tr -d ' ')" -eq 0 ] ||
  fail "el contexto contiene saltos de linea reales; se conserva en $context_file"
size_without_cr=$(tr -d '\r' < "$context_file" | wc -c | tr -d ' ')
[ "$size_without_cr" = "$size" ] || fail "el contexto contiene retornos de carro; se conserva en $context_file"

session_id=$(tmux_cmd display-message -p -t "$TMUX_PANE" '#{session_id}' 2>/dev/null || true)
[ -n "$session_id" ] || fail "no se pudo localizar la sesion tmux; el contexto se conserva en $context_file"

agent_panes=$(tmux_cmd list-panes -s -t "$session_id" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "agent" { print $1 }')
agent_count=$(printf '%s\n' "$agent_panes" | awk 'NF { count++ } END { print count + 0 }')
[ "$agent_count" -eq 1 ] ||
  fail "se esperaba un panel con rol agent y se encontraron $agent_count; el contexto se conserva en $context_file"
agent_pane=$agent_panes

pane_dead=$(tmux_cmd display-message -p -t "$agent_pane" '#{pane_dead}')
[ "$pane_dead" = "0" ] || fail "el panel agent no tiene un proceso activo; el contexto se conserva en $context_file"
detected=$(tmux_cmd display-message -p -t "$agent_pane" '#{pane_current_command}')
detected=${detected##*/}
case "$detected" in
  -*) detected=${detected#-} ;;
esac

if in_list "$detected" "$KNOWN_SHELLS"; then
  fail "destino rechazado: el panel agent ejecuta la shell $detected; no se pego ningun contexto"
fi

declared=$(tmux_cmd show-option -p -v -t "$agent_pane" @entorno_agent_command 2>/dev/null || true)
declared_process=$(tmux_cmd show-option -p -v -t "$agent_pane" @entorno_agent_process 2>/dev/null || true)
allowed_commands="$DEFAULT_ALLOWED_COMMANDS ${ENTORNO_AGENT_ALLOWED_COMMANDS:-}"
if in_list "$detected" "$allowed_commands"; then
  agent_identity=$detected
elif [ -n "$declared" ] \
  && [ "$declared_process" = "$detected" ] \
  && in_list "$declared" "$allowed_commands"; then
  agent_identity=$declared
else
  fail "proceso no autorizado en el panel agent: $detected;" \
    "anadelo a ENTORNO_AGENT_ALLOWED_COMMANDS o usa" \
    "scripts/agente.sh --name identidad --process proceso comando"
fi

buffer_name="entorno-agent-context-$$"
tmux_cmd load-buffer -b "$buffer_name" "$context_file" ||
  fail "no se pudo cargar el contexto; se conserva en $context_file"

if ! tmux_cmd paste-buffer -p -d -b "$buffer_name" -t "$agent_pane"; then
  tmux_cmd delete-buffer -b "$buffer_name" 2>/dev/null || true
  fail "no se pudo pegar el contexto; se conserva en $context_file"
fi

rm -f "$context_file"
printf '%s\n' "Contexto pegado en $agent_pane para $agent_identity; revisalo y pulsa Enter para enviarlo."
