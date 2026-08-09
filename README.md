# Entorno Neovim de Isaías

Configuración de Neovim construida desde cero, modular y portable. El objetivo
es disponer de un entorno comprensible para programación y edición de Markdown,
sin depender de una distribución prefabricada.

## Estado

El proyecto contiene un núcleo nativo de Neovim y una capa mínima de plugins:
`lazy.nvim` gestiona dependencias, `fzf-lua` proporciona búsqueda y
`nvim-tree.lua` permite recorrer el proyecto como árbol. Tree-sitter añade
resaltado estructural para shell, Python y desarrollo web. El cliente LSP y el
completado son nativos; `nvim-lspconfig` aporta únicamente el catálogo de
configuraciones. Los servidores web para JavaScript, TypeScript, React/TSX,
HTML, CSS y JSON se instalan de forma aislada y reproducible mediante Corepack
y pnpm. LuaLS aporta soporte para los módulos Lua de esta configuración desde
una instalación versionada bajo `~/.local/opt`. Tailwind CSS se activa solo
cuando detecta una dependencia, una configuración clásica o una entrada
CSS-first real. `mini.pairs` aporta cierre automático de delimitadores y
comillas sin activar otros módulos de mini.nvim. Todo se ejecuta en un entorno
XDG aislado y no modifica ni enlaza `~/.config/nvim`.

El entorno principal es Debian 13 y el objetivo actual es Neovim 0.12.4. Los
scripts seleccionan su instalación paralela sin cambiar el binario global
0.11.4. Se buscará compatibilidad razonable con CachyOS y macOS.

## Documentación

- [Decisiones e inventario](docs/decisiones.md)
- [Entorno aislado](docs/entorno-aislado.md)
- [Neovim 0.12.4 en paralelo](docs/neovim-0.12.md)
- [Plugins, búsqueda y exploración](docs/plugins.md)
- [Tree-sitter y parsers](docs/treesitter.md)
- [LSP y completado nativo](docs/lsp.md)
- [Flujo de Markdown y PDF](docs/markdown-pdf.md)
- [Restauración](docs/restauracion.md)
- [Contexto original](CONTEXTO_INICIAL.md)

## Ejecución

Abrir Neovim con la configuración del repositorio:

```sh
./scripts/instalar-lsp-web.sh
./scripts/instalar-luals.sh
./scripts/arrancar.sh
```

También se puede abrir un archivo o pasar cualquier argumento normal de
Neovim:

```sh
./scripts/arrancar.sh README.md
```

Ejecutar las comprobaciones headless:

```sh
./scripts/comprobar.sh
```

Los detalles de las rutas utilizadas y del aislamiento están en
[docs/entorno-aislado.md](docs/entorno-aislado.md).
