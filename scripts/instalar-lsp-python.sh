#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
TOOLS_DIR="$PROJECT_ROOT/tools/lsp-python"
XDG_ROOT=${NVIM_XDG_ROOT:-"$PROJECT_ROOT/.xdg/0.12.4"}

case "$XDG_ROOT" in
  /*) ;;
  *) XDG_ROOT="$PROJECT_ROOT/$XDG_ROOT" ;;
esac

if ! command -v node >/dev/null 2>&1 || ! command -v corepack >/dev/null 2>&1; then
  printf '%s\n' "Error: se requieren Node 22 y Corepack." >&2
  exit 1
fi

NODE_COMPATIBLE=$(node -p "const [major, minor] = process.versions.node.split('.').map(Number); Number(major === 22 && minor >= 13)")
if [ "$NODE_COMPATIBLE" != "1" ]; then
  printf '%s\n' "Error: se requiere Node >=22.13 <23; version encontrada: $(node --version)" >&2
  exit 1
fi

COREPACK_HOME="$XDG_ROOT/corepack"
PNPM_STORE_DIR="$XDG_ROOT/pnpm/store"
mkdir -p "$COREPACK_HOME" "$PNPM_STORE_DIR"

export COREPACK_HOME

cd "$TOOLS_DIR"
corepack pnpm@11.18.0 install --frozen-lockfile --store-dir "$PNPM_STORE_DIR"
corepack pnpm@11.18.0 ignored-builds

for executable in pyright pyright-langserver
do
  if [ ! -x "$TOOLS_DIR/node_modules/.bin/$executable" ]; then
    printf '%s\n' "Error: falta el ejecutable $executable." >&2
    exit 1
  fi
done

"$TOOLS_DIR/node_modules/.bin/pyright" --version
printf '%s\n' "Pyright instalado en $TOOLS_DIR/node_modules/.bin"
