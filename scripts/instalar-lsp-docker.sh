#!/bin/sh
# Servidores LSP de Dockerfile y Docker Compose, fijados en tools/lsp-docker.
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/rutas.sh"
. "$SCRIPT_DIR/lib/plataforma.sh"
entorno_preferir_node_vendor
TOOLS_DIR="$PROJECT_ROOT/tools/lsp-docker"
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION"}

case "$XDG_ROOT" in
  /*) ;;
  *) XDG_ROOT="$PROJECT_ROOT/$XDG_ROOT" ;;
esac

if ! command -v node >/dev/null 2>&1 || ! command -v corepack >/dev/null 2>&1; then
  printf '%s\n' "Error: se requieren Node 24 LTS y Corepack." >&2
  exit 1
fi

COREPACK_HOME="$XDG_ROOT/corepack"
PNPM_STORE_DIR="$XDG_ROOT/pnpm/store"
mkdir -p "$COREPACK_HOME" "$PNPM_STORE_DIR"
export COREPACK_HOME

if node -e '
  const fs = require("fs");
  const path = require("path");
  const dir = process.argv[1];
  const manifest = JSON.parse(fs.readFileSync(path.join(dir, "package.json"), "utf8"));
  for (const [name, expected] of Object.entries(manifest.devDependencies)) {
    const installed = JSON.parse(fs.readFileSync(path.join(dir, "node_modules", ...name.split("/"), "package.json"), "utf8"));
    if (installed.version !== expected) process.exit(1);
  }
' "$TOOLS_DIR" 2>/dev/null; then
  printf '%s\n' "Servidores Docker ya instalados con las versiones fijadas."
else
  cd "$TOOLS_DIR"
  corepack "pnpm@$ENTORNO_PNPM_VERSION" install --frozen-lockfile --store-dir "$PNPM_STORE_DIR"
  corepack "pnpm@$ENTORNO_PNPM_VERSION" ignored-builds
fi

for executable in docker-langserver docker-compose-langserver; do
  [ -x "$TOOLS_DIR/node_modules/.bin/$executable" ] || {
    printf 'Error: falta %s.\n' "$executable" >&2
    exit 1
  }
done
printf '%s\n' "Servidores Dockerfile y Docker Compose instalados en $TOOLS_DIR/node_modules/.bin"
