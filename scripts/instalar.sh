#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"

[ "$(id -u)" -ne 0 ] || {
  printf '%s\n' "Error: no ejecutes este instalador como root." >&2
  exit 1
}

system=$(uname -s)
case "$system" in
  Linux)
    distro=linux
    if [ -r /etc/os-release ]; then
      distro=$(sed -n 's/^ID=//p' /etc/os-release | sed 's/^"//; s/"$//' | sed -n '1p')
    fi
    case "$distro" in
      debian | ubuntu)
        hint="sudo apt install git tmux fzf fd-find ripgrep lazygit pandoc chromium poppler-utils curl unzip build-essential"
        node_hint="Node >=24 <25 y Corepack deben proceder de una fuente aprobada; no se instala Node mediante un script remoto"
        ;;
      arch | cachyos)
        hint="sudo pacman -S git tmux fzf fd ripgrep lazygit nodejs corepack pandoc-cli chromium poppler curl unzip base-devel"
        node_hint="Node >=24 <25 y Corepack"
        ;;
      *)
        hint="instala Git, tmux, fzf, fd, ripgrep, lazygit, Pandoc, Chromium, curl, unzip y un compilador"
        node_hint="Node >=24 <25 y Corepack"
        ;;
    esac
    ;;
  Darwin)
    distro=macos
    hint="brew install git tmux fzf fd ripgrep lazygit node@24 corepack pandoc poppler; instala Chromium, Chrome o Brave si no dispones ya de uno"
    node_hint="Node >=24 <25 y Corepack"
    ;;
  *)
    printf 'Error: sistema no contemplado: %s\n' "$system" >&2
    exit 1
    ;;
esac

missing=
for dependency in git tmux fzf rg lazygit node corepack pandoc curl tar unzip; do
  command -v "$dependency" >/dev/null 2>&1 || missing="$missing $dependency"
done
if ! command -v fd >/dev/null 2>&1 && ! command -v fdfind >/dev/null 2>&1; then missing="$missing fd/fdfind"; fi
if ! command -v chromium >/dev/null 2>&1 && ! command -v google-chrome >/dev/null 2>&1 \
  && ! command -v brave-browser >/dev/null 2>&1 \
  && [ ! -x "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser" ] \
  && [ ! -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ] \
  && [ ! -x "/Applications/Chromium.app/Contents/MacOS/Chromium" ]; then missing="$missing Chromium/Chrome"; fi
if ! command -v cc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1; then missing="$missing compilador"; fi
if [ -n "$missing" ]; then
  printf 'Faltan herramientas de sistema:%s\n' "$missing" >&2
  printf '%s\n' "Comando orientativo para $distro:" "$hint" >&2
  printf 'Requisito de runtime: %s.\n' "$node_hint" >&2
  printf '%s\n' "No se ha ejecutado sudo ni se ha modificado el sistema." >&2
  exit 1
fi

compatible=$(node -p "const [a,b]=process.versions.node.split('.').map(Number); Number(a === $ENTORNO_NODE_MAJOR && b >= $ENTORNO_NODE_MIN_MINOR)")
[ "$compatible" = 1 ] || {
  printf 'Error: se requiere Node >=%s.%s <%s; encontrado %s.\n' \
    "$ENTORNO_NODE_MAJOR" "$ENTORNO_NODE_MIN_MINOR" "$((ENTORNO_NODE_MAJOR + 1))" "$(node --version)" >&2
  exit 1
}

if [ "$system" = Darwin ]; then
  NVIM_BIN=${NVIM_BIN:-"$(command -v nvim 2>/dev/null || true)"}
  LUALS_BIN=${LUALS_BIN:-"$(command -v lua-language-server 2>/dev/null || true)"}
  [ -n "$NVIM_BIN" ] || { printf '%s\n' "Error: Neovim no esta disponible en PATH." >&2; exit 1; }
  [ -n "$LUALS_BIN" ] || { printf '%s\n' "Error: LuaLS no esta disponible en PATH." >&2; exit 1; }
  [ -x "$NVIM_BIN" ] && [ "$("$NVIM_BIN" --version | sed -n '1s/^NVIM v//p')" = "$ENTORNO_NVIM_VERSION" ] || {
    printf 'Error: NVIM_BIN no corresponde a Neovim %s.\n' "$ENTORNO_NVIM_VERSION" >&2; exit 1;
  }
  [ -x "$LUALS_BIN" ] && [ "$("$LUALS_BIN" --version 2>/dev/null)" = "$ENTORNO_LUALS_VERSION" ] || {
    printf 'Error: LUALS_BIN no corresponde a LuaLS %s.\n' "$ENTORNO_LUALS_VERSION" >&2; exit 1;
  }
else
  "$SCRIPT_DIR/instalar-neovim.sh"
  "$SCRIPT_DIR/instalar-luals.sh"
fi
"$SCRIPT_DIR/instalar-tree-sitter.sh"
"$SCRIPT_DIR/instalar-lsp-web.sh"
"$SCRIPT_DIR/instalar-lsp-python.sh"
"$SCRIPT_DIR/instalar-plugins.sh"
"$SCRIPT_DIR/instalar-parsers.sh"
"$SCRIPT_DIR/comprobar-requisitos.sh"

printf '\n%s\n' "Instalacion de usuario preparada. No se ha activado ~/.config/nvim."
printf '%s\n' "Prueba con ./scripts/arrancar.sh y activa despues con ./scripts/activar.sh."
