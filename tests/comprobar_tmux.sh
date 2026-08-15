#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
SOCKET="entorno-nvim-test-$$"
WORK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-tmux.XXXXXX")
FALLBACK_HOME="$WORK_DIR-fallback casa con espacios"
CONTEXT_DIR="$WORK_DIR/runtime/agent-context"
NVIM_ARGS_FILE="$WORK_DIR/nvim-argc"

tmux_test() {
  tmux -L "$SOCKET" "$@"
}

cleanup() {
  tmux_test kill-server 2>/dev/null || true
  rm -rf "$WORK_DIR" "$FALLBACK_HOME"
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

wait_for_shell() {
  pane=$1
  attempts=0
  while [ "$attempts" -lt 5 ]; do
    actual=$(tmux_test display-message -p -t "$pane" '#{pane_current_command}')
    case "$actual" in
      sh | bash | dash | zsh | fish | ksh | tcsh | nu)
        printf '%s\n' "$actual"
        return 0
        ;;
    esac
    attempts=$((attempts + 1))
    sleep 1
  done
  fail "el panel $pane no volvio a una shell; proceso actual: $actual"
}

wait_for_output() {
  expected=$1
  pane=$2
  attempts=0
  while [ "$attempts" -lt 20 ]; do
    tmux_test capture-pane -p -J -t "$pane" | grep -Fq "$expected" && return 0
    attempts=$((attempts + 1))
    sleep 1
  done
  pane_output=$(tmux_test capture-pane -p -J -S - -t "$pane" | tail -n 30 | tr '\n' ' ')
  fail "el panel $pane no mostro: $expected; salida: $pane_output"
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
grep -Fq 'nvim_command=${NVIM_BIN:-"$DEFAULT_NVIM_BIN"}' "$PROJECT_ROOT/scripts/proyecto.sh" ||
  fail "proyecto.sh no usa el wrapper aislado como editor predeterminado"

REPOSITORY="$WORK_DIR/proyecto principal"
WORKTREE="$WORK_DIR/proyecto-worktree"
FALLBACK_REPOSITORY="$FALLBACK_HOME/Proyectos/proyecto fallback"
mkdir -p "$REPOSITORY" "$FALLBACK_REPOSITORY" "$CONTEXT_DIR"
REPOSITORY=$(CDPATH= cd "$REPOSITORY" && pwd -P)
chmod 700 "$CONTEXT_DIR"
git -C "$REPOSITORY" init -q
git -C "$REPOSITORY" -c user.name=Prueba -c user.email=prueba@example.invalid \
  commit --allow-empty -q -m inicial
git -C "$REPOSITORY" worktree add -q -b prueba-worktree "$WORKTREE"
WORKTREE=$(CDPATH= cd "$WORKTREE" && pwd -P)
git -C "$FALLBACK_REPOSITORY" init -q

SESSION=$(ENTORNO_TMUX_SOCKET="$SOCKET" \
  ENTORNO_NVIM_ROOT= \
  ENTORNO_TMUX_NO_ATTACH=1 \
  ENTORNO_TMUX_TEST_NVIM_ARGS_FILE="$NVIM_ARGS_FILE" \
  ENTORNO_TMUX_PROJECT_ROOTS="$WORK_DIR" \
  ENTORNO_TMUX_PROJECT_DEPTH=5 \
  LINES=78 \
  COLUMNS=319 \
  NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
  "$PROJECT_ROOT/scripts/proyecto.sh" "$REPOSITORY")

tmux_test has-session -t "=$SESSION"
[ "$(tmux_test list-panes -t "=$SESSION" | wc -l)" -eq 3 ] || fail "el layout inicial no tiene tres paneles"
[ "$(tmux_test display-message -p -t "=$SESSION:1" '#{window_name}')" = code ] ||
  fail "la ventana inicial no se llama code"
[ "$(tmux_test show-option -v -t "$SESSION" @entorno_project_root)" = "$REPOSITORY" ] ||
  fail "la sesion no conserva la raiz del proyecto con espacios"
[ "$(tmux_test show-option -v -t "$SESSION" @entorno_project_name)" = "proyecto principal" ] ||
  fail "la sesion no conserva el nombre legible del proyecto"
session_prefix=${SESSION%-*}
[ "$session_prefix" = "proyecto_principal" ] || fail "nombre de sesion inesperado o con sufijo espurio: $SESSION"

AGENT_PANE=$(tmux_test list-panes -s -t "=$SESSION" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "agent" { print $1 }')
EDITOR_PANE=$(tmux_test list-panes -s -t "=$SESSION" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "editor" { print $1 }')
TERMINAL_PANE=$(tmux_test list-panes -s -t "=$SESSION" -F '#{pane_id} #{@entorno_role}' |
  awk '$2 == "terminal" { print $1 }')
[ -n "$AGENT_PANE" ] || fail "falta el panel con rol agent"
[ -n "$EDITOR_PANE" ] || fail "falta el panel con rol editor"
[ -n "$TERMINAL_PANE" ] || fail "falta el panel con rol terminal"
[ "$(printf '%s\n' "$AGENT_PANE" | wc -l)" -eq 1 ] || fail "hay mas de un panel con rol agent"
[ "$(printf '%s\n' "$EDITOR_PANE" | wc -l)" -eq 1 ] || fail "hay mas de un panel con rol editor"
[ "$(printf '%s\n' "$TERMINAL_PANE" | wc -l)" -eq 1 ] || fail "hay mas de un panel con rol terminal"
[ "$(tmux_test list-panes -s -t "=$SESSION" -F '#{@entorno_role}' |
  awk '$0 == "editor" || $0 == "agent" || $0 == "terminal" { count++ } END { print count + 0 }')" -eq 3 ] ||
  fail "el layout no tiene exactamente los tres roles esperados"
wait_for_output "Agente>" "$AGENT_PANE"
[ -z "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent 2>/dev/null || true)" ] ||
  fail "el selector sin eleccion declaro un agente activo"
tmux_test send-keys -t "$AGENT_PANE" Escape
AGENT_SHELL=$(wait_for_shell "$AGENT_PANE")
attempts=0
while [ ! -f "$NVIM_ARGS_FILE" ] && [ "$attempts" -lt 20 ]; do
  attempts=$((attempts + 1))
  sleep 1
done
[ -f "$NVIM_ARGS_FILE" ] || fail "el editor de prueba no registro su arranque"
[ "$(cat "$NVIM_ARGS_FILE")" = "0" ] || fail "Neovim debe arrancar sin argumentos para mostrar el dashboard"
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

# Caso real de regresion: tmux conoce la raiz, pero una shell creada antes de
# set-environment no la recibe. El popup debe consultarla en la sesion.
SHELL_PANE=$TERMINAL_PANE
wait_for_shell "$SHELL_PANE" >/dev/null
# tmux puede informar el proceso de la shell antes de que su prompt acepte
# entrada, especialmente mientras arrancan en paralelo editor y selector.
sleep 1
SHELL_ROOT_FILE="$WORK_DIR/shell-root"
SHELL_TMUX_FILE="$WORK_DIR/shell-tmux"
quoted_shell_root_file=$(printf '%s' "$SHELL_ROOT_FILE" | sed "s/'/'\\''/g")
quoted_shell_tmux_file=$(printf '%s' "$SHELL_TMUX_FILE" | sed "s/'/'\\''/g")
tmux_test send-keys -l -t "$SHELL_PANE" \
  "printf '%s' \"\${ENTORNO_NVIM_ROOT-}\" > '$quoted_shell_root_file'; printf '%s' \"\$TMUX\" > '$quoted_shell_tmux_file'"
tmux_test send-keys -t "$SHELL_PANE" Enter
attempts=0
while [ ! -f "$SHELL_ROOT_FILE" ] && [ "$attempts" -lt 20 ]; do
  attempts=$((attempts + 1))
  sleep 1
done
[ -f "$SHELL_ROOT_FILE" ] && [ -f "$SHELL_TMUX_FILE" ] || fail "la shell no escribio su entorno"
[ ! -s "$SHELL_ROOT_FILE" ] || fail "la prueba no reprodujo ENTORNO_NVIM_ROOT ausente en la shell"
[ "$(tmux_test display-message -p -t "$SHELL_PANE" '#{ENTORNO_NVIM_ROOT}')" = "$PROJECT_ROOT" ] ||
  fail "el formato tmux no resolvio ENTORNO_NVIM_ROOT desde la sesion"

WINDOW_WIDTH=$(tmux_test display-message -p -t "=$SESSION:1" '#{window_width}')
WINDOW_HEIGHT=$(tmux_test display-message -p -t "=$SESSION:1" '#{window_height}')
TERMINAL_HEIGHT=$(tmux_test display-message -p -t "$TERMINAL_PANE" '#{pane_height}')
AGENT_WIDTH=$(tmux_test display-message -p -t "$AGENT_PANE" '#{pane_width}')
TERMINAL_PERCENT=$((TERMINAL_HEIGHT * 100 / WINDOW_HEIGHT))
AGENT_PERCENT=$((AGENT_WIDTH * 100 / WINDOW_WIDTH))
[ "$TERMINAL_PERCENT" -ge 12 ] && [ "$TERMINAL_PERCENT" -le 18 ] ||
  fail "el panel terminal ocupa ${TERMINAL_PERCENT}% de la altura; se esperaba aproximadamente 12-18%"
[ "$AGENT_PERCENT" -ge 25 ] && [ "$AGENT_PERCENT" -le 35 ] ||
  fail "el panel agent ocupa ${AGENT_PERCENT}% del ancho; se esperaba aproximadamente 25-35%"
BOTTOM_PANES=$(tmux_test list-panes -t "=$SESSION:1" -F '#{pane_top} #{pane_width}' |
  awk -v width="$WINDOW_WIDTH" '$1 > 0 && $2 == width { count++ } END { print count + 0 }')
[ "$BOTTOM_PANES" -eq 1 ] || fail "el panel inferior no ocupa todo el ancho"

for binding in h j k l H J K L C-a P r c d n a t p s w z '[' '|' '-'; do
  tmux_test list-keys -T prefix "$binding" >/dev/null 2>&1 || fail "falta el binding tmux $binding"
done
if tmux_test list-keys -T prefix C-b >/dev/null 2>&1; then
  fail "Ctrl-b no debe conservar un binding de prefijo"
fi
ROLE_SCRIPT="$PROJECT_ROOT/scripts/tmux-select-role.sh"
[ -x "$ROLE_SCRIPT" ] || fail "el selector de panel por rol no es ejecutable"
grep -q 'tmux display-message' "$ROLE_SCRIPT" || fail "el selector de rol no muestra los errores en tmux"
for role_binding in 'n editor' 'a agent' 't terminal'; do
  binding=${role_binding%% *}
  role=${role_binding#* }
  binding_definition=$(tmux_test list-keys -T prefix "$binding")
  printf '%s\n' "$binding_definition" | grep -q 'tmux-select-role\.sh' ||
    fail "Ctrl-a $binding no usa el selector por rol"
  printf '%s\n' "$binding_definition" | grep -q " $role " ||
    fail "Ctrl-a $binding no selecciona el rol $role"
  if printf '%s\n' "$binding_definition" | grep -q '\$0'; then
    fail "Ctrl-a $binding expone session_id a una segunda expansion del shell"
  fi
done

TMUX_TEST_ENV=$(tmux_test display-message -p -t "=$SESSION" '#{socket_path},#{pid},0')
active_pane() {
  tmux_test list-panes -s -t "=$SESSION" -F '#{pane_id} #{pane_active}' |
    while IFS=' ' read -r pane active; do
      [ "$active" = 1 ] && printf '%s\n' "$pane"
    done
}
select_role() {
  TMUX="$TMUX_TEST_ENV" TMUX_PANE="$EDITOR_PANE" \
    "$ROLE_SCRIPT" "$1" "$EDITOR_PANE"
}

select_role editor
[ "$(active_pane)" = "$EDITOR_PANE" ] || fail "Ctrl-a n no selecciono el panel editor"
select_role agent
[ "$(active_pane)" = "$AGENT_PANE" ] || fail "Ctrl-a a no selecciono el panel agent"
select_role terminal
[ "$(active_pane)" = "$TERMINAL_PANE" ] || fail "Ctrl-a t no selecciono el panel terminal"

# Los roles viajan con los paneles: intercambiar sus posiciones no debe alterar
# el destino de la navegacion.
tmux_test swap-pane -s "$EDITOR_PANE" -t "$TERMINAL_PANE"
select_role editor
[ "$(active_pane)" = "$EDITOR_PANE" ] || fail "la navegacion por rol dependio de la posicion del editor"
select_role terminal
[ "$(active_pane)" = "$TERMINAL_PANE" ] || fail "la navegacion por rol dependio de la posicion del terminal"
tmux_test swap-pane -s "$EDITOR_PANE" -t "$TERMINAL_PANE"

tmux_test set-option -p -u -t "$TERMINAL_PANE" @entorno_role
if missing_role_error=$(select_role terminal 2>&1); then
  fail "el selector acepto un rol inexistente"
fi
printf '%s\n' "$missing_role_error" | grep -q 'no existe ningun panel.*@entorno_role=terminal' ||
  fail "el selector no explico el rol inexistente"
tmux_test set-option -p -t "$TERMINAL_PANE" @entorno_role terminal

DUPLICATE_TERMINAL=$(tmux_test split-window -d -t "$TERMINAL_PANE" -c "$REPOSITORY" -P -F '#{pane_id}')
tmux_test set-option -p -t "$DUPLICATE_TERMINAL" @entorno_role terminal
if duplicate_role_error=$(select_role terminal 2>&1); then
  fail "el selector acepto dos paneles con el mismo rol"
fi
printf '%s\n' "$duplicate_role_error" | grep -q 'mas de un panel.*@entorno_role=terminal' ||
  fail "el selector no explico el rol duplicado"
tmux_test kill-pane -t "$DUPLICATE_TERMINAL"

POPUP_BINDING=$(tmux_test list-keys -T prefix P)
printf '%s\n' "$POPUP_BINDING" | grep -q 'popup-proyecto\.sh' || fail "Ctrl-a P no usa el lanzador del popup"
printf '%s\n' "$POPUP_BINDING" | grep -q 'show-environment -t.*ENTORNO_NVIM_ROOT' ||
  fail "el popup no obtiene la raiz desde el entorno de sesion"
if printf '%s\n' "$POPUP_BINDING" | grep -q 'show-environment ENTORNO_NVIM_ROOT'; then
  fail "el binding consulta la raiz sin un destino de sesion explicito"
fi
if printf '%s\n' "$POPUP_BINDING" | grep -q '\$ENTORNO_NVIM_ROOT/scripts/proyecto'; then
  fail "el popup sigue dependiendo de ENTORNO_NVIM_ROOT en la shell"
fi
POPUP_SCRIPT="$PROJECT_ROOT/scripts/popup-proyecto.sh"
[ -x "$POPUP_SCRIPT" ] || fail "el lanzador del popup no es ejecutable"
grep -q 'display-popup' "$POPUP_SCRIPT" || fail "el lanzador no abre un popup"
grep -q '#{pane_current_path}' "$POPUP_SCRIPT" || fail "el popup no conserva el cwd del panel"
grep -q '85%' "$POPUP_SCRIPT" || fail "el popup no tiene anchura suficiente"
grep -q '75%' "$POPUP_SCRIPT" || fail "el popup no tiene altura suficiente"
grep -q -- '-b simple' "$POPUP_SCRIPT" || fail "el popup no usa un borde ASCII portable"
grep -q 'scripts/proyecto\.sh' "$POPUP_SCRIPT" || fail "el popup no reutiliza proyecto.sh"
if printf '%s\n' "$POPUP_BINDING" | grep -Eq 'sesh|gum|fzf-tmux' ||
  grep -Eq 'sesh|gum|fzf-tmux' "$POPUP_SCRIPT"; then
  fail "el popup introdujo un sessionizer o selector adicional"
fi
REFRESH_BINDING=$(tmux_test list-keys -T prefix r)
printf '%s\n' "$REFRESH_BINDING" | grep -q 'refresh-client' || fail "Ctrl-a r dejo de refrescar el cliente"
if printf '%s\n' "$REFRESH_BINDING" | grep -q 'ENTORNO_'; then
  fail "Ctrl-a r depende indebidamente del entorno de entorno-nvim"
fi

# Regresion exacta: la shell no tiene la raiz, tmux si; ademas existe otra
# sesion y el popup no dispone de TMUX_PANE. El destino explicito evita mezclar
# entornos de sesion.
DECOY_SESSION=sesion-ajena
tmux_test new-session -d -s "$DECOY_SESSION" -c "$WORK_DIR"
tmux_test set-environment -t "=$DECOY_SESSION" ENTORNO_NVIM_ROOT "$WORK_DIR/raiz-incorrecta"
POPUP_SELECTED=$(
  unset TMUX_PANE
  ENTORNO_TMUX_SOCKET= \
    ENTORNO_TMUX_PROJECT_ROOTS= \
    ENTORNO_TMUX_PROJECT_DEPTH= \
    ENTORNO_SOURCE_SESSION="$SESSION" \
    NVIM_BIN= \
    ENTORNO_TMUX_NO_ATTACH=1 \
    FZF_DEFAULT_OPTS='--filter=principal' \
    TMUX="$(cat "$SHELL_TMUX_FILE")" \
    "$PROJECT_ROOT/scripts/proyecto.sh"
)
[ "$POPUP_SELECTED" = "$SESSION" ] || fail "el popup no uso la sesion de origen explicita"

# Una sesion antigua sin roots usa solo los fallbacks documentados de HOME.
tmux_test set-environment -u -t "=$SESSION" ENTORNO_TMUX_PROJECT_ROOTS
FALLBACK_SELECTED=$(
  unset TMUX_PANE
  HOME="$FALLBACK_HOME" \
    ENTORNO_TMUX_SOCKET= \
    ENTORNO_TMUX_PROJECT_ROOTS= \
    ENTORNO_TMUX_PROJECT_DEPTH= \
    ENTORNO_SOURCE_SESSION="$SESSION" \
    NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
    ENTORNO_TMUX_NO_ATTACH=1 \
    FZF_DEFAULT_OPTS='--filter=fallback' \
    TMUX="$(cat "$SHELL_TMUX_FILE")" \
    "$PROJECT_ROOT/scripts/proyecto.sh"
)
tmux_test has-session -t "=$FALLBACK_SELECTED"
[ "$(tmux_test show-environment -t "=$FALLBACK_SELECTED" ENTORNO_TMUX_PROJECT_ROOTS)" = "ENTORNO_TMUX_PROJECT_ROOTS=$FALLBACK_HOME/Proyectos" ] ||
  fail "el fallback de roots no quedo limitado a HOME/Proyectos"
tmux_test set-environment -t "=$SESSION" ENTORNO_TMUX_PROJECT_ROOTS "$WORK_DIR"
[ "$(tmux_test show-options -gv prefix)" = "C-a" ] || fail "el prefijo tmux debe ser Ctrl-a"
[ "$(tmux_test show-options -gv mouse)" = "on" ] || fail "mouse debe estar activado"
[ "$(tmux_test show-options -gv status-interval)" = 15 ] || fail "status-interval no es razonable"
[ "$(tmux_test show-options -gv status-style)" = "fg=colour7,bg=colour0" ] || fail "status-style no usa colores ANSI"
[ "$(tmux_test show-options -gv status-left-style)" = "fg=colour6,bg=colour0,bold" ] ||
  fail "status-left no destaca el proyecto"
[ "$(tmux_test show-options -gv status-right-style)" = "fg=colour7,bg=colour0" ] ||
  fail "status-right no conserva contraste ANSI"
[ "$(tmux_test show-options -gv status-left)" = ' #{?#{@entorno_project_name},#{@entorno_project_name},#S} #[fg=colour8,bg=colour0,nobold]|' ] ||
  fail "status-left no muestra el nombre legible del proyecto"
[ "$(tmux_test show-options -gv window-status-separator)" = "" ] ||
  fail "tmux anade separacion fuera de los formatos controlados"
[ "$(tmux_test show-window-options -gv window-status-format)" = " #I:#W #[fg=colour8,bg=colour0]|" ] ||
  fail "las ventanas inactivas no muestran indice y nombre"
[ "$(tmux_test show-window-options -gv window-status-current-format)" = " [#I:#W] #[fg=colour8,bg=colour0,nobold]|" ] ||
  fail "la ventana activa no usa corchetes ASCII"
[ "$(tmux_test show-window-options -gv window-status-style)" = "fg=colour7,bg=colour0" ] ||
  fail "las ventanas inactivas no usan el estilo ANSI"
[ "$(tmux_test show-window-options -gv window-status-current-style)" = "fg=colour0,bg=colour6,bold" ] ||
  fail "la ventana activa no esta diferenciada"
[ "$(tmux_test display-message -p -t "=$SESSION:1" '#{T:status-left}')" = " proyecto principal #[fg=colour8,bg=colour0,nobold]|" ] ||
  fail "status-left no oculta el checksum de la sesion"
STATUS_RIGHT=$(tmux_test show-options -gv status-right)
printf '%s\n' "$STATUS_RIGHT" | grep -q 'tmux-status\.sh' || fail "status-right no usa el helper"
printf '%s\n' "$STATUS_RIGHT" | grep -q '%H:%M' || fail "status-right no muestra la hora"
printf '%s\n' "$STATUS_RIGHT" | grep -Fq '#[fg=colour6,bold]%H:%M' || fail "status-right no destaca la hora"
[ "$(tmux_test show-options -gv base-index)" = "1" ] || fail "base-index debe ser 1"
[ "$(tmux_test show-window-options -gv pane-base-index)" = "1" ] || fail "pane-base-index debe ser 1"
[ "$(tmux_test show-window-options -gv mode-keys)" = "vi" ] || fail "copy mode debe usar teclas Vi"
[ "$(tmux_test show-options -gv focus-events)" = "on" ] || fail "focus-events debe estar activo"

STATUS_SCRIPT="$PROJECT_ROOT/scripts/tmux-status.sh"
[ -x "$STATUS_SCRIPT" ] || fail "falta el helper ejecutable de la barra tmux"
STATUS_TMUX=$(tmux_test display-message -p -t "$EDITOR_PANE" '#{socket_path},#{pid},0')
status_output() {
  TMUX="$STATUS_TMUX" TMUX_PANE="$EDITOR_PANE" "$STATUS_SCRIPT" "$SESSION"
}
EXPECTED_BRANCH=$(git -C "$REPOSITORY" symbolic-ref --quiet --short HEAD)
[ "$(status_output)" = "git:$EXPECTED_BRANCH | AI:-" ] ||
  fail "la barra no muestra Git limpio y agente ausente"
printf '%s\n' modificado > "$REPOSITORY/estado-barra.txt"
git -C "$REPOSITORY" add estado-barra.txt
[ "$(status_output)" = "git:$EXPECTED_BRANCH * | AI:-" ] ||
  fail "la barra no muestra el repositorio modificado"
tmux_test set-option -p -t "$AGENT_PANE" @entorno_agent codex
[ "$(status_output)" = "git:$EXPECTED_BRANCH * | AI:Codex" ] ||
  fail "la barra no muestra el agente Codex"
tmux_test set-option -p -u -t "$AGENT_PANE" @entorno_agent

# El selector usa fzf cuando existe y conserva el rol del panel.
SELECTOR="$PROJECT_ROOT/scripts/selector-agente.sh"
[ -x "$SELECTOR" ] || fail "falta el selector de agentes ejecutable"
FAKE_FZF_BIN="$WORK_DIR/fake-fzf-bin"
mkdir -p "$FAKE_FZF_BIN"
ln -s "$PROJECT_ROOT/tests/fixtures/tmux/fake-fzf.sh" "$FAKE_FZF_BIN/fzf"
FZF_MARKER="$WORK_DIR/fzf-usado"
quoted_selector=$(printf '%s' "$SELECTOR" | sed "s/'/'\\''/g")
quoted_fake_fzf_bin=$(printf '%s' "$FAKE_FZF_BIN" | sed "s/'/'\\''/g")
quoted_fzf_marker=$(printf '%s' "$FZF_MARKER" | sed "s/'/'\\''/g")
tmux_test send-keys -l -t "$AGENT_PANE" \
  "PATH='$quoted_fake_fzf_bin':\$PATH ENTORNO_TMUX_SOCKET='$SOCKET' ENTORNO_TMUX_TEST_FZF_MARKER='$quoted_fzf_marker' ENTORNO_TMUX_TEST_FZF_CHOICE=exit '$quoted_selector'"
tmux_test send-keys -t "$AGENT_PANE" Enter
attempts=0
while [ ! -f "$FZF_MARKER" ]; do
  attempts=$((attempts + 1))
  [ "$attempts" -lt 20 ] || fail "el selector no uso fzf"
  sleep 1
done
[ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_role)" = agent ] ||
  fail "el selector altero @entorno_role=agent"
AGENT_SHELL=$(wait_for_shell "$AGENT_PANE")
[ "$(wc -l < "$FZF_MARKER" | tr -d ' ')" -eq 1 ] || fail "fzf se ejecuto un numero inesperado de veces"
[ -z "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent 2>/dev/null || true)" ] ||
  fail "el selector no limpio @entorno_agent al salir"

# Sin fzf se ofrece el menu textual. El agente se lanza siempre a traves de
# agente.sh, publica ambos estados y al terminar regresa al selector.
TEXT_BIN="$WORK_DIR/text-selector-bin"
mkdir -p "$TEXT_BIN"
ln -s "$PROJECT_ROOT/tests/fixtures/tmux/fake-agent.sh" "$TEXT_BIN/codex"
AGENT_STARTED="$TEXT_BIN/agent-started"
AGENT_RECEIVED="$TEXT_BIN/agent-received"
quoted_text_bin=$(printf '%s' "$TEXT_BIN" | sed "s/'/'\\''/g")
tmux_test send-keys -l -t "$AGENT_PANE" \
  "PATH='$quoted_text_bin':\$PATH SHELL=/bin/sh ENTORNO_TMUX_SOCKET='$SOCKET' ENTORNO_AGENT_SELECTOR_USE_FZF=0 ENTORNO_AGENT_CODEX_PROCESS=tee '$quoted_selector'"
tmux_test send-keys -t "$AGENT_PANE" Enter
wait_for_output "Selecciona agente:" "$AGENT_PANE"
tmux_test send-keys -l -t "$AGENT_PANE" codex
tmux_test send-keys -t "$AGENT_PANE" Enter
attempts=0
while [ ! -f "$AGENT_STARTED" ]; do
  attempts=$((attempts + 1))
  if [ "$attempts" -ge 20 ]; then
    pane_output=$(tmux_test capture-pane -p -J -S - -t "$AGENT_PANE" | tail -n 30 | tr '\n' ' ')
    fail "el fallback no ejecuto el agente simulado; salida: $pane_output"
  fi
  sleep 1
done
wait_for_process tee "$AGENT_PANE"
[ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_role)" = agent ] ||
  fail "la limpieza altero @entorno_role=agent"
[ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent)" = codex ] ||
  fail "el selector no declaro @entorno_agent=codex"
[ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent_command)" = codex ] ||
  fail "el selector no uso scripts/agente.sh"
[ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent_process)" = tee ] ||
  fail "la limpieza altero el proceso declarado del agente"
attempts=0
while :; do
  AGENT_CAPTURE=$(tmux_test capture-pane -p -J -S - -t "$AGENT_PANE")
  if ! printf '%s\n' "$AGENT_CAPTURE" |
    grep -Eq 'Selecciona agente:|ENTORNO_AGENT_SELECTOR_USE_FZF=0|scripts/agente\.sh'; then
    break
  fi
  attempts=$((attempts + 1))
  if [ "$attempts" -ge 5 ]; then
    pane_output=$(printf '%s\n' "$AGENT_CAPTURE" | tail -n 20 | tr '\n' ' ')
    fail "el panel del agente conserva contenido anterior tras la limpieza: $pane_output"
  fi
  sleep 1
done
MENUS_BEFORE=$(tmux_test capture-pane -p -J -S - -t "$AGENT_PANE" | grep -Fc "Selecciona agente:" || true)
tmux_test send-keys -t "$AGENT_PANE" C-d
attempts=0
while :; do
  menus_now=$(tmux_test capture-pane -p -J -S - -t "$AGENT_PANE" | grep -Fc "Selecciona agente:" || true)
  state_now=$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent 2>/dev/null || true)
  [ "$menus_now" -gt "$MENUS_BEFORE" ] && [ -z "$state_now" ] && break
  attempts=$((attempts + 1))
  [ "$attempts" -lt 20 ] || fail "el fallback no volvio al selector tras salir del agente"
  sleep 1
done
tmux_test send-keys -l -t "$AGENT_PANE" shell
tmux_test send-keys -t "$AGENT_PANE" Enter
attempts=0
while [ "$(tmux_test show-option -p -v -t "$AGENT_PANE" @entorno_agent 2>/dev/null || true)" != shell ]; do
  attempts=$((attempts + 1))
  if [ "$attempts" -ge 20 ]; then
    pane_output=$(tmux_test capture-pane -p -J -S - -t "$AGENT_PANE" | tail -n 30 | tr '\n' ' ')
    fail "el fallback no declaro @entorno_agent=shell; salida: $pane_output"
  fi
  sleep 1
done
MENUS_BEFORE=$(tmux_test capture-pane -p -J -S - -t "$AGENT_PANE" | grep -Fc "Selecciona agente:" || true)
tmux_test send-keys -l -t "$AGENT_PANE" exit
tmux_test send-keys -t "$AGENT_PANE" Enter
attempts=0
while :; do
  menus_now=$(tmux_test capture-pane -p -J -S - -t "$AGENT_PANE" | grep -Fc "Selecciona agente:" || true)
  [ "$menus_now" -gt "$MENUS_BEFORE" ] && break
  attempts=$((attempts + 1))
  [ "$attempts" -lt 20 ] || fail "el fallback no volvio al selector tras salir de la shell"
  sleep 1
done
tmux_test send-keys -l -t "$AGENT_PANE" exit
tmux_test send-keys -t "$AGENT_PANE" Enter
AGENT_SHELL=$(wait_for_shell "$AGENT_PANE")
[ "$(tmux_test list-panes -t "=$SESSION" | wc -l)" -eq 3 ] || fail "el selector altero la geometria"
if tmux_test list-buffers -F '#{buffer_name}' 2>/dev/null | grep -q '^entorno-agent-selector-'; then
  fail "el selector dejo un buffer auxiliar de tmux"
fi

# Una shell, incluso dentro del panel marcado, nunca es un destino valido.
# En macOS el proceso inicial puede aparecer brevemente como sh antes de que la
# shell interactiva configurada termine de arrancar.
sleep 1
AGENT_SHELL=$(wait_for_shell "$AGENT_PANE")
shell_index=10
for shell in bash sh dash zsh fish; do
  command -v "$shell" >/dev/null 2>&1 || continue
  if [ "$shell" != "$AGENT_SHELL" ]; then
    tmux_test send-keys -l -t "$AGENT_PANE" "$shell"
    tmux_test send-keys -t "$AGENT_PANE" Enter
    # tmux 3.6b en macOS puede seguir informando la shell padre aunque el
    # prompt de la subshell ya este activo; el rechazo se valida igualmente
    # contra el proceso que tmux expone al transporte.
    sleep 1
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
    AGENT_SHELL=$(wait_for_shell "$AGENT_PANE")
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
AGENT_SHELL=$(wait_for_shell "$AGENT_PANE")
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
AGENT_SHELL=$(wait_for_shell "$AGENT_PANE")

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
