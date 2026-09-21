#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/rutas.sh"
. "$SCRIPT_DIR/lib/plataforma.sh"

sistema_auto=0
solo_comprobar=0
perfil=si

mostrar_logo() {
  if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then
    # Secuencia ANSI portable: limpiar pantalla y situar el cursor arriba.
    printf '\033[2J\033[H'
  fi

  cat <<'EOF'
██╗  ███████╗  ██╗
██║  ██╔════╝  ██║
██║  █████╗    ██║
██║  ██╔══╝    ██║
██║  ██║       ███████╗
╚═╝  ╚═╝       ╚══════╝

Entorno de desarrollo IFL para alumnado
Neovim · Node 24 · LSP por asignatura · tmux · búsqueda · IA opcional
EOF
}

uso() {
  cat <<'EOF'
Uso: scripts/instalar-alumno.sh [--perfil si|dwec] [--sistema] [--comprobar]

Prepara el entorno esencial del alumno: Neovim y Node locales verificados,
plugins, LSP del perfil elegido, busqueda, tmux e IA opcional. No instala PDF
ni las herramientas exclusivas del perfil completo del profesor.

  --perfil    si: Bash/Python; dwec: HTML/CSS/JSON/JavaScript/TypeScript
  --sistema    ofrece instalar con sudo solo los paquetes basicos que falten
  --comprobar  diagnostica sin descargar ni modificar nada
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --perfil)
      [ "$#" -ge 2 ] || { printf '%s\n' 'Error: falta el perfil.' >&2; exit 2; }
      perfil=$2
      shift
      ;;
    --sistema) sistema_auto=1 ;;
    --comprobar) solo_comprobar=1 ;;
    -h | --help) mostrar_logo; printf '\n'; uso; exit 0 ;;
    *) printf 'Error: opcion desconocida: %s\n' "$1" >&2; uso >&2; exit 2 ;;
  esac
  shift
done

case "$perfil" in
  si | dwec) ;;
  *) printf 'Error: perfil de alumno desconocido: %s (use si o dwec).\n' "$perfil" >&2; exit 2 ;;
esac

mostrar_logo
printf '\nEste instalador prepara el entorno dentro del repositorio y no sustituye\n'
printf '%s\n' 'tu configuración personal de Neovim, tmux o shell.'
if [ "$solo_comprobar" -eq 1 ]; then
  printf '\nModo: COMPROBACIÓN. Solo leerá el estado; no instalará nada.\n'
elif [ "$sistema_auto" -eq 1 ]; then
  printf '\nModo: INSTALACIÓN ASISTIDA.\n'
  printf '%s\n' '- Si faltan paquetes del sistema, mostrará el comando exacto.'
  printf '%s\n' '- Pedirá confirmación antes de usar sudo.'
  printf '%s\n' '- Después instalará herramientas locales con versiones fijadas.'
else
  printf '\nModo: INSTALACIÓN LOCAL, sin sudo.\n'
  printf '%s\n' 'Si falta algún paquete del sistema, se detendrá y mostrará cómo resolverlo.'
  printf '%s\n' 'Para permitir la instalación asistida de esos paquetes, ejecuta:'
  printf '  ./scripts/instalar-alumno.sh --perfil %s --sistema\n' "$perfil"
  printf '%s\n' 'Para diagnosticar sin modificar nada, ejecuta:'
  printf '  ./scripts/instalar-alumno.sh --perfil %s --comprobar\n' "$perfil"
fi
printf '\n'

[ "$(id -u)" -ne 0 ] || {
  printf '%s\n' "Error: no ejecutes este instalador como root." >&2
  exit 1
}

case "$ENTORNO_OS:$ENTORNO_ARCH" in
  Linux:x86_64) ;;
  *)
    printf 'Error: el instalador minimo auditado admite Linux x86_64; detectado %s %s.\n' \
      "$ENTORNO_OS" "$ENTORNO_ARCH" >&2
    exit 1
    ;;
esac

faltan=
herramientas='git tmux curl tar xz fzf rg'
[ "$perfil" = si ] && herramientas="$herramientas shellcheck"
for herramienta in $herramientas; do
  command -v "$herramienta" >/dev/null 2>&1 || faltan="$faltan $herramienta"
done
entorno_fd_bin >/dev/null 2>&1 || faltan="$faltan fd"
[ -s /etc/ssl/certs/ca-certificates.crt ] || faltan="$faltan ca-certificates"
faltan=${faltan# }

printf 'Entorno alumno - %s %s' "$ENTORNO_DISTRO" "$ENTORNO_ARCH"
[ "$ENTORNO_IS_WSL" = 1 ] && printf ' (WSL2)'
printf '\n'

if [ -n "$faltan" ]; then
  printf 'Faltan paquetes basicos: %s\n' "$faltan" >&2
  case "$ENTORNO_DISTRO" in
    debian | ubuntu | pop)
      paquetes=
      for herramienta in $faltan; do
        case "$herramienta" in
          fd) paquetes="$paquetes fd-find" ;;
          rg) paquetes="$paquetes ripgrep" ;;
          xz) paquetes="$paquetes xz-utils" ;;
          *) paquetes="$paquetes $herramienta" ;;
        esac
      done
      comando="sudo apt-get update && sudo apt-get install -y${paquetes} ca-certificates"
      ;;
    arch | cachyos | omarchy)
      paquetes=
      for herramienta in $faltan; do
        case "$herramienta" in rg) paquetes="$paquetes ripgrep" ;; *) paquetes="$paquetes $herramienta" ;; esac
      done
      comando="sudo pacman -S --needed${paquetes} ca-certificates"
      ;;
    *)
      printf '%s\n' "Instalalos con el gestor de paquetes de tu distribucion." >&2
      exit 1
      ;;
  esac

  printf 'Comando propuesto:\n  %s\n' "$comando"
  if [ "$solo_comprobar" -eq 1 ] || [ "$sistema_auto" -eq 0 ]; then
    printf '%s\n' "No se ha modificado el sistema. Usa --sistema para ejecutarlo con confirmacion." >&2
    exit 1
  fi

  case "$ENTORNO_DISTRO" in
    debian | ubuntu | pop)
      command -v apt-get >/dev/null 2>&1 || {
        printf '%s\n' 'Error: apt-get no esta disponible en esta instalacion Debian/Ubuntu.' >&2
        exit 1
      }
      command -v sudo >/dev/null 2>&1 || {
        printf '%s\n' 'Error: falta sudo. Pide al profesor o administrador que instale los paquetes mostrados.' >&2
        exit 1
      }
      ;;
  esac

  printf '¿Ejecutar este comando? [s/N]: '
  respuesta=
  if [ -r /dev/tty ]; then read -r respuesta < /dev/tty || respuesta=; fi
  case "$respuesta" in
    s | S | si | Si | SI) ;;
    *) printf '%s\n' "Cancelado. No se ha modificado el sistema." >&2; exit 1 ;;
  esac
  sh -c "$comando"
  for herramienta in $herramientas; do
    command -v "$herramienta" >/dev/null 2>&1 || {
      printf 'Error: %s sigue sin estar disponible.\n' "$herramienta" >&2
      exit 1
    }
  done
  entorno_fd_bin >/dev/null 2>&1 || { printf '%s\n' "Error: fd/fdfind sigue sin estar disponible." >&2; exit 1; }
  [ -s /etc/ssl/certs/ca-certificates.crt ] || {
    printf '%s\n' 'Error: siguen faltando los certificados TLS del sistema.' >&2
    exit 1
  }
fi

NVIM_LOCAL="$ENTORNO_TOOLS_ROOT/nvim-$ENTORNO_NVIM_VERSION/bin/nvim"
if [ -x "$NVIM_LOCAL" ]; then
  printf 'OK: Neovim local %s\n' "$NVIM_LOCAL"
elif [ "$solo_comprobar" -eq 1 ]; then
  printf 'FALTA: Neovim local; ejecuta ./scripts/instalar-alumno.sh\n' >&2
  exit 1
else
  "$SCRIPT_DIR/instalar-neovim.sh"
fi

version_instalada=$("$NVIM_LOCAL" --version | sed -n '1s/^NVIM v//p')
[ "$version_instalada" = "$ENTORNO_NVIM_VERSION" ] || {
  printf 'Error: se esperaba Neovim %s y se encontro %s.\n' \
    "$ENTORNO_NVIM_VERSION" "${version_instalada:-desconocido}" >&2
  exit 1
}

if [ "$solo_comprobar" -eq 0 ]; then
  "$SCRIPT_DIR/instalar-node.sh"
  if [ "$perfil" = dwec ]; then
    ENTORNO_SIN_FIXTURES=1 "$SCRIPT_DIR/instalar-lsp-web.sh"
  else
    "$SCRIPT_DIR/instalar-lsp-bash.sh"
    "$SCRIPT_DIR/instalar-lsp-python.sh"
  fi
fi

if [ "$solo_comprobar" -eq 1 ]; then
  plugins_faltan=0
  while IFS=' ' read -r plugin commit; do
    [ -n "$plugin" ] || continue
    actual=$(git -C "$PROJECT_ROOT/.xdg/$ENTORNO_NVIM_VERSION/data/nvim/lazy/$plugin" rev-parse HEAD 2>/dev/null || true)
    [ "$actual" = "$commit" ] || plugins_faltan=1
  done <<EOF
$(sed -n 's/^[[:space:]]*"\([^"]*\)":.*"commit": "\([0-9a-f]*\)".*/\1 \2/p' "$PROJECT_ROOT/nvim/lazy-lock.json")
EOF
  [ "$plugins_faltan" -eq 0 ] || {
    printf 'FALTA: plugins fijados; ejecuta ./scripts/instalar-alumno.sh\n' >&2
    exit 1
  }
  NODE_LOCAL=$(entorno_node_dir)/bin/node
  [ -x "$NODE_LOCAL" ] && [ "$("$NODE_LOCAL" --version)" = "v$ENTORNO_NODE_VERSION" ] \
    || { printf '%s\n' "FALTA: Node local verificado." >&2; exit 1; }
  if [ "$perfil" = dwec ]; then
    WEB_LSP_BIN="$PROJECT_ROOT/tools/lsp-web/node_modules/.bin"
    for ejecutable in typescript-language-server vscode-html-language-server \
      vscode-css-language-server vscode-json-language-server tailwindcss-language-server
    do
      [ -x "$WEB_LSP_BIN/$ejecutable" ] || {
        printf 'FALTA: servidor web %s.\n' "$ejecutable" >&2
        exit 1
      }
    done
  else
    BASHLS_LOCAL="$PROJECT_ROOT/tools/lsp-bash/node_modules/.bin/bash-language-server"
    PYRIGHT_LOCAL="$PROJECT_ROOT/tools/lsp-python/node_modules/.bin/pyright-langserver"
    [ -x "$BASHLS_LOCAL" ] || { printf '%s\n' "FALTA: Bash Language Server." >&2; exit 1; }
    [ -x "$PYRIGHT_LOCAL" ] || { printf '%s\n' "FALTA: Pyright." >&2; exit 1; }
  fi
  printf 'OK: perfil %s, tmux, busqueda, Node, Neovim, LSP y plugins preparados.\n' "$perfil"
  exit 0
fi

ENTORNO_PERFIL="$perfil" ENTORNO_IA=0 ENTORNO_SIN_LISTEN=1 NVIM_BIN="$NVIM_LOCAL" \
  "$SCRIPT_DIR/instalar-plugins.sh"
ENTORNO_PERFIL="$perfil" ENTORNO_IA=0 ENTORNO_SIN_LISTEN=1 NVIM_BIN="$NVIM_LOCAL" \
  "$SCRIPT_DIR/arrancar.sh" --headless "+lua print('OK: Neovim alumno arranca')" +qa
printf '\n'
"$SCRIPT_DIR/instalar-entorno-dev.sh"

path_preparado=0
case ":$PATH:" in
  *":$HOME/.local/bin:"*) path_preparado=1 ;;
esac

cat <<EOF

Instalacion esencial terminada. No se ha tocado ~/.config/nvim ni ~/.tmux.conf.

Para abrir el entorno del perfil $perfil sin IA:
  entorno-dev --perfil $perfil --sin-ia /ruta/al/proyecto

La IA solo se abrira si ya hay un cliente compatible instalado (Codex,
OpenCode, Claude, Pi o jarvis-coder). El instalador no instala ni configura
cuentas, tokens o credenciales.
EOF

if [ "$path_preparado" -eq 0 ]; then
  cat <<'EOF'

Tu shell actual todavia no incluye ~/.local/bin en PATH. Activalo ahora con:
  export PATH="$HOME/.local/bin:$PATH"

Despues podras ejecutar directamente `entorno-dev`. Las terminales nuevas de
Ubuntu suelen incorporar ~/.local/bin automaticamente una vez que existe.
EOF
fi
