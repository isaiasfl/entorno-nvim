#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
AGENT_LAUNCHER="$SCRIPT_DIR/agente.sh"
TMUX_SOCKET=${ENTORNO_TMUX_SOCKET:-entorno-nvim}

tmux_cmd() {
  command tmux -L "$TMUX_SOCKET" "$@"
}

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

clear_agent_state() {
  tmux_cmd set-option -p -u -t "$TMUX_PANE" @entorno_agent 2>/dev/null || true
}

clear_selector_state() {
  tmux_cmd set-option -p -u -t "$TMUX_PANE" @entorno_selector_state 2>/dev/null || true
}

cleanup() {
  clear_selector_state
  [ "${handoff:-0}" = 1 ] || clear_agent_state
}

shell_quote() {
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

queue_in_pane() {
  handoff_buffer="entorno-agent-selector-$$"
  tmux_cmd set-buffer -b "$handoff_buffer" "$1"
  tmux_path=$(command -v tmux)
  delayed_enter="sleep 0.1; $(shell_quote "$tmux_path") -L $(shell_quote "$TMUX_SOCKET")"
  delayed_enter="$delayed_enter paste-buffer -d -b $(shell_quote "$handoff_buffer") -t $(shell_quote "$TMUX_PANE");"
  delayed_enter="$delayed_enter $(shell_quote "$tmux_path") -L $(shell_quote "$TMUX_SOCKET")"
  delayed_enter="$delayed_enter send-keys -t $(shell_quote "$TMUX_PANE") Enter"
  tmux_cmd run-shell -b "$delayed_enter"
  handoff=1
  exit 0
}

selector_return_command() {
  return_command="PATH=$(shell_quote "$PATH") ENTORNO_TMUX_SOCKET=$(shell_quote "$TMUX_SOCKET")"
  return_command="$return_command ENTORNO_AGENT_SELECTOR_USE_FZF=$(shell_quote "${ENTORNO_AGENT_SELECTOR_USE_FZF:-1}")"
  return_command="$return_command SHELL=$(shell_quote "${SHELL:-/bin/sh}")"
  for assignment in \
    "ENTORNO_AGENT_CODEX_PROCESS=${ENTORNO_AGENT_CODEX_PROCESS:-}" \
    "ENTORNO_AGENT_OPENCODE_PROCESS=${ENTORNO_AGENT_OPENCODE_PROCESS:-}" \
    "ENTORNO_AGENT_CLAUDE_PROCESS=${ENTORNO_AGENT_CLAUDE_PROCESS:-}" \
    "ENTORNO_AGENT_PI_PROCESS=${ENTORNO_AGENT_PI_PROCESS:-}"
  do
    name=${assignment%%=*}
    value=${assignment#*=}
    [ -n "$value" ] && return_command="$return_command $name=$(shell_quote "$value")"
  done
  printf '%s %s\n' "$return_command" "$(shell_quote "$SCRIPT_DIR/selector-agente.sh")"
}

set_agent_state() {
  tmux_cmd set-option -p -t "$TMUX_PANE" @entorno_agent "$1"
}

agent_process() {
  agent_id=$1
  executable=$2
  case "$agent_id" in
    codex) override=${ENTORNO_AGENT_CODEX_PROCESS:-} ;;
    opencode) override=${ENTORNO_AGENT_OPENCODE_PROCESS:-} ;;
    claude) override=${ENTORNO_AGENT_CLAUDE_PROCESS:-} ;;
    pi) override=${ENTORNO_AGENT_PI_PROCESS:-} ;;
    *) override= ;;
  esac
  if [ -n "$override" ]; then
    printf '%s\n' "$override"
    return
  fi

  executable_path=$(command -v "$executable")
  magic=$(LC_ALL=C dd if="$executable_path" bs=2 count=1 2>/dev/null || true)
  if [ "$magic" = '#!' ]; then
    shebang=$(LC_ALL=C sed -n '1p' "$executable_path")
    case "$shebang" in
      *node*) printf '%s\n' node; return ;;
    esac
  fi
  basename "$executable_path"
}

available_choices() {
  for entry in \
    'Codex:codex' \
    'OpenCode:opencode' \
    'Claude:claude' \
    'Pi:pi'
  do
    label=${entry%%:*}
    agent_id=${entry#*:}
    if command -v "$agent_id" >/dev/null 2>&1; then
      marker='[OK]'
    else
      marker='[--]'
    fi
    printf '%-11s %s\t%s\n' "$label" "$marker" "$agent_id"
  done
  printf '%-11s [OK]\tshell\n' Shell
  if [ "${ENTORNO_AGENT_SELECTOR_POPUP:-0}" != 1 ]; then
    printf '%-11s [OK]\texit\n' Salir
  fi
}

select_with_fzf() {
  if fzf --help 2>/dev/null | grep -q -- '--footer='; then
    selected=$(available_choices | fzf --no-sort --delimiter='\t' --with-nth=1 \
      --layout=reverse --header='Entorno IA' --header-first \
      --footer='Enter elegir  Esc salir' --footer-border=none \
      --info=hidden --no-separator --no-scrollbar --gutter=' ' \
      --pointer='>' --prompt='') || return 1
  else
    selected=$(available_choices | fzf --no-sort --delimiter='\t' --with-nth=1 \
      --header='Entorno IA' --pointer='>' --prompt='Elegir> ') || return 1
  fi
  printf '%s\n' "${selected#*	}"
}

select_with_text_menu() {
  printf '%s\n\n' "Entorno IA" >&2
  if [ "${ENTORNO_AGENT_SELECTOR_POPUP:-0}" = 1 ]; then
    available_choices | awk -F '\t' '{ printf "  %s\n", $1 }' >&2
    printf '\n%s\n' "Escribe nombre  |  vacio cierra" >&2
  else
    available_choices | awk -F '\t' '
      $2 == "exit" { number = 0 }
      $2 != "exit" { number++ }
      { printf "  %s) %s\n", number, $1 }
    ' >&2
    printf '\n%s\n%s\n' "Enter: elegir" "0: cerrar" >&2
  fi
  printf '%s' "> " >&2
  IFS= read -r selected || return 1
  case "$selected" in
    1 | codex | Codex) choice=codex ;;
    2 | opencode | OpenCode) choice=opencode ;;
    3 | claude | Claude) choice=claude ;;
    4 | pi | Pi) choice=pi ;;
    5 | shell | Shell) choice=shell ;;
    0 | exit | salir | Salir | '') choice=exit ;;
    *) printf '%s\n' "Opcion no valida: $selected" >&2; return 2 ;;
  esac
  printf '%s\n' "$choice"
}

ensure_available() {
  agent_id=$1
  label=$2
  if ! command -v "$agent_id" >/dev/null 2>&1; then
    printf '%s\n' "Agente no disponible: $label (ejecutable: $agent_id)" >&2
    return 1
  fi
}

choose_only() {
  while :; do
    if [ "${ENTORNO_AGENT_SELECTOR_USE_FZF:-1}" != 0 ] \
      && command -v fzf >/dev/null 2>&1 && [ -t 0 ] && [ -t 2 ]; then
      select_with_fzf
      return
    fi
    choice=$(select_with_text_menu) || {
      status=$?
      [ "$status" -eq 2 ] && continue
      return 1
    }
    printf '%s\n' "$choice"
    return
  done
}

run_agent() {
  agent_id=$1
  agent_executable=$(command -v "$agent_id")
  process=$(agent_process "$agent_id" "$agent_executable")
  set_agent_state "$agent_id"
  command_line="$(shell_quote "$AGENT_LAUNCHER") --name $(shell_quote "$agent_id")"
  command_line="$command_line --process $(shell_quote "$process") $(shell_quote "$agent_executable")"
  command_line="$command_line; $(selector_return_command)"
  queue_in_pane "$command_line"
}

run_shell() {
  shell_command=${SHELL:-/bin/sh}
  [ -x "$shell_command" ] || fail "la shell no es ejecutable: $shell_command"
  set_agent_state shell
  command_line="$(shell_quote "$shell_command"); $(selector_return_command)"
  queue_in_pane "$command_line"
}

if [ "$#" -eq 1 ] && [ "$1" = --choose-only ]; then
  choose_only
  exit $?
fi
[ "$#" -eq 0 ] || fail "uso: scripts/selector-agente.sh [--choose-only]"

[ -n "${TMUX:-}" ] || fail "el selector debe ejecutarse dentro de tmux"
[ -n "${TMUX_PANE:-}" ] || fail "no se pudo identificar el panel tmux actual"
[ -x "$AGENT_LAUNCHER" ] || fail "no se encuentra scripts/agente.sh"
role=$(tmux_cmd show-option -p -v -t "$TMUX_PANE" @entorno_role 2>/dev/null || true)
[ "$role" = agent ] || fail "el panel actual no tiene @entorno_role=agent"

handoff=0
trap 'cleanup' 0 HUP TERM
trap ':' INT
clear_agent_state
tmux_cmd set-option -p -t "$TMUX_PANE" @entorno_selector_state ready

while :; do
  if [ "${ENTORNO_AGENT_SELECTOR_USE_FZF:-1}" != 0 ] \
    && command -v fzf >/dev/null 2>&1 && [ -t 0 ] && [ -t 1 ]; then
    choice=$(select_with_fzf) || exit 0
  else
    choice=$(select_with_text_menu) || {
      status=$?
      [ "$status" -eq 2 ] && continue
      exit 0
    }
  fi

  case "$choice" in
    codex) if ensure_available codex Codex; then run_agent codex; fi ;;
    opencode) if ensure_available opencode OpenCode; then run_agent opencode; fi ;;
    claude) if ensure_available claude Claude; then run_agent claude; fi ;;
    pi) if ensure_available pi Pi; then run_agent pi; fi ;;
    shell) run_shell ;;
    exit) exit 0 ;;
    *) printf '%s\n' "Opcion desconocida: $choice" >&2 ;;
  esac
done
