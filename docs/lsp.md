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
habilitados `ts_ls`, `html`, `cssls`, `jsonls` y `tailwindcss`; sus procesos
solo arrancan al abrir un tipo de archivo compatible y encontrar una raíz
válida.

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
| `Tab` / `Shift-Tab` | Recorrer candidatos cuando el menu esta visible |
| `Ctrl-N` / `Ctrl-P` | Recorrer candidatos como alternativa nativa |
| `Enter` / `Ctrl-Y` | Aceptar el candidato seleccionado |
| `Ctrl-E` | Cerrar el menú |

`completeopt` usa `menu`, `menuone`, `noselect` y `popup`. Esto evita aceptar
una opción accidentalmente y permite mostrar su documentación. Neovim puede
aplicar imports, ediciones adicionales y snippets al aceptar un elemento; no
se instala un motor de snippets externo. Fuera del menú, `Tab` y `Shift-Tab`
conservan la indentación normal o saltan entre posiciones de un snippet nativo
activo; `Enter` conserva la inserción de una línea nueva.

## Diagnósticos durante la escritura

`vim.diagnostic.config({ update_in_insert = true })` permite refrescar signos,
subrayados y mensajes mientras se permanece en modo insertar. No inicia
procesos adicionales: los servidores ya reciben los cambios del documento y
esta opción controla cuándo Neovim presenta los diagnósticos recibidos. Con los
servidores web locales el coste observado es despreciable. Si resulta visualmente
ruidoso, puede volver al comportamiento predeterminado cambiando el valor a
`false`; los diagnósticos se actualizarán al salir de insertar.

## Servidores web activos

| Configuración | Lenguajes | Ejecutable |
| --- | --- | --- |
| `ts_ls` | JavaScript, TypeScript, JSX y TSX | `typescript-language-server --stdio` |
| `html` | HTML | `vscode-html-language-server --stdio` |
| `cssls` | CSS, SCSS y Less | `vscode-css-language-server --stdio` |
| `jsonls` | JSON y JSON con comentarios | `vscode-json-language-server --stdio` |
| `tailwindcss` | HTML, CSS, JavaScript/JSX y TypeScript/TSX en proyectos Tailwind | `tailwindcss-language-server --stdio` |

Los comandos usan rutas absolutas bajo `tools/lsp-web/node_modules/.bin`; no
dependen del `PATH` global. `nvim-lspconfig` sigue aportando tipos de archivo,
raíces de proyecto, opciones iniciales y comandos específicos de TypeScript.
En HTML se conservan los modos embebidos para JavaScript y CSS.

Para `ts_ls`, la raíz se detecta por este orden: lockfile del gestor de
paquetes, `package.json` y `.git`. Un proyecto sencillo con `package.json` pero
sin lockfile queda aislado correctamente; los monorepos con lockfile conservan
la raíz común. Los proyectos Deno siguen excluidos de `ts_ls`.

LuaLS, `bashls` y el servidor de Python quedan para una fase posterior. Tampoco
existe format-on-save: `<leader>lf` sigue siendo una acción manual.

## Activación selectiva de Tailwind

`tailwindcss` está habilitado en Neovim, pero su proceso solo arranca cuando
`root_dir` confirma al menos una evidencia de proyecto Tailwind:

- `package.json` declara `tailwindcss` en dependencias directas, de desarrollo,
  opcionales o de pares;
- existe `tailwind.config.js`, `.cjs`, `.mjs`, `.ts`, `.cts` o `.mts`;
- el buffer CSS abierto contiene `@import "tailwindcss"`, una directiva
  `@tailwind` o una referencia `@config`.

Un proyecto HTML, JSX o TSX normal no satisface ninguna de estas condiciones y
no inicia el servidor. La detección lee `package.json` con el decodificador JSON
de Neovim; no usa búsquedas de texto ambiguas.

Para Tailwind v4 CSS-first, `before_init` localiza hasta veinte hojas de entrada
CSS dentro de la raíz, omitiendo `.git`, `node_modules`, salidas de compilación
y cachés habituales. Las pasa al ajuste oficial
`tailwindCSS.experimental.configFile` con un selector limitado al directorio de
cada entrada. Si existe una configuración clásica, no se fuerza este ajuste y
el servidor conserva la detección nativa de Tailwind v3/v4.

El recorrido tiene límites de 2.000 entradas y veinte hojas CSS para evitar que
el arranque examine indefinidamente un monorepo grande. Si un proyecto v4 tiene
varias entradas fuera de esos límites, puede necesitar una configuración
explícita futura.

Tailwind convive con `ts_ls`, `html` y `cssls`: cada servidor mantiene su propio
ámbito. Neovim presenta los colores mediante su capacidad nativa
`textDocument/documentColor`; no se añadió un plugin de Tailwind.

## Versiones y decisión TypeScript

El 7 de agosto de 2026 se verificaron en el registro oficial estas versiones
estables: pnpm 11.20.0, TypeScript 7.0.2, typescript-language-server 5.3.0 y
vscode-langservers-extracted 4.10.0. La publicación oficial marca
`@tailwindcss/language-server` 0.16.0 como la versión estable más reciente.

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
- `https://registry.npmjs.org/@tailwindcss/language-server/0.16.0`;
- `https://github.com/tailwindlabs/tailwindcss-intellisense/releases/tag/v0.16.0`;
- `https://github.com/tailwindlabs/tailwindcss-intellisense#tailwindcssexperimentalconfigfile`;
- `https://github.com/typescript-language-server/typescript-language-server/releases/tag/v5.3.0`;
- `https://www.typescriptlang.org/docs/handbook/release-notes/typescript-6-0.html`.

## Instalación reproducible

Node 22.23.2 y Corepack 0.34.6 ya estaban instalados. No se ejecuta
`corepack enable`, no se instala pnpm globalmente y no se cambia el `PATH`.

```sh
./scripts/instalar-lsp-web.sh
```

En otra máquina, después de clonar el repositorio y comprobar que existen Node
`>=22.13 <23` y Corepack, el comando exacto para recrear esta subfase es:

```sh
cd /ruta/al/entorno-nvim
NVIM_XDG_ROOT="$PWD/.xdg/0.12.4" ./scripts/instalar-lsp-web.sh
```

No requiere `corepack enable`, pnpm global, Mason ni cambios en `PATH`. La orden
descarga la versión de pnpm fijada, exige el lockfile sin cambios y recrea
`tools/lsp-web/node_modules` usando el almacén aislado indicado.

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

`@tailwindcss/language-server` 0.16.0 exige Node `>=18`, por lo que es compatible
con Node 22.23.2. Su artefacto publicado no tiene dependencias de ejecución ni
scripts de ciclo de instalación: distribuye el servidor ya compilado y varios
watchers nativos para las plataformas soportadas. Sus scripts `build`, `test` y
`clean` son solo de desarrollo y no se ejecutan al instalar el tarball. Se
verificó su procedencia publicada, integridad SHA-512 y contenido antes de
añadirlo. `pnpm audit --audit-level low` no encontró vulnerabilidades conocidas
en el entorno combinado el 7 de agosto de 2026.

La prueba v4 usa `tailwindcss` 4.3.3 como dependencia exacta de un fixture
independiente. Ese paquete tampoco declara dependencias transitivas ni scripts
de instalación. Su manifiesto y lockfile viven en
`tests/fixtures/lsp-tailwind-v4`; `node_modules` permanece fuera de Git.

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

`tests/comprobar_tailwind.lua` verifica raíces por dependencia, configuración
clásica y CSS-first v4. En un proyecto v4 real comprueba HTML, JSX, TSX y CSS;
coexistencia con `ts_ls`, `html` y `cssls`; completado de clases, hover,
diagnósticos de conflicto, colores y activación del color nativo. El fixture web
sin Tailwind confirma que el servidor no arranca fuera de su ámbito.

## Lenguajes pendientes

- Lua: evaluar e instalar Lua Language Server de forma aislada y configurar
  `lua_ls`, incluyendo los tipos de la API de Neovim.
- Bash: evaluar `bash-language-server`, su dependencia de Node y la convivencia
  opcional con ShellCheck sin instalarla todavía.
- Python: decidir entre BasedPyright y Pyright según tipado, licencia, consumo y
  método de instalación reproducible; después configurar el servidor elegido.

Estas tareas no forman parte de la subfase Tailwind y no hay binarios ni
configuraciones activas para esos tres lenguajes.

## Reversión

La instalación no toca ubicaciones globales. Para revertirla se deshabilitan
las cinco configuraciones de `config.lsp`, se retiran
`tools/lsp-web/node_modules` y `tests/fixtures/lsp-tailwind-v4/node_modules` y,
si no se usa para otra fase, se retiran `.xdg/0.12.4/corepack` y
`.xdg/0.12.4/pnpm`. Los tres archivos reproducibles de `tools/lsp-web` permiten
recrear el entorno después.
