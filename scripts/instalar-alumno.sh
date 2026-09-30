#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd "$(dirname "$0")" && pwd)
PROJECT_ROOT=$(dirname "$SCRIPT_DIR")
. "$SCRIPT_DIR/lib/versiones.sh"
. "$SCRIPT_DIR/lib/rutas.sh"
. "$SCRIPT_DIR/lib/plataforma.sh"
. "$SCRIPT_DIR/lib/resumen-instalacion.sh"
entorno_fase_actual="opciones y requisitos"

# preguntar: si faltan paquetes y hay terminal, se ofrece instalarlos.
# si: igual, pero explicito (--sistema). no: nunca usa sudo (--sin-sistema).
sistema=preguntar
inicio_sin_pausa=0
solo_comprobar=0
perfil=
# Perfil de la ultima instalacion: lo reutilizan este instalador y entorno-dev.
PERFIL_GUARDADO=${ENTORNO_PERFIL_GUARDADO:-"$PROJECT_ROOT/.xdg/perfil-alumno"}

mostrar_logo() {
  entorno_banner "Instalación para alumnado"
}

uso() {
  cat <<'EOF'
USO RÁPIDO
  ./scripts/instalar-alumno.sh

  Te preguntará tu asignatura (DWEC o SI) y, si faltan programas del
  sistema, te ofrecerá instalarlos. La próxima vez recordará tu elección:
  para actualizar basta con repetir el mismo comando y pulsar Enter.

PERFILES
  dwec   Desarrollo web: HTML, CSS, JavaScript, TypeScript y React
  si     Sistemas: Bash y Python

OPCIONES (no son obligatorias)
  --perfil dwec|si   elige el perfil sin preguntar (también: ... dwec)
  --comprobar        solo revisa la instalación; no descarga ni cambia nada
  --sin-sistema      no instala paquetes del sistema ni usa sudo
  --sistema          acepta la opción antigua; equivale al comportamiento normal
  -y, --yes          empieza sin pedir Enter (no autoriza sudo)
  -h, --help         muestra esta ayuda

DESPUÉS DE INSTALAR
  cd /ruta/a/mi-proyecto
  entorno-dev .

Instalación completa del profesor (Markdown/PDF): ./scripts/instalar.sh
Más ayuda: docs/alumno.md
EOF
}

normalizar_perfil() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    dwec | web | 1) printf '%s\n' dwec ;;
    si | sistemas | 2) printf '%s\n' si ;;
    *) return 1 ;;
  esac
}

nombre_perfil() {
  case "$1" in
    dwec) printf '%s\n' 'DWEC (desarrollo web)' ;;
    si) printf '%s\n' 'SI (Bash y Python)' ;;
  esac
}

error_uso() {
  printf '\nError: %s\n' "$1" >&2
  printf '%s\n' 'Lo más sencillo es ejecutar sin opciones y responder a las preguntas:' \
    '  ./scripts/instalar-alumno.sh' 'Ayuda: ./scripts/instalar-alumno.sh --help' >&2
  exit 2
}

elegir_perfil() {
  printf '%s\n\n' '¿Para qué asignatura preparas el entorno?'
  printf '%s\n' '  1) DWEC   Desarrollo web: HTML, CSS, JavaScript, TypeScript y React'
  printf '%s\n\n' '  2) SI     Sistemas: Bash y Python'
  while :; do
    if [ -n "$1" ]; then
      printf 'Escribe 1 o 2 y pulsa Enter [Enter = %s, tu última elección]: ' "$1"
    else
      printf '%s' 'Escribe 1 o 2 y pulsa Enter: '
    fi
    IFS= read -r respuesta || return 1
    if [ -z "$respuesta" ] && [ -n "$1" ]; then
      perfil=$1
      return 0
    fi
    perfil=$(normalizar_perfil "$respuesta") && return 0
    printf '%s\n' 'Respuesta no válida: escribe 1 (DWEC) o 2 (SI).'
  done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --perfil)
      [ "$#" -ge 2 ] || error_uso 'falta el nombre del perfil después de --perfil (dwec o si).'
      perfil=$(normalizar_perfil "$2") || error_uso "perfil desconocido: $2 (usa dwec o si)."
      shift
      ;;
    --perfil=*)
      perfil=$(normalizar_perfil "${1#--perfil=}") || error_uso "perfil desconocido: ${1#--perfil=} (usa dwec o si)."
      ;;
    dwec | DWEC | si | SI | web | sistemas) perfil=$(normalizar_perfil "$1") ;;
    --sistema) sistema=si ;;
    --sin-sistema) sistema=no ;;
    -y | --yes) inicio_sin_pausa=1 ;;
    --comprobar) solo_comprobar=1 ;;
    -h | --help | --ayuda) mostrar_logo; uso; exit 0 ;;
    *) error_uso "opción desconocida: $1" ;;
  esac
  shift
done

[ "$(id -u)" -ne 0 ] || {
  printf '%s\n' 'Error: no ejecutes este instalador como root ni con sudo.' \
    'Ejecútalo como tu usuario normal: ./scripts/instalar-alumno.sh' \
    'Si hace falta sudo para algún paquete, el instalador te lo pedirá.' >&2
  exit 1
}

case "$ENTORNO_OS:$ENTORNO_ARCH" in
  Linux:x86_64) ;;
  *)
    printf 'Error: el instalador de alumnado admite Linux x86_64; detectado %s %s.\n' \
      "$ENTORNO_OS" "$ENTORNO_ARCH" >&2
    exit 1
    ;;
esac

# Los errores de uso ya se explican solos; desde aqui se resume cualquier fallo.
trap entorno_instalacion_salida 0
mostrar_logo

guardado=
if [ -r "$PERFIL_GUARDADO" ]; then
  guardado=$(normalizar_perfil "$(sed -n '1p' "$PERFIL_GUARDADO")") || guardado=
fi
if [ -z "$perfil" ]; then
  if [ -t 0 ]; then
    elegir_perfil "$guardado" || exit 1
  elif [ -n "$guardado" ]; then
    perfil=$guardado
  else
    error_uso 'falta el perfil y no hay terminal para preguntarlo. Usa --perfil dwec o --perfil si.'
  fi
fi

printf '\nPerfil: %s\n' "$(nombre_perfil "$perfil")"
printf 'Sistema: %s %s' "$ENTORNO_DISTRO" "$ENTORNO_ARCH"
[ "$ENTORNO_IS_WSL" = 1 ] && printf ' (WSL2)'
printf '\n'

if [ "$solo_comprobar" -eq 1 ]; then
  printf '\n%s\n' 'Modo COMPROBACIÓN: solo se revisa el estado; no se instala nada.'
else
  printf '\n%s\n' 'QUÉ VA A PASAR'
  printf '%s\n' \
    '  1. Se revisan los programas del sistema necesarios (git, tmux, fzf...).' \
    '  2. Se descargan Neovim, Node, plugins y servidores de lenguaje dentro de' \
    '     esta carpeta, con versiones fijadas y verificadas.' \
    '  3. Se prepara el comando entorno-dev para abrir tus proyectos.'
  case "$sistema" in
    no) printf '%s\n' '  Con --sin-sistema: si falta algún programa, se indicará cómo instalarlo.' ;;
    *) printf '%s\n' '  Si falta algún programa del sistema, se te preguntará antes de instalarlo.' ;;
  esac
  printf '%s\n' '  No cambia tu Neovim ni tu tmux habituales.'
  if [ "$inicio_sin_pausa" -eq 0 ]; then
    [ -t 0 ] || error_uso 'no hay terminal para confirmar. Usa --yes para empezar sin pausa.'
    printf '\n%s' 'Pulsa Enter para comenzar (Ctrl+C cancela): '
    IFS= read -r inicio_respuesta || exit 1
    if [ -n "$inicio_respuesta" ]; then
      printf '%s\n' 'Cancelado: solo Enter confirma el inicio.'
      exit 0
    fi
  fi
  mkdir -p "$(dirname "$PERFIL_GUARDADO")"
  printf '%s\n' "$perfil" > "$PERFIL_GUARDADO"
fi

herramientas='git tmux curl tar xz fzf rg'
[ "$perfil" = si ] && herramientas="$herramientas shellcheck"
faltan=
for herramienta in $herramientas; do
  command -v "$herramienta" >/dev/null 2>&1 || faltan="$faltan $herramienta"
done
entorno_fd_bin >/dev/null 2>&1 || faltan="$faltan fd"
[ -s /etc/ssl/certs/ca-certificates.crt ] || faltan="$faltan ca-certificates"
faltan=${faltan# }

if [ -n "$faltan" ]; then
  entorno_fase "Programas del sistema"
  printf 'Faltan estos programas del sistema: %s\n' "$faltan"
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
      printf '%s\n' 'Instálalos con el gestor de paquetes de tu distribución y repite:' \
        '  ./scripts/instalar-alumno.sh' >&2
      exit 1
      ;;
  esac

  printf 'Comando para instalarlos:\n  %s\n' "$comando"
  if [ "$solo_comprobar" -eq 1 ] || [ "$sistema" = no ] || [ ! -r /dev/tty ] \
    || { [ "$sistema" = preguntar ] && [ ! -t 0 ]; }; then
    printf '\n%s\n' 'No se ha modificado el sistema.' >&2
    printf '%s\n' 'Ejecuta ese comando (o pide ayuda al profesor) y repite:' \
      '  ./scripts/instalar-alumno.sh' >&2
    exit 1
  fi

  case "$ENTORNO_DISTRO" in
    debian | ubuntu | pop)
      command -v apt-get >/dev/null 2>&1 || {
        printf '%s\n' 'Error: apt-get no está disponible en esta instalación Debian/Ubuntu.' >&2
        exit 1
      }
      command -v sudo >/dev/null 2>&1 || {
        printf '%s\n' 'Error: falta sudo. Pide al profesor o administrador que instale los paquetes mostrados.' >&2
        exit 1
      }
      ;;
  esac

  printf '\n%s\n' '¿Instalarlos ahora? Se te pedirá tu contraseña de Linux (sudo).'
  printf '%s' 'Enter o s = sí; n = no: '
  respuesta=
  if [ -t 0 ]; then
    read -r respuesta || respuesta=n
  else
    read -r respuesta < /dev/tty 2>/dev/null || respuesta=n
  fi
  case "$respuesta" in
    '' | s | S | si | Si | SI | sí | Sí | y | Y) ;;
    *)
      printf '%s\n' 'No se ha modificado el sistema. Cuando los instales, repite:' \
        '  ./scripts/instalar-alumno.sh' >&2
      exit 1
      ;;
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

entorno_fase "Neovim local"
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
  entorno_fase "Node y servidores del perfil"
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

entorno_fase "Plugins fijados"
ENTORNO_PERFIL="$perfil" ENTORNO_IA=0 ENTORNO_SIN_LISTEN=1 NVIM_BIN="$NVIM_LOCAL" \
  "$SCRIPT_DIR/instalar-plugins.sh"
entorno_fase "Arranque de Neovim"
ENTORNO_PERFIL="$perfil" ENTORNO_IA=0 ENTORNO_SIN_LISTEN=1 NVIM_BIN="$NVIM_LOCAL" \
  "$SCRIPT_DIR/arrancar.sh" --headless "+lua print('OK: Neovim alumno arranca')" +qa
printf '\n'
entorno_fase "Lanzador entorno-dev"
entorno_lanzador_ok=1
"$SCRIPT_DIR/instalar-entorno-dev.sh" || entorno_lanzador_ok=0

path_preparado=0
case ":$PATH:" in
  *":$HOME/.local/bin:"*) path_preparado=1 ;;
esac

entorno_resumen_instalacion "$perfil" alumnado

if [ "$path_preparado" -eq 0 ]; then
  cat <<'EOF'

Tu shell actual todavia no incluye ~/.local/bin en PATH. Activalo ahora con:
  export PATH="$HOME/.local/bin:$PATH"

Despues podras ejecutar directamente `entorno-dev`. Las terminales nuevas de
Ubuntu suelen incorporar ~/.local/bin automaticamente una vez que existe.
EOF
fi

# Consentimiento separado: --yes no autoriza cambiar la shell.
sh "$SCRIPT_DIR/configurar-path.sh"
