#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/rutas.sh"
. "$SCRIPT_DIR/lib/plataforma.sh"
entorno_preferir_node_vendor
TOOLS_DIR="$PROJECT_ROOT/tools/lsp-bash"
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION"}

case "$XDG_ROOT" in
  /*) ;;
  *) XDG_ROOT="$PROJECT_ROOT/$XDG_ROOT" ;;
esac

if ! command -v node >/dev/null 2>&1 || ! command -v corepack >/dev/null 2>&1; then
  printf '%s\n' "Error: se requieren Node 24 LTS y Corepack." >&2
  exit 1
fi

[ "$(node -p "Number(process.versions.node.split('.')[0] === '24')")" = 1 ] || {
  printf 'Error: se requiere Node >=24 <25; version encontrada: %s.\n' "$(node --version)" >&2
  exit 1
}

COREPACK_HOME="$XDG_ROOT/corepack"
PNPM_STORE_DIR="$XDG_ROOT/pnpm/store"
mkdir -p "$COREPACK_HOME" "$PNPM_STORE_DIR"
export COREPACK_HOME

if node -e '
  const fs = require("fs");
  const path = require("path");
  const dir = process.argv[1];
  const manifest = JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf8"));
  const installed = JSON.parse(fs.readFileSync(path.join(dir, "node_modules/bash-language-server/package.json"), "utf8"));
  if (installed.version !== manifest.devDependencies["bash-language-server"]) process.exit(1);
' "$TOOLS_DIR" 2>/dev/null; then
  printf '%s\n' "Bash Language Server ya esta instalado con la version fijada."
else
  cd "$TOOLS_DIR"
  corepack "pnpm@$ENTORNO_PNPM_VERSION" install --frozen-lockfile --store-dir "$PNPM_STORE_DIR"
  corepack "pnpm@$ENTORNO_PNPM_VERSION" ignored-builds
fi

executable="$TOOLS_DIR/node_modules/.bin/bash-language-server"
[ -x "$executable" ] || { printf '%s\n' "Error: falta bash-language-server." >&2; exit 1; }
"$executable" --version
printf '%s\n' "Bash Language Server instalado en $TOOLS_DIR/node_modules/.bin"
