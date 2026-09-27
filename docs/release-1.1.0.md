# Cierre de entorno-nvim 1.1.0

Fecha: 2026-09-27. Se conserva Neovim 0.12.4 y las versiones de herramientas
existentes. Esta versión mejora productividad, ayuda e instalación; no migra a
LazyVim ni sustituye automáticamente la configuración activa.

## Cambios

Véase [CHANGELOG](../CHANGELOG.md). El nuevo complemento indent-blankline está
fijado por commit y documentado en [decisiones](decisiones.md). Los snippets
propios son editables y compatibles con el formato JSON de VS Code.

## Verificación

- JSDoc: pulsaciones reales /** y Enter con el servidor TypeScript, y Enter normal.
- Productividad: ayuda flotante, sintaxis de todos los snippets y guías de indentación.
- Instaladores: versión y plan previo con pseudoterminal, pausa y cancelación.
- La instalación completa repetida fue ejecutada por el usuario en Omarchy y
  mostró todos los requisitos obligatorios preparados antes de añadir la pausa.
- La instalación desde cero en un equipo sin herramientas y las plataformas
  macOS/WSL2 no quedan certificadas por estas pruebas locales.

- Suite `ENTORNO_SIN_LISTEN=1 ./scripts/comprobar.sh`: completada en el equipo
  local Omarchy. Incluye temas, tmux, activación/restauración en rutas de prueba,
  Markdown/PDF e instalación aislada. Los instaladores de alumnado DWEC y SI
  se repitieron dos veces por perfil, con --yes y HOME temporal.
- La prueba de Python presentó un fallo intermitente de espera de diagnósticos;
  pasó de forma aislada y en la suite final. Se mejoró el mensaje de fallo para
  incluir los diagnósticos recibidos, sin ocultar el requisito.
- Checkhealth no presenta errores críticos; conserva avisos opcionales de
  visores de imagen ausentes, runtime, deprecación y actualización disponible.

Comandos específicos adicionales (desde el repositorio):

```sh
python3 tests/comprobar_instalador_entrada.py
.tools/nvim-0.12.4/bin/nvim -u NONE --headless -l tests/comprobar_productividad.lua
PATH="$PWD/.tools/node-24.21.0-linux-x64/bin:$PATH" \
  .tools/nvim-0.12.4/bin/nvim -u NONE --headless -l tests/comprobar_jsdoc.lua
```

## Publicación

El commit y la etiqueta locales no publican el proyecto. Revisar el resultado y
publicar en remoto solo con autorización explícita. El archivo fuente de GitHub
puede servir como distribución; no se genera un paquete .deb en esta fase.

## Identidad visual

[Prompt para una nueva identidad](logo-prompt.md). El banner actual se conserva
hasta elegir y revisar la propuesta.
