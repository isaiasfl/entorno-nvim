# Inventario de entorno-nvim v1.0.0

Inventario realizado el 10 de agosto de 2026 en Debian 13 x86_64. Las rutas de
usuario se expresan con `~`; el repositorio puede residir en cualquier ruta.

## A. Configuración versionada

| Área | Fuente reproducible |
| --- | --- |
| Neovim | `nvim/`, módulos Lua y `nvim/lazy-lock.json` |
| tmux | `tmux/tmux.conf`, `scripts/proyecto.sh`, lanzador del popup, `agente.sh` y transporte de contexto |
| Markdown/PDF | `markdown/`, `scripts/markdown-pdf.sh`, visor y ejemplos |
| Instalación | `scripts/instalar*.sh`, activación, restauración y librerías de versiones |
| Pruebas | `tests/` y `scripts/comprobar.sh` |

Los PDF, `node_modules`, plugins descargados, parsers compilados y raíces XDG
son artefactos regenerables e ignorados por Git.

## B. Herramientas bajo ~/.local/opt

| Componente | Versión | Verificación V1 |
| --- | --- | --- |
| Neovim | 0.12.4 | tarball y binario con SHA-256 fijados; Linux x86_64 |
| tree-sitter CLI | 0.26.11 | ZIP oficial con SHA-256; Linux x86_64 y artefactos macOS auditados |
| LuaLS | 3.19.0 | tarball y binario con SHA-256; Linux x86_64 |

El instalador nunca reemplaza un directorio existente que no coincida.

## C. Herramientas de sistema comprobadas

| Herramienta | Versión observada |
| --- | --- |
| Git | 2.47.3 |
| tmux | 3.5a |
| fzf | 0.60.3 |
| fd/fdfind | 10.2.0 |
| ripgrep | 14.1.1 de Debian; el proceso de auditoría también aporta rg 15.2.0 |
| lazygit | 0.50.0 |
| Node | 22.23.2 |
| Pandoc | 3.1.11.1 |
| Chromium | 151.0.7922.108 |
| Poppler | 25.03.0 |
| compilador | toolchain `build-essential` 12.12 |

Corepack procede de la instalación Node disponible. No se instala pnpm global.

## D. Herramientas gestionadas mediante pnpm

Los manifests y lockfiles fijan pnpm 11.18.0 y estas dependencias directas:

| Paquete | Versión |
| --- | --- |
| TypeScript | 6.0.3 |
| typescript-language-server | 5.3.0 |
| vscode-langservers-extracted | 4.10.0 |
| @tailwindcss/language-server | 0.16.0 |
| Pyright | 1.1.411 |

El fixture Tailwind v4 tiene su propio manifest y lockfile. Los almacenes de
Corepack y pnpm viven dentro de la raíz XDG aislada.

## E. Plugins y parsers

Los siete plugins están fijados por commit en `nvim/lazy-lock.json`:
`lazy.nvim`, `fzf-lua`, `nvim-tree.lua`, `nvim-lspconfig`, `nvim-treesitter`,
`nvim-ts-autotag` y `mini.nvim`.

Los parsers externos fijados son `bash`, `python`, `javascript`, `typescript`,
`tsx`, `json`, `html` y `css`. Lua, Markdown y Markdown inline proceden de
Neovim 0.12.4.

## F. Elementos opcionales

- `pdfinfo`, `pdftotext` y `pdftoppm`: validación más profunda del PDF;
- `xdg-open`, `open` o `ENTORNO_PDF_VIEWER`: visualización del PDF;
- clientes Codex, Claude, OpenCode, pi, JARVIS u otros: no se instalan;
- proveedores externos de Neovim e iconos Nerd Font: no son requisitos;
- BashLS: aplazado deliberadamente por la decisión de seguridad existente.
