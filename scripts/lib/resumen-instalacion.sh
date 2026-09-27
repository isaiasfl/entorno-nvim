#!/bin/sh
entorno_color_reset= entorno_color_ok= entorno_color_aviso= entorno_color_error=
if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ] && [ -z "${NO_COLOR:-}" ]; then
  entorno_color_reset=$(printf '\033[0m')
  entorno_color_ok=$(printf '\033[32m')
  entorno_color_aviso=$(printf '\033[33m')
  entorno_color_error=$(printf '\033[31m')
fi
entorno_version_repo() {
  sed -n '1p' "$PROJECT_ROOT/VERSION"
}
entorno_banner() {
  if [ -t 1 ] && [ "${TERM:-dumb}" != dumb ]; then
    printf '\033[2J\033[H'
  fi
  printf '%s' "$entorno_color_ok"
  cat <<'BANNER'
██╗  ███████╗  ██╗
██║  ██╔════╝  ██║
██║  █████╗    ██║
██║  ██╔══╝    ██║
██║  ██║       ███████╗
╚═╝  ╚═╝       ╚══════╝
BANNER
  printf '%s\n' "$entorno_color_reset"
  printf 'ENTORNO-NVIM v%s | %s\n' "$(entorno_version_repo)" "$1"
  printf '%s\n\n' 'Neovim · Node · LSP · tmux · búsqueda · Git'
}
entorno_confirmar_inicio() {
  printf '\n%s\n' 'ANTES DE COMENZAR'
  printf '  Modalidad: %s\n' "$1"
  printf '%s\n' '  - Comprobara requisitos y reutilizara lo ya instalado.' '  - Descargara los componentes locales que falten dentro del repositorio.' '  - Preparara plugins y servidores de lenguaje de la modalidad elegida.'
  if [ "$sistema_auto" -eq 1 ]; then
    printf '%s\n' '  - Si faltan paquetes del sistema, mostrara el comando y pedira permiso para sudo.'
  else
    printf '%s\n' '  - No ejecutara sudo; si faltan paquetes del sistema, mostrara como instalarlos.'
  fi
  printf '%s\n' '  - No sustituira su configuracion habitual ni el comando nvim.'
  if [ "$2" = alumnado ]; then
    printf '%s\n' '  - Creara el lanzador entorno-dev en ~/.local/bin sin sobrescribir archivos ajenos.' '  - No instalara las herramientas PDF.'
  else
    printf '%s\n' '  - Preparara el entorno completo, incluidos parsers y requisitos para Markdown/PDF.'
  fi
  if [ "$inicio_sin_pausa" -eq 1 ]; then
    printf '\n%s\n' '[INFO] Inicio sin pausa solicitado con --yes.'
    return 0
  fi
  if [ ! -t 0 ]; then
    printf '%s\n' 'No hay entrada interactiva. Use --yes si desea iniciar sin pausa.' >&2
    return 1
  fi
  printf '\n%s' 'Pulse Enter para comenzar, o Ctrl+C para cancelar: '
  IFS= read -r inicio_respuesta || return 1
  if [ -n "$inicio_respuesta" ]; then
    printf '%s\n' 'Cancelado: solo Enter confirma el inicio.'
    exit 0
  fi
}
entorno_fase() {
  entorno_fase_actual=$1
  printf '\n%s[EN CURSO] %s%s\n' "$entorno_color_aviso" "$entorno_fase_actual" "$entorno_color_reset"
}
entorno_instalacion_salida() {
  entorno_salida_codigo=$?
  trap - 0
  if [ "$entorno_salida_codigo" -ne 0 ]; then
    printf '\n%s[ERROR] INSTALACION O COMPROBACION INCOMPLETA (codigo %s)%s\n' "$entorno_color_error" "$entorno_salida_codigo" "$entorno_color_reset" >&2
    printf 'Fase que no termino: %s\n' "${entorno_fase_actual:-inicio}" >&2
    printf '%s\n' 'Revise el error o los requisitos pendientes indicados justo arriba.' 'No se confirma que todo este instalado. Resuelva el aviso y repita el comando.' >&2
  fi
  exit "$entorno_salida_codigo"
}
# Se llama solo despues de completar las fases y comprobaciones del instalador.
entorno_resumen_instalacion() {
  resumen_perfil=$1
  resumen_tipo=$2
  printf '\n%s\n' '================================================================'
  if [ -n "${faltan_opcionales:-}" ] && [ "$resumen_tipo" = completa ]; then
    printf '%s[AVISO] PREPARADA CON OPCIONALES PENDIENTES%s\n' "$entorno_color_aviso" "$entorno_color_reset"
  else
    printf '%s[OK] INSTALACION PREPARADA%s\n' "$entorno_color_ok" "$entorno_color_reset"
  fi
  printf '%s\n' '================================================================'
  printf '  Version del entorno: %s\n' "$(entorno_version_repo)"
  printf '  Perfil: %s | Modalidad: %s\n' "$resumen_perfil" "$resumen_tipo"
  printf '  Repositorio: %s\n\n' "$PROJECT_ROOT"
  printf '%s\n' '  [##########] Neovim y Node: fases completadas'
  printf '%s\n' '  [##########] Plugins: revisiones del lockfile preparadas'
  printf '%s\n' '  [##########] Servidores de lenguaje: fase completada'
  if [ "$resumen_tipo" = completa ]; then
    printf '%s\n' '  [##########] Tree-sitter: herramientas y parsers preparados'
    if [ -n "${faltan_opcionales:-}" ]; then
      printf '%s\n' '  [AVISO] Hay herramientas opcionales pendientes:'
      imprimir_lista "$faltan_opcionales"
      printf '%s\n' '          Consulte los avisos anteriores para PDF y otras funciones.'
    else
      printf '%s\n' '  [OK] No faltan paquetes opcionales detectados en la comprobación inicial'
    fi
  else
    printf '%s\n' '  [##########] Arranque aislado de Neovim comprobado'
    printf '%s\n' '  [OK] Lanzador entorno-dev preparado en ~/.local/bin'
    printf '%s\n' '  [INFO] Este perfil no instala las herramientas de Markdown/PDF'
  fi
  printf '\n%s\n' '  EMPIECE AQUI (desde la carpeta del repositorio):'
  printf '    ./bin/entorno-dev --perfil %s --sin-ia /ruta/a/mi-proyecto\n' "$resumen_perfil"
  printf '\n'; printf '%s\n' '  SOLO EL EDITOR:' '    ./scripts/arrancar.sh /ruta/a/archivo'
  printf '\n'; printf '%s\n' '  DENTRO DE NEOVIM:' '    Esc y Espacio ?   Ayuda de teclas' '    Espacio e        Explorador' '    Espacio w        Guardar' '    :bd              Cerrar archivo sin salir'
  printf '\n%s\n' '  COMANDOS EN EL PATH:'
  if [ "$resumen_tipo" = completa ]; then
    printf '%s\n' '    Para disponer de entorno-dev desde cualquier carpeta:' '    ./scripts/instalar-entorno-dev.sh'
  fi
  printf '%s\n' '    nvim no se sustituye automaticamente.' '    Activacion opcional de nvim y su configuracion: README.md.'
  printf '\n%s\n' '  ACTUALIZAR: git pull --ff-only y repetir este instalador.'
  printf '%s\n' '  Lazygit utiliza la version del sistema; no se actualiza aqui.'
  printf '%s\n' '  La IA es opcional: no se instalan clientes ni credenciales.'
  printf '%s\n' '  Documentacion: README.md y docs/alumno.md'
  printf '%s\n\n' '================================================================'
}
