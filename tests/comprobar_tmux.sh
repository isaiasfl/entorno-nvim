#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(dirname -- "$SCRIPT_DIR")
SOCKET="entorno-nvim-test-$$"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-tmux.XXXXXX")

tmux_test() {
  tmux -L "$SOCKET" "$@"
}

cleanup() {
  tmux_test kill-server 2>/dev/null || true
  rm -rf -- "$WORK_DIR"
}
trap cleanup EXIT HUP INT TERM

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

command -v tmux >/dev/null 2>&1 || fail "tmux no esta instalado"
command -v fzf >/dev/null 2>&1 || fail "fzf no esta disponible"

REPOSITORY="$WORK_DIR/proyecto principal"
WORKTREE="$WORK_DIR/proyecto-worktree"
mkdir -p "$REPOSITORY"
git -C "$REPOSITORY" init -q
git -C "$REPOSITORY" worktree add -q --orphan "$WORKTREE"

SESSION=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh" "$REPOSITORY")

tmux_test has-session -t "=$SESSION"
[ "$(tmux_test list-panes -t "=$SESSION" | wc -l)" -eq 3 ] || fail "el layout inicial no tiene tres paneles"

AGENT_PANE=$(tmux_test list-panes -s -t "=$SESSION" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "agent" { print $1 }')
[ -n "$AGENT_PANE" ] || fail "falta el panel con rol agent"
[ "$(printf '%s\n' "$AGENT_PANE" | wc -l)" -eq 1 ] || fail "hay mas de un panel con rol agent"

WINDOW_WIDTH=$(tmux_test display-message -p -t "=$SESSION:1" '#{window_width}')
BOTTOM_PANES=$(tmux_test list-panes -t "=$SESSION:1" -F '#{pane_top} #{pane_width}' |
  awk -v width="$WINDOW_WIDTH" '$1 > 0 && $2 == width { count++ } END { print count + 0 }')
[ "$BOTTOM_PANES" -eq 1 ] || fail "el panel inferior no ocupa todo el ancho"

for binding in h j k l H J K L; do
  tmux_test list-keys -T prefix "$binding" >/dev/null 2>&1 || fail "falta el binding tmux $binding"
done
[ "$(tmux_test show-options -gv mouse)" = "off" ] || fail "mouse debe estar desactivado"
[ "$(tmux_test show-options -gv base-index)" = "1" ] || fail "base-index debe ser 1"
[ "$(tmux_test show-window-options -gv pane-base-index)" = "1" ] || fail "pane-base-index debe ser 1"
[ "$(tmux_test show-window-options -gv mode-keys)" = "vi" ] || fail "copy mode debe usar teclas Vi"
[ "$(tmux_test show-options -gv focus-events)" = "on" ] || fail "focus-events debe estar activo"

CONTEXT="$WORK_DIR/context-normal.json"
SENTINEL="$WORK_DIR/no-debe-ejecutarse"
printf '%s' "NORMAL_CONTEXT_\$(touch '$SENTINEL')" > "$CONTEXT"
chmod 600 "$CONTEXT"
EDITOR_PANE=$(tmux_test list-panes -t "=$SESSION:1" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 != "agent" { print $1; exit }')

TMUX=test TMUX_PANE="$EDITOR_PANE" ENTORNO_TMUX_SOCKET="$SOCKET" \
  "$PROJECT_ROOT/scripts/enviar-contexto-agente.sh" "$CONTEXT" >/dev/null
[ ! -e "$CONTEXT" ] || fail "el contexto temporal no se elimino"
[ ! -e "$SENTINEL" ] || fail "el transporte ejecuto el contenido sin confirmacion"
tmux_test capture-pane -p -J -t "$AGENT_PANE" | grep -q 'NORMAL_CONTEXT_' || fail "el contexto no llego al panel agent"
if tmux_test list-buffers -F '#{buffer_name}' 2>/dev/null | grep -q '^entorno-agent-context-'; then
  fail "quedo un buffer auxiliar de tmux"
fi
tmux_test send-keys -t "$AGENT_PANE" C-c

OUTSIDE_TMUX="$WORK_DIR/context-outside-tmux.json"
printf '%s' 'OUTSIDE_TMUX_CONTEXT' > "$OUTSIDE_TMUX"
chmod 600 "$OUTSIDE_TMUX"
if TMUX= TMUX_PANE="$EDITOR_PANE" ENTORNO_TMUX_SOCKET="$SOCKET" \
  "$PROJECT_ROOT/scripts/enviar-contexto-agente.sh" "$OUTSIDE_TMUX" 2>/dev/null; then
  fail "el transporte acepto un contexto fuera de tmux"
fi
[ -e "$OUTSIDE_TMUX" ] || fail "se perdio el contexto al ejecutarse fuera de tmux"

tmux_test set-option -p -u -t "$AGENT_PANE" @entorno_role
PRESERVED="$WORK_DIR/context-preserved.json"
printf '%s' 'PRESERVED_CONTEXT' > "$PRESERVED"
chmod 600 "$PRESERVED"
if TMUX=test TMUX_PANE="$EDITOR_PANE" ENTORNO_TMUX_SOCKET="$SOCKET" \
  "$PROJECT_ROOT/scripts/enviar-contexto-agente.sh" "$PRESERVED" 2>/dev/null; then
  fail "el transporte acepto una sesion sin panel agent"
fi
[ -e "$PRESERVED" ] || fail "se perdio el contexto al faltar el panel agent"
tmux_test set-option -p -t "$AGENT_PANE" @entorno_role agent

tmux_test split-window -t "=$SESSION:1" -c "$REPOSITORY" >/dev/null
PANES_BEFORE=$(tmux_test list-panes -t "=$SESSION:1" | wc -l)
RECONNECTED=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh" "$REPOSITORY")
PANES_AFTER=$(tmux_test list-panes -t "=$SESSION:1" | wc -l)
[ "$RECONNECTED" = "$SESSION" ] || fail "no se reutilizo la sesion existente"
[ "$PANES_AFTER" -eq "$PANES_BEFORE" ] || fail "se reconstruyo el layout de una sesion existente"

WORKTREE_SESSION=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  ENTORNO_TMUX_PROJECT_ROOTS="$WORK_DIR" \
  FZF_DEFAULT_OPTS="--filter=worktree" \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh")
tmux_test has-session -t "=$WORKTREE_SESSION"
WORKTREE_CWD=$(tmux_test display-message -p -t "=$WORKTREE_SESSION:1.1" '#{pane_current_path}')
[ "$WORKTREE_CWD" = "$WORKTREE" ] || fail "el selector no reconocio el worktree"

printf '%s\n' "Comprobacion tmux correcta."
