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

`config.lsp.enable(nombre, ajustes)` combina el catálogo con ajustes propios
mediante `vim.lsp.config()` y activa el servidor con `vim.lsp.enable()`. Están
habilitados `ts_ls`, `html`, `cssls` y `jsonls`; sus procesos solo arrancan al
abrir un tipo de archivo compatible.

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

## Servidores web activos

| Configuración | Lenguajes | Ejecutable |
| --- | --- | --- |
| `ts_ls` | JavaScript, TypeScript, JSX y TSX | `typescript-language-server --stdio` |
| `html` | HTML | `vscode-html-language-server --stdio` |
| `cssls` | CSS, SCSS y Less | `vscode-css-language-server --stdio` |
| `jsonls` | JSON y JSON con comentarios | `vscode-json-language-server --stdio` |

Los comandos usan rutas absolutas bajo `tools/lsp-web/node_modules/.bin`; no
dependen del `PATH` global. `nvim-lspconfig` sigue aportando tipos de archivo,
raíces de proyecto, opciones iniciales y comandos específicos de TypeScript.
En HTML se conservan los modos embebidos para JavaScript y CSS.

`tailwindcss` no está instalado ni habilitado y será la siguiente subfase.
LuaLS, `bashls` y BasedPyright quedan para una fase posterior. Tampoco existe
format-on-save: `<leader>lf` sigue siendo una acción manual.

## Versiones y decisión TypeScript

El 7 de agosto de 2026 se verificaron en el registro oficial estas versiones
estables: pnpm 11.20.0, TypeScript 7.0.2, typescript-language-server 5.3.0 y
vscode-langservers-extracted 4.10.0.

El entorno fija pnpm 11.18.0 porque 11.20.0 llevaba solo cuatro días publicado
y la política exige siete días de antigüedad. Se fija TypeScript 6.0.3 porque
`typescript-language-server` 5.3.0 envuelve la API de `tsserver`; TypeScript 7
es una implementación nativa distinta y ya no ofrece esa API estable. Migrar
al servidor nativo de TypeScript 7 requiere una evaluación independiente.

Fuentes oficiales consultadas:

- `https://registry.npmjs.org/pnpm/11.18.0`;
- `https://registry.npmjs.org/typescript/6.0.3`;
- `https://registry.npmjs.org/typescript-language-server/5.3.0`;
- `https://registry.npmjs.org/vscode-langservers-extracted/4.10.0`;
- `https://github.com/typescript-language-server/typescript-language-server/releases/tag/v5.3.0`;
- `https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html`.

## Instalación reproducible

Node 22.23.2 y Corepack 0.34.6 ya estaban instalados. No se ejecuta
`corepack enable`, no se instala pnpm globalmente y no se cambia el `PATH`.

```sh
./scripts/instalar-lsp-web.sh
```

El manifiesto fija versiones exactas y el campo `packageManager` fija pnpm
11.18.0 junto con el SHA-512 del artefacto. El lockfile conserva todas las
versiones transitivas e integridades. Corepack se descarga bajo
`.xdg/0.12.4/corepack`, el almacén está en `.xdg/0.12.4/pnpm/store` y los
enlaces ejecutables quedan en `tools/lsp-web/node_modules/.bin`.

La política de `pnpm-workspace.yaml`:

- retrasa siete días cualquier versión nueva;
- falla si falta la fecha de publicación;
- verifica integridad y contenido del almacén;
- impide fuentes transitivas Git o tarballs arbitrarios;
- considera error cualquier build no revisado;
- deniega expresamente el `postinstall` informativo de `core-js`.

Los tarballs directos se inspeccionaron antes de instalar y todas sus rutas
quedaban bajo `package/`. Ninguno declara `preinstall`, `install` o
`postinstall`; `typescript-language-server` conserva un `prepare` de desarrollo
que no se ejecuta para el artefacto ya compilado. La inspección transitoria con
`--ignore-scripts` confirmó que `core-js` era el único ciclo instalable. La
auditoría del lockfile no encontró vulnerabilidades conocidas en esta fecha.

## Comprobación funcional

`tests/comprobar_lsp_web.lua` abre fixtures reales JS, TS, JSX, TSX, HTML, CSS y
JSON. Comprueba conexión, diagnósticos, definición, `gd`, hover, referencias,
rename, completado, disparadores automáticos, `Ctrl-Space`, auto-imports y la
capacidad nativa de snippets. Los cambios de rename y completado no se escriben
en los fixtures.

Neovim anuncia soporte de snippets y usa `vim.snippet` cuando un servidor los
entrega. No todos los elementos de completado son snippets; por ejemplo, el
servidor HTML devuelve algunas etiquetas como texto plano. No se instala ningún
motor externo.

## Reversión

La instalación no toca ubicaciones globales. Para revertirla se deshabilitan
las cuatro llamadas de `config.lsp`, se retira `tools/lsp-web/node_modules` y,
si no se usa para otra fase, se retiran `.xdg/0.12.4/corepack` y
`.xdg/0.12.4/pnpm`. Los tres archivos reproducibles de `tools/lsp-web` permiten
recrear el entorno después.
