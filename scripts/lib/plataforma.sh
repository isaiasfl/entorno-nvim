#!/bin/sh
# Fuente unica de deteccion de plataforma.
# Requiere versiones.sh (ENTORNO_NODE_VERSION y checksums). Exporta:
#   ENTORNO_OS, ENTORNO_ARCH, ENTORNO_DISTRO, ENTORNO_IS_WSL,
#   ENTORNO_NODE_PLATFORM, ENTORNO_NODE_ARCHIVE_EXT
# No descarga ni modifica nada.

ENTORNO_OS=$(uname -s)
ENTORNO_ARCH=$(uname -m)
ENTORNO_IS_WSL=0
ENTORNO_DISTRO=unknown

case "$ENTORNO_OS" in
  Linux)
    if [ -r /proc/version ] && grep -qi microsoft /proc/version 2>/dev/null; then
      ENTORNO_IS_WSL=1
    fi
    if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ]; then
      ENTORNO_IS_WSL=1
    fi
    if [ -r /etc/os-release ]; then
      ENTORNO_DISTRO=$(sed -n 's/^ID=//p' /etc/os-release | sed 's/^"//; s/"$//' | sed -n '1p')
    fi
    ;;
  Darwin)
    ENTORNO_DISTRO=macos
    ;;
esac
[ -n "$ENTORNO_DISTRO" ] || ENTORNO_DISTRO=unknown

case "$ENTORNO_OS:$ENTORNO_ARCH" in
  Linux:x86_64) ENTORNO_NODE_PLATFORM=linux-x64 ;;
  Linux:aarch64 | Linux:arm64) ENTORNO_NODE_PLATFORM=linux-arm64 ;;
  Darwin:arm64) ENTORNO_NODE_PLATFORM=darwin-arm64 ;;
  Darwin:x86_64) ENTORNO_NODE_PLATFORM=darwin-x64 ;;
  *) ENTORNO_NODE_PLATFORM= ;;
esac

case "$ENTORNO_NODE_PLATFORM" in
  darwin-*) ENTORNO_NODE_ARCHIVE_EXT=.tar.gz ;;
  '') ENTORNO_NODE_ARCHIVE_EXT= ;;
  *) ENTORNO_NODE_ARCHIVE_EXT=.tar.xz ;;
esac

export ENTORNO_OS ENTORNO_ARCH ENTORNO_DISTRO ENTORNO_IS_WSL
export ENTORNO_NODE_PLATFORM ENTORNO_NODE_ARCHIVE_EXT

# Los nombres de paquetes difieren entre Debian (fdfind) y Arch (fd).
entorno_fd_bin() {
  if command -v fd >/dev/null 2>&1; then
    printf '%s\n' fd
  elif command -v fdfind >/dev/null 2>&1; then
    printf '%s\n' fdfind
  else
    return 1
  fi
}

entorno_hint_sistema() {
  case "$ENTORNO_DISTRO" in
    debian | ubuntu)
      printf '%s\n' "sudo apt install git tmux fzf fd-find ripgrep lazygit chromium poppler-utils curl unzip build-essential (Pandoc es opcional para PDF)"
      ;;
    arch | cachyos | omarchy)
      printf '%s\n' "sudo pacman -S git tmux fzf fd ripgrep lazygit chromium poppler curl unzip base-devel (Pandoc es opcional para PDF)"
      ;;
    macos)
      printf '%s\n' "brew install git tmux fzf fd ripgrep lazygit poppler; instala Chromium, Chrome o Brave si no dispones de uno (Pandoc es opcional para PDF)"
      ;;
    *)
      printf '%s\n' "instala Git, tmux, fzf, fd, ripgrep, lazygit, Chromium, curl, unzip y un compilador; Pandoc es opcional para PDF"
      ;;
  esac
}

# Node vendorizado en .tools/: rutas y preferencia de PATH.
entorno_node_dir() {
  [ -n "${ENTORNO_NODE_PLATFORM:-}" ] || return 1
  [ -n "${ENTORNO_TOOLS_ROOT:-}" ] || return 1
  printf '%s/node-%s-%s\n' "$ENTORNO_TOOLS_ROOT" "$ENTORNO_NODE_VERSION" "$ENTORNO_NODE_PLATFORM"
}

entorno_node_bin_dir() {
  directory=$(entorno_node_dir) || return 1
  [ -x "$directory/bin/node" ] || return 1
  printf '%s\n' "$directory/bin"
}

# Si existe el Node vendorizado, lo antepone al PATH. Si no, no hace nada y se
# conserva el Node del sistema.
entorno_preferir_node_vendor() {
  directory=$(entorno_node_bin_dir) || return 0
  case ":$PATH:" in
    *":$directory:"*) ;;
    *) PATH="$directory:$PATH" ;;
  esac
  export PATH
}

entorno_node_archive() {
  [ -n "${ENTORNO_NODE_PLATFORM:-}" ] || return 1
  printf 'node-v%s-%s%s\n' "$ENTORNO_NODE_VERSION" "$ENTORNO_NODE_PLATFORM" "$ENTORNO_NODE_ARCHIVE_EXT"
}

entorno_node_checksum() {
  case "${ENTORNO_NODE_PLATFORM:-}" in
    linux-x64) printf '%s\n' "$ENTORNO_NODE_LINUX_X64_SHA256" ;;
    linux-arm64) printf '%s\n' "$ENTORNO_NODE_LINUX_ARM64_SHA256" ;;
    darwin-arm64) printf '%s\n' "$ENTORNO_NODE_DARWIN_ARM64_SHA256" ;;
    darwin-x64) printf '%s\n' "$ENTORNO_NODE_DARWIN_X64_SHA256" ;;
    *) return 1 ;;
  esac
}

# Traduce una clave logica (git, fd, compilador...) al paquete de la
# distribucion. Devuelve vacio si la distribucion no lo empaqueta aparte.
entorno_paquete_sistema() {
  clave=$1
  case "$ENTORNO_DISTRO" in
    debian | ubuntu)
      case "$clave" in
        fd) printf 'fd-find' ;;
        compilador) printf 'build-essential' ;;
        navegador) printf 'chromium' ;;
        poppler) printf 'poppler-utils' ;;
        visor) printf 'xdg-utils' ;;
        *) printf '%s' "$clave" ;;
      esac
      ;;
    arch | cachyos | omarchy)
      case "$clave" in
        compilador) printf 'base-devel' ;;
        navegador) printf 'chromium' ;;
        poppler) printf 'poppler' ;;
        visor) printf 'xdg-utils' ;;
        *) printf '%s' "$clave" ;;
      esac
      ;;
    macos)
      case "$clave" in
        compilador | navegador | visor) printf '' ;;
        *) printf '%s' "$clave" ;;
      esac
      ;;
    *) printf '%s' "$clave" ;;
  esac
}

entorno_comando_sistema() {
  case "$ENTORNO_DISTRO" in
    debian | ubuntu) printf 'sudo apt install %s\n' "$*" ;;
    arch | cachyos | omarchy) printf 'sudo pacman -S %s\n' "$*" ;;
    macos) printf 'brew install %s\n' "$*" ;;
    *) printf 'instala manualmente: %s\n' "$*" ;;
  esac
}
