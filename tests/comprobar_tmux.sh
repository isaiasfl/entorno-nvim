#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
SOCKET="entorno-nvim-test-$$"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-tmux.XXXXXX")
CONTEXT_DIR="$WORK_DIR/runtime/agent-context"

tmux_test() {
  tmux -L "$SOCKET" "$@"
}

cleanup() {
  tmux_test kill-server 2>/dev/null || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT HUP INT TERM

fail() {
  printf '%s\n' "Error: $*" >&2
  exit 1
}

wait_for_process() {
  expected=$1
  pane=$2
  attempts=0
  while [ "$attempts" -lt 5 ]; do
    actual=$(tmux_test display-message -p -t "$pane" '#{pane_current_command}')
    [ "$actual" = "$expected" ] && return 0
    attempts=$((attempts + 1))
    sleep 1
  done
  pane_output=$(tmux_test capture-pane -p -t "$pane" | tail -n 20 | tr '\n' ' ')
  fail "el panel $pane no ejecuto $expected; proceso actual: $actual; salida: $pane_output"
}

make_context() {
  suffix=$1
  payload=$2
  CONTEXT="$CONTEXT_DIR/context-$$-$suffix.json"
  printf '%s' "$payload" > "$CONTEXT"
  chmod 600 "$CONTEXT"
}

transport() {
  TMUX=test \
  TMUX_PANE="$EDITOR_PANE" \
  ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_AGENT_CONTEXT_DIR="$CONTEXT_DIR" \
  ENTORNO_AGENT_CONTEXT_MAX_BYTES="${CONTEXT_LIMIT:-32768}" \
  ENTORNO_AGENT_ALLOWED_COMMANDS="${EXTRA_ALLOWED:-}" \
    "$PROJECT_ROOT/scripts/enviar-contexto-agente.sh" "$1"
}

command -v tmux >/dev/null 2>&1 || fail "tmux no esta instalado"
command -v fzf >/dev/null 2>&1 || fail "fzf no esta disponible"

REPOSITORY="$WORK_DIR/proyecto principal"
WORKTREE="$WORK_DIR/proyecto-worktree"
mkdir -p "$REPOSITORY" "$CONTEXT_DIR"
chmod 700 "$CONTEXT_DIR"
git -C "$REPOSITORY" init -q
git -C "$REPOSITORY" -c user.name=Prueba -c user.email=prueba@example.invalid \
  commit --allow-empty -q -m inicial
git -C "$REPOSITORY" worktree add -q -b prueba-worktree "$WORKTREE"

SESSION=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  ENTORNO_TMUX_PROJECT_ROOTS="$WORK_DIR" \
  ENTORNO_TMUX_PROJECT_DEPTH=5 \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh" "$REPOSITORY")

tmux_test has-session -t "=$SESSION"
[ "$(tmux_test list-panes -t "=$SESSION" | wc -l)" -eq 3 ] || fail "el layout inicial no tiene tres paneles"
session_prefix=${SESSION%-*}
[ "$session_prefix" = "proyecto_principal" ] || fail "nombre de sesion inesperado o con sufijo espurio: $SESSION"

AGENT_PANE=$(tmux_test list-panes -s -t "=$SESSION" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "agent" { print $1 }')
EDITOR_PANE=$(tmux_test list-panes -s -t "=$SESSION" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "editor" { print $1 }')
[ -n "$AGENT_PANE" ] || fail "falta el panel con rol agent"
[ -n "$EDITOR_PANE" ] || fail "falta el panel con rol editor"
[ "$(printf '%s\n' "$AGENT_PANE" | wc -l)" -eq 1 ] || fail "hay mas de un panel con rol agent"
[ "$(tmux_test show-environment -t "=$SESSION" ENTORNO_TMUX_SOCKET)" = "ENTORNO_TMUX_SOCKET=$SOCKET" ] ||
  fail "la sesion no conserva el socket dedicado"
[ "$(tmux_test show-environment -t "=$SESSION" ENTORNO_NVIM_ROOT)" = "ENTORNO_NVIM_ROOT=$PROJECT_ROOT" ] ||
  fail "la sesion no conserva la raiz de entorno-nvim"
[ "$(tmux_test show-environment -t "=$SESSION" ENTORNO_TMUX_PROJECT_ROOTS)" = "ENTORNO_TMUX_PROJECT_ROOTS=$WORK_DIR" ] ||
  fail "la sesion no conserva las raices del selector"
[ "$(tmux_test show-environment -t "=$SESSION" ENTORNO_TMUX_PROJECT_DEPTH)" = "ENTORNO_TMUX_PROJECT_DEPTH=5" ] ||
  fail "la sesion no conserva la profundidad del selector"
[ "$(tmux_test show-environment -t "=$SESSION" NVIM_BIN)" = "NVIM_BIN=$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" ] ||
  fail "la sesion no conserva el ejecutable de Neovim para crear otros proyectos"

# El editor de prueba termina inmediatamente; el panel debe volver a su shell.
EDITOR_SHELL=$(tmux_test display-message -p -t "$EDITOR_PANE" '#{pane_current_command}')
case "$EDITOR_SHELL" in
  sh | bash | dash | zsh | fish | ksh | tcsh | nu) ;;
  *) fail "el panel editor no volvio a una shell: $EDITOR_SHELL" ;;
esac
[ "$(tmux_test list-panes -t "=$SESSION" | wc -l)" -eq 3 ] || fail "salir de Neovim destruyo su panel"
EDITOR_ENV_FILE="$WORK_DIR/editor-env"
quoted_env_file=$(printf '%s' "$EDITOR_ENV_FILE" | sed "s/'/'\\''/g")
tmux_test send-keys -l -t "$EDITOR_PANE" \
  "printf '%s|%s' \"\$ENTORNO_TMUX_SOCKET\" \"\$ENTORNO_NVIM_ROOT\" > '$quoted_env_file'"
tmux_test send-keys -t "$EDITOR_PANE" Enter
attempts=0
while [ ! -f "$EDITOR_ENV_FILE" ] && [ "$attempts" -lt 20 ]; do
  attempts=$((attempts + 1))
  sleep 1
done
[ "$(cat "$EDITOR_ENV_FILE")" = "$SOCKET|$PROJECT_ROOT" ] ||
  fail "la shell del editor no conservo el entorno del socket dedicado"

WINDOW_WIDTH=$(tmux_test display-message -p -t "=$SESSION:1" '#{window_width}')
BOTTOM_PANES=$(tmux_test list-panes -t "=$SESSION:1" -F '#{pane_top} #{pane_width}' |
  awk -v width="$WINDOW_WIDTH" '$1 > 0 && $2 == width { count++ } END { print count + 0 }')
[ "$BOTTOM_PANES" -eq 1 ] || fail "el panel inferior no ocupa todo el ancho"

for binding in h j k l H J K L C-b P; do
  tmux_test list-keys -T prefix "$binding" >/dev/null 2>&1 || fail "falta el binding tmux $binding"
done
POPUP_BINDING=$(tmux_test list-keys -T prefix P)
printf '%s\n' "$POPUP_BINDING" | grep -q 'display-popup' || fail "Ctrl-b P no abre un popup"
printf '%s\n' "$POPUP_BINDING" | grep -q 'proyecto\.sh' || fail "el popup no reutiliza proyecto.sh"
printf '%s\n' "$POPUP_BINDING" | grep -q '#{pane_current_path}' || fail "el popup no conserva el cwd del panel"
printf '%s\n' "$POPUP_BINDING" | grep -q '85%' || fail "el popup no tiene anchura suficiente"
printf '%s\n' "$POPUP_BINDING" | grep -q '75%' || fail "el popup no tiene altura suficiente"
printf '%s\n' "$POPUP_BINDING" | grep -q -- '-b simple' || fail "el popup no usa un borde ASCII portable"
if printf '%s\n' "$POPUP_BINDING" | grep -Eq 'sesh|gum|fzf-tmux'; then
  fail "el popup introdujo un sessionizer o selector adicional"
fi
[ "$(tmux_test show-options -gv mouse)" = "off" ] || fail "mouse debe estar desactivado"
[ "$(tmux_test show-options -gv base-index)" = "1" ] || fail "base-index debe ser 1"
[ "$(tmux_test show-window-options -gv pane-base-index)" = "1" ] || fail "pane-base-index debe ser 1"
[ "$(tmux_test show-window-options -gv mode-keys)" = "vi" ] || fail "copy mode debe usar teclas Vi"
[ "$(tmux_test show-options -gv focus-events)" = "on" ] || fail "focus-events debe estar activo"

# Una shell, incluso dentro del panel marcado, nunca es un destino valido.
AGENT_SHELL=$(tmux_test display-message -p -t "$AGENT_PANE" '#{pane_current_command}')
shell_index=10
for shell in bash sh dash zsh fish; do
  command -v "$shell" >/dev/null 2>&1 || continue
  if [ "$shell" != "$AGENT_SHELL" ]; then
    tmux_test send-keys -l -t "$AGENT_PANE" "$shell"
    tmux_test send-keys -t "$AGENT_PANE" Enter
    wait_for_process "$shell" "$AGENT_PANE"
  fi
  make_context "$shell_index" "SHELL_$shell"
  if transport "$CONTEXT" >/dev/null 2>&1; then
    fail "el transporte acepto la shell $shell"
  fi
  [ -e "$CONTEXT" ] || fail "se perdio el contexto rechazado para $shell"
  if tmux_test capture-pane -p -J -t "$AGENT_PANE" | grep -q "SHELL_$shell"; then
    fail "el contexto se pego en la shell $shell"
  fi
  rm -f "$CONTEXT"
  shell_index=$((shell_index + 1))
  if [ "$shell" != "$AGENT_SHELL" ]; then
    tmux_test send-keys -l -t "$AGENT_PANE" exit
    tmux_test send-keys -t "$AGENT_PANE" Enter
    wait_for_process "$AGENT_SHELL" "$AGENT_PANE"
  fi
done

# El lanzador declara una identidad fiable aunque el proceso real sea un wrapper.
sleep 1
launcher=$(printf '%s' "$PROJECT_ROOT/scripts/agente.sh" | sed "s/'/'\\''/g")
RECEIVED="$WORK_DIR/agente-recibido"
tmux_test send-keys -l -t "$AGENT_PANE" \
  "ENTORNO_TMUX_SOCKET='$SOCKET' '$launcher' --name codex --process tee tee '$RECEIVED'"
tmux_test send-keys -t "$AGENT_PANE" Enter
wait_for_process tee "$AGENT_PANE"
[ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent_command)" = "codex" ] ||
  fail "el lanzador no declaro la identidad codex"
[ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent_process)" = "tee" ] ||
  fail "el lanzador no declaro el proceso tee"

SENTINEL_SUBSHELL="$WORK_DIR/no-ejecutar-subshell"
SENTINEL_BACKTICK="$WORK_DIR/no-ejecutar-backtick"
payload="UNICODE_á🚀 \$(touch '$SENTINEL_SUBSHELL') \`touch '$SENTINEL_BACKTICK'\` \"comillas\" linea1\\nlinea2"
make_context 20 "$payload"
CONTEXT_MODE=$(stat -c '%a' "$CONTEXT" 2>/dev/null || stat -f '%Lp' "$CONTEXT")
[ "$CONTEXT_MODE" = "600" ] || fail "el contexto no tiene modo 0600"
transport "$CONTEXT" >/dev/null
[ ! -e "$CONTEXT" ] || fail "el contexto temporal no se elimino"
[ ! -e "$SENTINEL_SUBSHELL" ] || fail "se ejecuto una sustitucion de comando"
[ ! -e "$SENTINEL_BACKTICK" ] || fail "se ejecutaron backticks"
tmux_test capture-pane -p -J -t "$AGENT_PANE" | grep -q 'UNICODE_á' || fail "el payload Unicode no llego intacto"
[ ! -s "$RECEIVED" ] || fail "el transporte envio Enter automaticamente"
if tmux_test list-buffers -F '#{buffer_name}' 2>/dev/null | grep -q '^entorno-agent-context-'; then
  fail "quedo un buffer auxiliar de tmux"
fi
tmux_test send-keys -t "$AGENT_PANE" C-c
wait_for_process "$AGENT_SHELL" "$AGENT_PANE"
sleep 2
[ -z "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent_command 2>/dev/null || true)" ] ||
  fail "el lanzador no limpio la identidad al terminar"

# Un proceso desconocido se rechaza por defecto.
tmux_test send-keys -l -t "$AGENT_PANE" cat
tmux_test send-keys -t "$AGENT_PANE" Enter
wait_for_process cat "$AGENT_PANE"
make_context 21 UNKNOWN_PROCESS
if transport "$CONTEXT" >/dev/null 2>&1; then
  fail "se acepto un proceso desconocido"
fi
[ -e "$CONTEXT" ] || fail "no se conservo el contexto del proceso desconocido"
rm -f "$CONTEXT"

# La allowlist adicional permite ampliar agentes sin modificar codigo.
EXTRA_ALLOWED=cat
make_context 22 ADDITIONAL_AGENT
transport "$CONTEXT" >/dev/null
[ ! -e "$CONTEXT" ] || fail "la allowlist adicional no autorizo el proceso"
EXTRA_ALLOWED=
tmux_test send-keys -t "$AGENT_PANE" C-c
wait_for_process "$AGENT_SHELL" "$AGENT_PANE"

# Dos paneles marcados son ambiguos y deben conservar el contexto.
SECOND_AGENT=$(tmux_test split-window -t "=$SESSION:1" -c "$REPOSITORY" -P -F '#{pane_id}')
tmux_test set-option -p -t "$SECOND_AGENT" @entorno_role agent
make_context 23 TWO_AGENTS
if transport "$CONTEXT" >/dev/null 2>&1; then
  fail "se aceptaron dos paneles agent"
fi
[ -e "$CONTEXT" ] || fail "se perdio el contexto con dos paneles agent"
rm -f "$CONTEXT"
tmux_test kill-pane -t "$SECOND_AGENT"

# Permisos, tamano, override y symlinks se validan antes de pegar.
make_context 24 BAD_MODE
chmod 644 "$CONTEXT"
if transport "$CONTEXT" >/dev/null 2>&1; then
  fail "se acepto un contexto sin permisos 0600"
fi
rm -f "$CONTEXT"

make_context 25 "$(awk 'BEGIN { for (i = 0; i < 33000; i++) printf "x" }')"
if transport "$CONTEXT" >/dev/null 2>&1; then
  fail "se acepto un contexto mayor que el limite"
fi
[ -e "$CONTEXT" ] || fail "no se conservo el contexto demasiado grande"
rm -f "$CONTEXT"

CONTEXT_LIMIT=8
make_context 26 NINE_BYTES
if transport "$CONTEXT" >/dev/null 2>&1; then
  fail "el transporte ignoro ENTORNO_AGENT_CONTEXT_MAX_BYTES"
fi
[ -e "$CONTEXT" ] || fail "no se conservo el contexto rechazado por override"
rm -f "$CONTEXT"
CONTEXT_LIMIT=32768

TARGET="$CONTEXT_DIR/context-$$-27.json"
LINK="$CONTEXT_DIR/context-$$-28.json"
printf '%s' SYMLINK_TARGET > "$TARGET"
chmod 600 "$TARGET"
ln -s "$TARGET" "$LINK"
if transport "$LINK" >/dev/null 2>&1; then
  fail "se acepto un symlink como contexto"
fi
[ -L "$LINK" ] && [ -e "$TARGET" ] || fail "la prueba de symlink altero sus archivos"

OUTSIDE_TMUX="$CONTEXT_DIR/context-$$-29.json"
printf '%s' OUTSIDE_TMUX_CONTEXT > "$OUTSIDE_TMUX"
chmod 600 "$OUTSIDE_TMUX"
if TMUX= TMUX_PANE="$EDITOR_PANE" ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_AGENT_CONTEXT_DIR="$CONTEXT_DIR" \
  "$PROJECT_ROOT/scripts/enviar-contexto-agente.sh" "$OUTSIDE_TMUX" 2>/dev/null; then
  fail "el transporte acepto un contexto fuera de tmux"
fi
[ -e "$OUTSIDE_TMUX" ] || fail "se perdio el contexto fuera de tmux"

# Reconectar no reconstruye ni altera el layout existente.
tmux_test split-window -t "=$SESSION:1" -c "$REPOSITORY" >/dev/null
PANES_BEFORE=$(tmux_test list-panes -t "=$SESSION:1" | wc -l)
RECONNECTED=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh" "$REPOSITORY")
PANES_AFTER=$(tmux_test list-panes -t "=$SESSION:1" | wc -l)
[ "$RECONNECTED" = "$SESSION" ] || fail "no se reutilizo la sesion existente"
[ "$PANES_AFTER" -eq "$PANES_BEFORE" ] || fail "se reconstruyo el layout de una sesion existente"

# El mismo selector que usa el popup debe reconectar proyectos con espacios.
SELECTED_EXISTING=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  ENTORNO_TMUX_PROJECT_ROOTS="$WORK_DIR" \
  FZF_DEFAULT_OPTS='--filter=principal' \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh")
[ "$SELECTED_EXISTING" = "$SESSION" ] || fail "el selector no reconecto la sesion del proyecto con espacios"
[ "$(tmux_test list-panes -t "=$SESSION:1" | wc -l)" -eq "$PANES_BEFORE" ] ||
  fail "el selector reconstruyo una sesion existente"

# Fzf cancelado termina con exito y no crea sesiones parciales.
SESSIONS_BEFORE=$(tmux_test list-sessions -F '#{session_name}' | wc -l)
CANCELLED=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  ENTORNO_TMUX_PROJECT_ROOTS="$WORK_DIR" \
  FZF_DEFAULT_OPTS='--filter=proyecto-que-no-existe' \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh")
[ -z "$CANCELLED" ] || fail "cancelar fzf produjo una salida inesperada"
SESSIONS_AFTER=$(tmux_test list-sessions -F '#{session_name}' | wc -l)
[ "$SESSIONS_AFTER" -eq "$SESSIONS_BEFORE" ] || fail "cancelar fzf creo una sesion parcial"

# Esc y Ctrl-C abortan el fzf real con exito y sin crear sesiones parciales.
CANCEL_PANE=$(tmux_test new-window -d -t "=$SESSION" -n cancelar-selector -c "$REPOSITORY" -P -F '#{pane_id}')
quoted_project_script=$(printf '%s' "$PROJECT_ROOT/scripts/proyecto.sh" | sed "s/'/'\\''/g")
quoted_work_dir=$(printf '%s' "$WORK_DIR" | sed "s/'/'\\''/g")
for cancel_key in Escape C-c; do
  CANCEL_RESULT="$WORK_DIR/cancel-$cancel_key"
  quoted_cancel_result=$(printf '%s' "$CANCEL_RESULT" | sed "s/'/'\\''/g")
  tmux_test send-keys -l -t "$CANCEL_PANE" \
    "ENTORNO_TMUX_SOCKET='$SOCKET' ENTORNO_TMUX_PROJECT_ROOTS='$quoted_work_dir' '$quoted_project_script'; printf '%s' \"\$?\" > '$quoted_cancel_result'"
  tmux_test send-keys -t "$CANCEL_PANE" Enter
  attempts=0
  while ! tmux_test capture-pane -p -t "$CANCEL_PANE" | grep -q 'Proyecto>'; do
    attempts=$((attempts + 1))
    [ "$attempts" -lt 10 ] || fail "fzf no mostro el prompt del selector"
    sleep 1
  done
  tmux_test send-keys -t "$CANCEL_PANE" "$cancel_key"
  attempts=0
  while [ ! -f "$CANCEL_RESULT" ] && [ "$attempts" -lt 10 ]; do
    attempts=$((attempts + 1))
    sleep 1
  done
  [ -f "$CANCEL_RESULT" ] || fail "$cancel_key no cerro el selector"
  [ "$(cat "$CANCEL_RESULT")" = "0" ] || fail "$cancel_key no cancelo limpiamente"
  [ "$(tmux_test list-sessions -F '#{session_name}' | wc -l)" -eq "$SESSIONS_BEFORE" ] ||
    fail "$cancel_key creo una sesion parcial"
done
tmux_test kill-window -t "$CANCEL_PANE"

# En Debian se verifica realmente el fallback fdfind; en Arch/macOS puede existir fd.
if ! command -v fd >/dev/null 2>&1; then
  command -v fdfind >/dev/null 2>&1 || fail "sin fd, el selector no encontro fdfind"
fi

WORKTREE_SESSION=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_TMUX_NO_ATTACH=1 \
  ENTORNO_TMUX_PROJECT_ROOTS="$WORK_DIR" \
  FZF_DEFAULT_OPTS='--filter=worktree' \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh")
tmux_test has-session -t "=$WORKTREE_SESSION"
WORKTREE_CWD=$(tmux_test display-message -p -t "=$WORKTREE_SESSION:1.1" '#{pane_current_path}')
[ "$WORKTREE_CWD" = "$WORKTREE" ] || fail "el selector no reconocio el worktree"

# Desde otro servidor tmux se rechaza el anidamiento local.
if TMUX="$WORK_DIR/otro-socket,1,0" ENTORNO_TMUX_SOCKET="$SOCKET" \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh" "$REPOSITORY" >/dev/null 2>&1; then
  fail "proyecto.sh permitio tmux anidado entre sockets distintos"
fi

printf '%s\n' "Comprobacion tmux y transporte de agentes correcta."
