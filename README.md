# Entorno Neovim de Isaías

Configuración de Neovim construida desde cero, modular y portable. El objetivo
es disponer de un entorno comprensible para programación y edición de Markdown,
sin depender de una distribución prefabricada.

## Estado

El proyecto está en fase de inventario y diseño. Todavía no contiene una
configuración ejecutable y no modifica ni enlaza `~/.config/nvim`.

El entorno principal es Debian 13 con Neovim 0.11.4. Se buscará compatibilidad
razonable con CachyOS y macOS.

## Documentación

- [Decisiones e inventario](docs/decisiones.md)
- [Flujo de Markdown y PDF](docs/markdown-pdf.md)
- [Restauración](docs/restauracion.md)
- [Contexto original](CONTEXTO_INICIAL.md)

## Próximo paso

Tras aprobar la arquitectura inicial, se creará un arranque mínimo aislado en
`nvim/`. Las pruebas usarán directorios temporales para no escribir en los datos,
estado o caché de la configuración activa.
