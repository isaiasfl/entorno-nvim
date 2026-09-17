#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$PROJECT_ROOT/scripts/lib/versiones.sh"

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/entorno-nvim-instalacion.XXXXXX")
TEST_ROOT=$(CDPATH= cd "$TEST_ROOT" && pwd -P)
TEST_HOME="$TEST_ROOT/home"
TEST_XDG="$TEST_ROOT/xdg"
SOURCE_TOOLS=${ENTORNO_TOOLS_ROOT:-"$PROJECT_ROOT/.tools"}
TEST_TOOLS="$TEST_ROOT/tools"
export ENTORNO_TOOLS_ROOT="$TEST_TOOLS"
export ENTORNO_PERFIL=profesor
TMUX_SOCKET="entorno-nvim-install-$$"
. "$PROJECT_ROOT/scripts/lib/plataforma.sh"

cleanup() {
  tmux -L "$TMUX_SOCKET" kill-server 2>/dev/null || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$TEST_TOOLS" "$TEST_XDG/data/nvim/lazy" "$TEST_XDG/data/nvim/site/parser"

HOME="$TEST_HOME" "$PROJECT_ROOT/scripts/instalar-entorno-dev.sh" >/dev/null
[ -L "$TEST_HOME/.local/bin/entorno-dev" ]
[ "$(readlink "$TEST_HOME/.local/bin/entorno-dev")" = "$PROJECT_ROOT/bin/entorno-dev" ]
HOME="$TEST_HOME" "$PROJECT_ROOT/scripts/instalar-entorno-dev.sh" >/dev/null
[ "$(readlink "$TEST_HOME/.local/bin/entorno-dev")" = "$PROJECT_ROOT/bin/entorno-dev" ]

COLLISION_HOME="$TEST_ROOT/home-colision"
mkdir -p "$COLLISION_HOME/.local/bin"
printf '%s\n' "lanzador ajeno" >"$COLLISION_HOME/.local/bin/entorno-dev"
if HOME="$COLLISION_HOME" "$PROJECT_ROOT/scripts/instalar-entorno-dev.sh" >/dev/null 2>&1; then
  printf '%s\n' "Error: el instalador sobrescribiria un lanzador ajeno." >&2
  exit 1
fi
[ "$(sed -n '1p' "$COLLISION_HOME/.local/bin/entorno-dev")" = "lanzador ajeno" ]

FOREIGN_LINK_HOME="$TEST_ROOT/home-enlace-ajeno"
mkdir -p "$FOREIGN_LINK_HOME/.local/bin"
ln -s "$TEST_ROOT/lanzador-ajeno" "$FOREIGN_LINK_HOME/.local/bin/entorno-dev"
if HOME="$FOREIGN_LINK_HOME" "$PROJECT_ROOT/scripts/instalar-entorno-dev.sh" >/dev/null 2>&1; then
  printf '%s\n' "Error: el instalador sobrescribiria un enlace ajeno." >&2
  exit 1
fi
[ "$(readlink "$FOREIGN_LINK_HOME/.local/bin/entorno-dev")" = "$TEST_ROOT/lanzador-ajeno" ]

for directory in "tree-sitter-cli-$ENTORNO_TREE_SITTER_VERSION"; do
  [ -d "$SOURCE_TOOLS/$directory" ] || {
    printf 'Error: falta la instalacion fuente para la prueba aislada: %s\n' "$directory" >&2
    exit 1
  }
  ln -s "$SOURCE_TOOLS/$directory" "$TEST_TOOLS/$directory"
done

# El Node vendorizado forma parte de la instalacion preparada: la prueba
# aislada debe reutilizarlo igual que Neovim, LuaLS y tree-sitter.
if [ -n "${ENTORNO_NODE_PLATFORM:-}" ]; then
  node_directory="node-$ENTORNO_NODE_VERSION-$ENTORNO_NODE_PLATFORM"
  [ -d "$SOURCE_TOOLS/$node_directory" ] || {
    printf 'Error: falta la instalacion fuente para la prueba aislada: %s\n' "$node_directory" >&2
    exit 1
  }
  ln -s "$SOURCE_TOOLS/$node_directory" "$TEST_TOOLS/$node_directory"
fi

if [ "$(uname -s)" = Darwin ]; then
  mkdir -p \
    "$TEST_TOOLS/nvim-$ENTORNO_NVIM_VERSION/bin" \
    "$TEST_TOOLS/lua-language-server-$ENTORNO_LUALS_VERSION/bin"
  ln -s "$(command -v nvim)" "$TEST_TOOLS/nvim-$ENTORNO_NVIM_VERSION/bin/nvim"
  ln -s "$(command -v lua-language-server)" \
    "$TEST_TOOLS/lua-language-server-$ENTORNO_LUALS_VERSION/bin/lua-language-server"
else
  for directory in \
    "nvim-$ENTORNO_NVIM_VERSION" \
    "lua-language-server-$ENTORNO_LUALS_VERSION"
  do
    [ -d "$SOURCE_TOOLS/$directory" ] || {
      printf 'Error: falta la instalacion fuente para la prueba aislada: %s\n' "$directory" >&2
      exit 1
    }
    ln -s "$SOURCE_TOOLS/$directory" "$TEST_TOOLS/$directory"
  done
fi

while IFS=' ' read -r plugin commit; do
  [ -n "$plugin" ] || continue
  source_dir="$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION/data/nvim/lazy/$plugin"
  [ -d "$source_dir/.git" ] || {
    printf 'Error: falta el plugin local para la prueba aislada: %s\n' "$plugin" >&2
    exit 1
  }
  git -c advice.detachedHead=false clone --quiet --shared "$source_dir" "$TEST_XDG/data/nvim/lazy/$plugin"
  git -c advice.detachedHead=false -C "$TEST_XDG/data/nvim/lazy/$plugin" switch --quiet --detach "$commit"
done <<EOF
$(sed -n 's/^[[:space:]]*"\([^"]*\)":.*"commit": "\([0-9a-f]*\)".*/\1 \2/p' "$PROJECT_ROOT/nvim/lazy-lock.json")
EOF

for parser in $ENTORNO_PARSERS; do
  source_parser="$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION/data/nvim/site/parser/$parser.so"
  [ -f "$source_parser" ] || {
    printf 'Error: falta el parser local para la prueba aislada: %s\n' "$parser" >&2
    exit 1
  }
  cp "$source_parser" "$TEST_XDG/data/nvim/site/parser/$parser.so"
done

HOME="$TEST_HOME" NVIM_XDG_ROOT="$TEST_XDG" \
  "$PROJECT_ROOT/scripts/comprobar-requisitos.sh" >/dev/null

HOME="$TEST_HOME" NVIM_XDG_ROOT="$TEST_XDG" \
  "$PROJECT_ROOT/scripts/arrancar.sh" --headless \
  "+lua local ok, err = pcall(dofile, '$PROJECT_ROOT/tests/comprobar_instalacion.lua'); if not ok then vim.api.nvim_err_writeln(err); vim.cmd('cquit 1') end" \
  "+qa"

tmux -L "$TMUX_SOCKET" -f "$PROJECT_ROOT/tmux/tmux.conf" \
  new-session -d -s instalacion -c "$PROJECT_ROOT"
[ "$(tmux -L "$TMUX_SOCKET" show-options -gv prefix)" = C-a ]
[ "$(tmux -L "$TMUX_SOCKET" show-options -gv mouse)" = on ]
tmux -L "$TMUX_SOCKET" kill-server

HOME="$TEST_HOME" "$PROJECT_ROOT/scripts/markdown-pdf.sh" \
  "$PROJECT_ROOT/examples/examen/examen2.md" "$TEST_ROOT/examen2.pdf" >/dev/null
[ -s "$TEST_ROOT/examen2.pdf" ]

printf '%s\n' "Comprobacion de instalacion aislada correcta."
