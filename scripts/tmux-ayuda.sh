#!/bin/sh
set -eu

fail() {
  tmux display-message -t "${origin_pane:-}" "Error: $*" 2>/dev/null || :
  exit 1
}

clean_label() {
  printf '%s' "$1" | LC_ALL=C tr -d '\000-\037\177' | sed 's/[|]/-/g' | cut -c 1-32
}

detect_context() {
  context_pane=$1
  context_window=$(tmux display-message -p -t "$context_pane" '#{window_id}' 2>/dev/null) || return 1
  window_role=$(tmux show-option -w -v -t "$context_window" @entorno_window_role 2>/dev/null || true)
  pane_role=$(tmux show-option -p -v -t "$context_pane" @entorno_role 2>/dev/null || true)
  if [ "$window_role" = git ]; then
    printf '%s\n' git
    return
  fi
  case "$pane_role" in
    editor | terminal) printf '%s\n' "$pane_role" ;;
    agent)
      active_agent=$(tmux show-option -p -v -t "$context_pane" @entorno_agent 2>/dev/null || true)
      if [ -n "$active_agent" ]; then
        printf 'agent/%s\n' "$active_agent"
      else
        printf '%s\n' agent
      fi
      ;;
    *) printf '%s\n' general ;;
  esac
}

category_rows() {
  case "${ENTORNO_HELP_CONTEXT:-general}" in
    editor) contextual=EDITOR ;;
    agent*) contextual=AI ;;
    terminal) contextual=TERMINAL ;;
    git) contextual=GIT ;;
    *) contextual=WORKSPACE ;;
  esac
  for category in FLOW "$contextual" EDITOR AI WORKSPACE GIT TERMINAL NAVIGATION CONFIG; do
    case " ${seen:-} " in *" $category "*) continue ;; esac
    seen="${seen:-} $category"
    case "$category" in
      FLOW) label='FLUJO DIARIO'; description='Ciclo habitual de trabajo' ;;
      EDITOR) label='EDITOR'; description='Edicion, busqueda, LSP y modos' ;;
      AI) label='INTELIGENCIA ARTIFICIAL'; description='Agentes, selector y contexto' ;;
      WORKSPACE) label='TMUX / ESPACIO DE TRABAJO'; description='Paneles, ventanas y proyectos' ;;
      GIT) label='GIT'; description='Lazygit, estado y cambios' ;;
      TERMINAL) label='TERMINAL'; description='Herramientas de desarrollo' ;;
      NAVIGATION) label='NAVEGACION'; description='Paneles, splits y tamanos' ;;
      CONFIG) label='CONFIGURACION'; description='Temas, interfaz y diagnostico' ;;
    esac
    printf '%-29s %s\t%s\n' "$label" "$description" "$category"
  done
}

availability() {
  if command -v "$1" >/dev/null 2>&1; then printf '%s' '[OK]'; else printf '%s' '[--]'; fi
}

action_rows() {
  case "$1" in
    FLOW)
      printf '%s\n' \
        'EDITAR' \
        'PREFIX n        Ir al editor' \
        'SPACE ff        Abrir un archivo' \
        'SPACE fg        Buscar texto' \
        'SPACE w         Guardar' \
        'CONSULTAR IA' \
        'SPACE ac        Preparar y pegar contexto' \
        'revisar         Comprobar el texto generado' \
        'Enter           Enviar manualmente' \
        'PREFIX a / i    Agente activo / selector' \
        'REVISAR CAMBIOS' \
        'PREFIX g        Abrir lazygit' \
        'status / diff   Revisar cambios' \
        'PREFIX n        Volver al editor'
      ;;
    EDITOR)
      printf '%s\n' \
        'BUSCAR Y EXPLORAR' \
        'SPACE ff / fg   Archivos / texto del proyecto' \
        'SPACE fb        Buffers abiertos' \
        'dashboard r     Archivos recientes' \
        'SPACE ee / ef   Explorador / enfocar archivo' \
        'ARCHIVO Y CODIGO' \
        'SPACE w / q     Guardar / cerrar ventana' \
        'SPACE d         Duplicar linea' \
        'ALT-SHIFT j/k   Mover linea o seleccion (Linux)' \
        'CMD-SHIFT arriba/abajo  Mover linea o seleccion (macOS)' \
        'gd / gD         Definicion / declaracion' \
        'SPACE lf        Formatear buffer' \
        '[d / ]d         Diagnostico anterior / siguiente' \
        'SPACE e         Abrir explorador' \
        'SPACE l d       Mostrar diagnostico' \
        'MODOS BASICOS' \
        'i / a / o       Insertar / anadir / nueva linea' \
        'v / V           Seleccion visual / por lineas' \
        'Esc o jk        Volver al modo normal' \
        'MOVIMIENTO BASICO' \
        'h j k l         Izquierda, abajo, arriba, derecha' \
        'w / b / e       Palabra siguiente / anterior / final' \
        'gg / G          Inicio / final del archivo' \
        '0 / $           Inicio / final de linea' \
        'INTEGRACIONES' \
        'SPACE gg / ac   Lazygit / enviar contexto IA'
      ;;
    AI)
      printf '%s\n' \
        'AGENTES' \
        "Codex           $(availability codex)" \
        "OpenCode        $(availability opencode)" \
        "Claude          $(availability claude)" \
        "Pi              $(availability pi)" \
        'Shell           [OK]' \
        'CONTROL' \
        'PREFIX i        Abrir selector de agentes' \
        'PREFIX a        Ir al agente activo' \
        'PREFIX n        Volver al editor' \
        'ENVIAR CONTEXTO' \
        'SPACE ac        Preparar contexto desde Neovim' \
        'Normal          Archivo, linea y posicion' \
        'Visual          Seleccion y metadatos' \
        'revisar         Comprobar el texto pegado' \
        'Enter           Enviar manualmente' \
        'SEGURIDAD' \
        'No envia Enter automaticamente' \
        'Solo admite paneles y procesos autorizados'
      ;;
    WORKSPACE)
      printf '%s\n' \
        'PREFIX = CTRL-a' \
        'PANELES POR FUNCION' \
        'PREFIX n / a / t  Editor / agente / terminal' \
        'PREFIX i / g      Selector IA / lazygit' \
        'PANELES Y VENTANAS' \
        'PREFIX | / -      Dividir horizontal / vertical' \
        'PREFIX z          Maximizar o restaurar' \
        'PREFIX c / p / w  Crear / anterior / elegir ventana' \
        'PREFIX 0-9        Ir a ventana por indice' \
        'SESIONES Y PROYECTOS' \
        'PREFIX s / d      Elegir / separar sesion' \
        'PREFIX P          Selector de proyectos' \
        'entorno-dev ruta  Abrir otra carpeta' \
        'ENTORNO' \
        'PREFIX ?          Abrir esta ayuda' \
        'PREFIX [          Modo copia' \
        'PREFIX CTRL-a     Enviar prefijo literal'
      ;;
    GIT)
      printf '%s\n' \
        'LAZYGIT' \
        'PREFIX g        Abrir o recuperar lazygit' \
        'SPACE gg        Abrir desde el editor' \
        'q / ?           Cerrar / ayuda de lazygit' \
        'REVISAR' \
        'git status --short   Estado resumido' \
        'git diff             Cambios locales' \
        'git diff --staged    Cambios preparados' \
        'git diff --check     Errores de espacios' \
        'git log --oneline    Historial reciente' \
        'FLUJO' \
        'editar > revisar > preparar > confirmar' \
        'PREFIX n        Volver al editor'
      ;;
    TERMINAL)
      printf '%s\n' \
        'PROYECTO' \
        'PREFIX t        Ir al terminal' \
        'git / rg / fd   Git, buscar texto o archivos' \
        'JAVASCRIPT' \
        'pnpm / npm      Dependencias y scripts' \
        'pnpm test       Ejecutar pruebas del proyecto' \
        'CONTENEDORES' \
        'docker ps       Ver contenedores' \
        'docker compose up    Arrancar servicios' \
        'docker compose logs  Consultar registros' \
        'REMOTO' \
        'ssh host        Conectar a un servidor' \
        'Ctrl-d          Cerrar shell o conexion' \
        'PREFIX CTRL-a   Prefijo para tmux remoto' \
        'ENTORNO-NVIM' \
        'PREFIX n / a / g  Editor / agente / lazygit'
      ;;
    NAVIGATION)
      printf '%s\n' \
        'PANELES TMUX' \
        'PREFIX h / j     Izquierda / abajo' \
        'PREFIX k / l     Arriba / derecha' \
        'REDIMENSIONAR' \
        'PREFIX H/J/K/L   Izquierda/abajo/arriba/derecha' \
        'PREFIX z         Maximizar o restaurar' \
        'SPLITS DEL EDITOR' \
        'CTRL-h / CTRL-j  Izquierda / abajo' \
        'CTRL-k / CTRL-l  Arriba / derecha' \
        'DESTINOS DIRECTOS' \
        'PREFIX n / a / t Editor / agente / terminal' \
        'PREFIX g         Git'
      ;;
    CONFIG)
      printf '%s\n' \
        'APARIENCIA DEL EDITOR' \
        'SPACE ut        Elegir tema visual' \
        '                Catppuccin / Tokyo Night / Kanagawa' \
        'SPACE ul        Mostrar caracteres invisibles' \
        'clipboard       Integrado con el portapapeles del sistema' \
        'DIAGNOSTICO' \
        ':checkhealth    Revisar salud de Neovim' \
        ':Lazy           Revisar plugins instalados' \
        'ENTORNO' \
        ':IFL            Volver al dashboard' \
        'PREFIX ?        Abrir esta ayuda' \
        'Los cambios persistentes se mantienen en el repositorio'
      ;;
    *) return 1 ;;
  esac
}

header() {
  printf 'ENTORNO-NVIM\nProyecto: %s\nContexto: %s\nPREFIX = CTRL-a   SPACE = leader Neovim' \
    "$(clean_label "${ENTORNO_HELP_PROJECT:-sin proyecto}")" \
    "${ENTORNO_HELP_CONTEXT:-general}"
}

fzf_select() {
  prompt=$1
  help_text=$2
  level=${3:-root}
  bindings='q:print(__quit__)+accept'
  [ "$level" = actions ] && bindings='q:print(__quit__)+accept,enter:ignore'
  if fzf --help 2>/dev/null | grep -q -- '--footer='; then
    fzf --no-sort --layout=reverse --delimiter='\t' --with-nth=1 \
      --header="$(header)" --header-first --footer="$help_text" \
      --footer-border=none --info=hidden --no-separator --no-scrollbar \
      --gutter=' ' --pointer='>' --prompt="$prompt" \
      --bind="$bindings"
  else
    fallback_header=$(printf '%s\n\n%s' "$(header)" "$help_text")
    fzf --no-sort --layout=reverse --delimiter='\t' --with-nth=1 \
      --header="$fallback_header" --info=hidden \
      --pointer='>' --prompt="$prompt" --bind="$bindings"
  fi
}

run_fzf() {
  while :; do
    selected=$(category_rows | fzf_select 'Categoria> ' 'Enter abrir   Esc/q cerrar') || return 0
    [ "$selected" = __quit__ ] && return 0
    category=${selected#*	}
    selected=$(action_rows "$category" | sed 's/$/\tinfo/' |
      fzf_select "$category> " 'Esc volver   q cerrar' actions) || continue
    [ "$selected" = __quit__ ] && return 0
  done
}

run_posix() {
  escape=$(printf '\033')
  while :; do
    clear 2>/dev/null || printf '\033[2J\033[H'
    header
    printf '\n\nCATEGORIAS\n\n'
    category_rows | awk -F '\t' '{ printf "  %s\n", $1 }'
    printf '\n[f] Flujo [e] Editor [i] IA [w] Tmux [g] Git [t] Terminal [n] Navegacion [c] Config\n'
    printf 'Pulsa categoria; Esc/q cierra: '
    choice=$(read_key) || return 0
    case "$choice" in
      f | F) category=FLOW ;; e | E) category=EDITOR ;;
      i | I) category=AI ;; w | W) category=WORKSPACE ;;
      g | G) category=GIT ;; t | T) category=TERMINAL ;;
      n | N) category=NAVIGATION ;; c | C) category=CONFIG ;;
      q | Q | "$escape") return 0 ;; *) continue ;;
    esac
    clear 2>/dev/null || printf '\033[2J\033[H'
    printf 'ENTORNO-NVIM > %s\nProyecto: %s\n\n' "$category" \
      "$(clean_label "${ENTORNO_HELP_PROJECT:-sin proyecto}")"
    action_rows "$category"
    printf '\nEnter/Esc volver; q cerrar'
    choice=$(read_key) || return 0
    case "$choice" in q | Q) return 0 ;; esac
  done
}

read_key() {
  saved_stty=$(stty -g 2>/dev/null) || return 1
  trap 'stty "$saved_stty" 2>/dev/null || :; exit 0' HUP INT TERM
  stty -echo -icanon min 1 time 0
  key=$(dd bs=1 count=1 2>/dev/null) || key=
  stty "$saved_stty"
  trap - HUP INT TERM
  printf '%s' "$key"
}

run_interface() {
  if command -v fzf >/dev/null 2>&1 && [ -t 0 ] && [ -t 2 ]; then
    run_fzf
  else
    run_posix
  fi
}

case "${1:-}" in
  --categories) category_rows; exit 0 ;;
  --actions) [ "$#" -eq 2 ] || exit 2; action_rows "$2"; exit $? ;;
  --interface) [ "$#" -eq 1 ] || exit 2; run_interface; exit 0 ;;
  --context) [ "$#" -eq 2 ] || exit 2; detect_context "$2"; exit $? ;;
esac

[ "$#" -eq 2 ] || fail "uso interno: tmux-ayuda.sh cliente pane"
target_client=$1
origin_pane=$2
target_session=$(tmux display-message -p -t "$origin_pane" '#{session_id}' 2>/dev/null) ||
  fail "no se pudo identificar la sesion actual"
context=$(detect_context "$origin_pane") || fail "no se pudo detectar el contexto actual"

project=$(tmux show-option -v -t "$target_session" @entorno_project_name 2>/dev/null || true)
[ -n "$project" ] || project=${target_session#\$}
root_entry=$(tmux show-environment -t "$target_session" ENTORNO_NVIM_ROOT 2>/dev/null) ||
  fail "tmux no conoce ENTORNO_NVIM_ROOT para esta sesion"
case "$root_entry" in
  ENTORNO_NVIM_ROOT=*) project_root=${root_entry#*=} ;;
  *) fail "ENTORNO_NVIM_ROOT no es valida en esta sesion" ;;
esac
[ -x "$project_root/scripts/tmux-ayuda.sh" ] || fail "no se encuentra el helper de ayuda"

tmux display-popup -E -b rounded -w 76% -h 78% \
  -c "$target_client" \
  -t "$origin_pane" \
  -e "ENTORNO_HELP_PROJECT=$(clean_label "$project")" \
  -e "ENTORNO_HELP_CONTEXT=$context" \
  -e "ENTORNO_NVIM_ROOT=$project_root" \
  'exec "$ENTORNO_NVIM_ROOT/scripts/tmux-ayuda.sh" --interface' 2>/dev/null || :
exit 0
