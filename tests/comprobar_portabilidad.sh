#!/bin/sh
set -eu
SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/entorno-portable.XXXXXX")
TEST_SOCKET=entorno-portable-$$
cleanup() {
  tmux -L "$TEST_SOCKET" kill-server 2>/dev/null || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM
NVIM_TEST_BIN=${NVIM_BIN:-$(command -v nvim)}
mkdir -p "$TEST_ROOT/escritorio/config" "$TEST_ROOT/escritorio/runtime"
chmod 700 "$TEST_ROOT/escritorio/runtime"

# El arranque personal debe conservar PDF, IA y los atajos historicos.
(
  unset ENTORNO_PERFIL ENTORNO_IA
  NVIM_BIN="$NVIM_TEST_BIN" NVIM_XDG_ROOT="$TEST_ROOT/personal" \
    "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
      '+lua local p = require("config.profile"); assert(p.name == "profesor" and p.has("pdf") and p.has("ai")); for _, k in ipairs({" mp", " mv", " ac", " ee", " ff", " fg", " gg"}) do assert(vim.fn.maparg(k, "n") ~= "", "Falta atajo: " .. k) end; assert(vim.v.errmsg == "", vim.v.errmsg)' +qa
)

for profile in inicial dwec si profesor; do
  NVIM_BIN="$NVIM_TEST_BIN" NVIM_XDG_ROOT="$TEST_ROOT/$profile" \
  ENTORNO_PERFIL="$profile" ENTORNO_IA=0 \
  XDG_CONFIG_HOME="$TEST_ROOT/escritorio/config" \
  XDG_RUNTIME_DIR="$TEST_ROOT/escritorio/runtime" \
  ENTORNO_DESKTOP_ENV_SAVED=0 \
  ENTORNO_TEST_DESKTOP_CONFIG="$TEST_ROOT/escritorio/config" \
  ENTORNO_TEST_DESKTOP_RUNTIME="$TEST_ROOT/escritorio/runtime" \
    "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
      "+lua local ok, err = pcall(dofile, vim.env.ENTORNO_NVIM_ROOT .. '/tests/comprobar_portabilidad.lua'); if not ok then print(err); vim.cmd('cquit 1') end" +qa
done

# Simular una terminal sin escritorio; no certifica otra distribucion, pero
# detecta dependencias accidentales de Wayland/X11 en el arranque basico.
(
  unset DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR
  NVIM_BIN="$NVIM_TEST_BIN" NVIM_XDG_ROOT="$TEST_ROOT/sin-escritorio" \
  ENTORNO_PERFIL=si ENTORNO_IA=0 \
    "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
      '+lua assert(not vim.env.DISPLAY and not vim.env.WAYLAND_DISPLAY); assert(vim.v.errmsg == "", vim.v.errmsg)' +qa
)

# El opt-in de IA se comprueba sin lanzar ni conectar ningun agente.
NVIM_BIN="$NVIM_TEST_BIN" NVIM_XDG_ROOT="$TEST_ROOT/ia" \
ENTORNO_PERFIL=dwec ENTORNO_IA=1 \
  "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
    '+lua assert(require("config.profile").has("ai")); assert(vim.fn.maparg(" ac", "n") ~= "")' +qa

if ENTORNO_PERFIL=no-existe NVIM_XDG_ROOT="$TEST_ROOT/invalido" \
  "$PROJECT_ROOT/scripts/arrancar.sh" --headless +qa >/dev/null 2>&1; then
  printf '%s\n' 'Error: se acepto un perfil invalido.' >&2; exit 1
fi
[ ! -e "$TEST_ROOT/invalido" ]
if "$PROJECT_ROOT/bin/entorno-dev" --perfil desconocido >/dev/null 2>&1; then
  printf '%s\n' 'Error: el lanzador acepto un perfil invalido.' >&2; exit 1
fi

# La entrada publica debe mantener la carpeta y usar el wrapper incluso
# cuando NVIM_BIN selecciona otro binario.
mkdir -p "$TEST_ROOT/proyecto con espacios"
NVIM_BIN="$PROJECT_ROOT/tests/fixtures/tmux/inspect-editor.sh" \
NVIM_XDG_ROOT="$TEST_ROOT/lanzador" ENTORNO_IA=0 \
  "$PROJECT_ROOT/bin/entorno-dev" --sin-tmux --perfil dwec "$TEST_ROOT/proyecto con espacios" > "$TEST_ROOT/entrada"
[ "$(sed -n '1p' "$TEST_ROOT/entrada")" = "$TEST_ROOT/proyecto con espacios" ]
[ "$(sed -n '2p' "$TEST_ROOT/entrada")" = dwec ]
[ "$(sed -n '3p' "$TEST_ROOT/entrada")" = 0 ]
[ "$(sed -n '4p' "$TEST_ROOT/entrada")" = "$PROJECT_ROOT" ]
[ "$(sed -n '5p' "$TEST_ROOT/entrada")" = "$TEST_ROOT/lanzador/state/dwec" ]

if command -v tmux >/dev/null 2>&1; then
  for profile in dwec si; do
    session=$(ENTORNO_TMUX_SOCKET="$TEST_SOCKET" ENTORNO_TMUX_NO_ATTACH=1 \
      ENTORNO_IA=0 ENTORNO_EDITOR_COMMAND="$PROJECT_ROOT/tests/fixtures/tmux/fake-nvim.sh" \
      "$PROJECT_ROOT/bin/entorno-dev" --perfil "$profile" --tmux "$TEST_ROOT/proyecto con espacios")
    [ "$(tmux -L "$TEST_SOCKET" list-panes -t "=$session" | wc -l)" -eq 2 ]
    [ "$(tmux -L "$TEST_SOCKET" list-panes -t "=$session" -F '#{@entorno_role}' | sort | tr '\n' ' ')" = 'editor terminal ' ]
    [ "$(tmux -L "$TEST_SOCKET" show-environment -t "=$session" ENTORNO_PERFIL)" = "ENTORNO_PERFIL=$profile" ]
  done
  [ "$(tmux -L "$TEST_SOCKET" list-sessions | wc -l)" -eq 2 ]
fi
printf '%s\n' 'Comprobacion de portabilidad y arranque minimo correcta.'
