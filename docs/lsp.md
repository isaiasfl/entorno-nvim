# LSP y completado nativo

## Responsabilidades

Neovim 0.12.4 aporta el cliente LSP, los diagnósticos, la navegación, las
acciones de código, el formato, el completado y la expansión de snippets. Los
módulos `config.lsp` y `config.completion` organizan esas APIs nativas.

`nvim-lspconfig` v2.9.0 se fija en el commit
`f6738ef65dabade340b473d4ff2a1ad3352c10e7`. Solo aporta archivos `lsp/*.lua`
con comandos, tipos de archivo, marcadores de raíz y ajustes iniciales. No es
el cliente LSP, no instala servidores y no gestiona el completado. No se usa la
API antigua `require("lspconfig")`.

Esta subfase no habilita ninguna configuración con `vim.lsp.enable()`. El
método `config.lsp.enable(nombre, ajustes)` queda preparado para combinar el
catálogo con ajustes propios mediante `vim.lsp.config()` y activar después el
servidor con la API nativa.

## Mapas de Neovim 0.12

Neovim ya define estos mapas globales y no se duplican:

| Mapa | Acción |
| --- | --- |
| `gra` | Acción de código |
| `gri` | Ir a la implementación |
| `grn` | Renombrar símbolo |
| `grr` | Mostrar referencias |
| `grt` | Ir a la definición de tipo |
| `grx` | Ejecutar code lens |
| `gO` | Mostrar símbolos del documento |
| `Ctrl-S` en insertar | Mostrar ayuda de firma |

Cuando un servidor se conecta, Neovim también configura `K` para mostrar la
documentación del símbolo, `Ctrl-]` para ir a una definición y `gq` para
formatear el rango cuando el servidor lo permite.

El proyecto añade solo mapas locales al buffer conectado:

| Mapa | Acción |
| --- | --- |
| `gd` | Ir a la definición |
| `gD` | Ir a la declaración |
| `<leader>lf` | Formatear el buffer completo |

`gd` es una alternativa directa a la navegación mediante `Ctrl-]`. Los mapas
locales no afectan a buffers sin un cliente LSP.

## Completado

Al conectarse un cliente que anuncie `textDocument/completion`, se llama a
`vim.lsp.completion.enable()` con `autotrigger = true`. Los caracteres que
abren automáticamente el menú dependen de cada servidor.

| Tecla | Acción nativa |
| --- | --- |
| `Ctrl-Space` | Solicitar completado LSP expresamente |
| `Ctrl-X Ctrl-O` | Usar el completado LSP mediante `omnifunc` |
| `Ctrl-N` / `Ctrl-P` | Recorrer candidatos |
| `Ctrl-Y` | Aceptar el candidato |
| `Ctrl-E` | Cerrar el menú |

`completeopt` usa `menu`, `menuone`, `noselect` y `popup`. Esto evita aceptar
una opción accidentalmente y permite mostrar su documentación. Neovim puede
aplicar imports, ediciones adicionales y snippets al aceptar un elemento; no
se instala un motor de snippets externo.

## Servidores posteriores

La siguiente subfase priorizará:

- `ts_ls` para JavaScript, TypeScript y React/TSX;
- `html` para HTML;
- `cssls` para CSS;
- `jsonls` para JSON.

Después se añadirá `tailwindcss` únicamente para proyectos Tailwind. LuaLS,
`bashls` y BasedPyright quedan para una fase posterior. Hasta entonces no hay
servidores habilitados ni procesos LSP al abrir archivos.

## Propuesta reproducible con Corepack y pnpm

El equipo tiene Node 22.23.2 y Corepack 0.34.6, pero no pnpm. No se activa ni se
descarga pnpm en esta subfase.

La siguiente subfase deberá:

1. verificar una versión estable de pnpm compatible con Corepack 0.34.6;
2. fijarla, con su hash de integridad, en el campo `packageManager` de un
   manifiesto dedicado a herramientas web;
3. fijar versiones exactas de `typescript`, `typescript-language-server` y
   `vscode-langservers-extracted`;
4. generar y versionar `pnpm-lock.yaml`;
5. dirigir `COREPACK_HOME`, el almacén pnpm y `node_modules` a rutas aisladas
   dentro del repositorio;
6. bloquear scripts de dependencias y revisar individualmente cualquier build
   solicitado antes de aprobarlo;
7. usar `corepack pnpm install --frozen-lockfile` desde un script del proyecto,
   sin activar pnpm globalmente ni cambiar `PATH`;
8. pasar rutas explícitas de los ejecutables a las configuraciones LSP.

Antes de crear ese manifiesto se revisarán las versiones, dependencias
transitivas, scripts de instalación y alertas oficiales disponibles. El
servidor Tailwind se incorporará en su propia subfase y no se mezclará con la
instalación web inicial.
