#!/bin/sh
# Se ofrece al final de instalar.sh e instalar-alumno.sh. Nunca usa sudo.
set -eu
if [ ! -t 0 ]; then
  printf '%s\n' '[INFO] PATH sin modificar: no hay entrada interactiva.'
  exit 0
fi
case "${SHELL:-}" in
  */bash) path_archivo="$HOME/.bashrc"; path_linea='export PATH="$HOME/.local/bin:$PATH"' ;;
  */zsh) path_archivo="${ZDOTDIR:-$HOME}/.zshrc"; path_linea='export PATH="$HOME/.local/bin:$PATH"' ;;
  */fish) path_archivo="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/entorno-dev-path.fish"; path_linea='fish_add_path "$HOME/.local/bin"' ;;
  *)
    printf '%s\n' '[AVISO] Shell no reconocida; PATH sin modificar.' 'Configure ~/.local/bin en el PATH de su shell. Consulte README.md.'
    exit 0 ;;
esac
path_marca='# entorno-nvim: comando entorno-dev en PATH'
if [ -f "$path_archivo" ] && { grep -q -F "$path_marca" "$path_archivo" || grep -q -F "$path_linea" "$path_archivo"; }; then
  printf '[OK] Acceso permanente ya configurado en %s.\n' "$path_archivo"
  exit 0
fi
printf '\n%s\n' 'COMANDO ENTORNO-DEV DESDE CUALQUIER CARPETA'
printf '¿Añadir ~/.local/bin al PATH de forma permanente? [s/N]:\n'
printf '  Se añadirá a: %s\n' "$path_archivo"
printf '%s\n' '  No sustituye nvim ni cambia paquetes del sistema.' '  Escriba s para aceptar; Enter conserva su configuración.'
printf '> '
IFS= read -r path_respuesta || path_respuesta=
case "$path_respuesta" in
  s|S|si|Si|SI|sí|Sí|y|Y|yes) ;;
  *) printf '%s\n' '[INFO] PATH sin modificar por elección del usuario.'; exit 0 ;;
esac
if [ -L "$path_archivo" ]; then
  printf '[AVISO] %s es un enlace simbólico; no se modifica automáticamente.\n' "$path_archivo"
  exit 0
fi
mkdir -p "$(dirname "$path_archivo")"
if [ -f "$path_archivo" ]; then
  path_copia=$(mktemp "${path_archivo}.entorno-backup.XXXXXX")
  cp -p "$path_archivo" "$path_copia"
  printf 'Copia recuperable: %s\n' "$path_copia"
fi
printf '\n%s\n%s\n' "$path_marca" "$path_linea" >> "$path_archivo"
printf '[OK] PATH configurado en %s.\n' "$path_archivo"
printf '%s\n' 'Abra una terminal nueva y compruebe: entorno-dev --help' 'La terminal actual no cambia su PATH desde este instalador.'
