# Plugins, búsqueda y exploración

## Alcance

La configuración incorpora únicamente:

- `lazy.nvim`, gestor directo de plugins;
- `fzf-lua`, método principal para buscar archivos, texto y buffers;
- `nvim-tree.lua`, exploración jerárquica y operaciones sobre archivos;
- `mini.pairs`, cierre automático mínimo de pares al escribir;
- `nvim-ts-autotag`, autocierre y autorrenombrado de etiquetas HTML/JSX/TSX;
- `nvim-lspconfig`, catálogo de configuraciones para el cliente LSP nativo.

No incluye Mason, motores externos de completado, plugins Git o de IA,
depuración, iconos ni temas. Tree-sitter y LSP se documentan por separado en
[treesitter.md](treesitter.md) y [lsp.md](lsp.md).

## Dependencias

| Componente | Tipo | Función |
| --- | --- | --- |
| Neovim 0.12.4 | Existente | Ejecuta y comprueba la configuración |
| Git 2.47.3 | Existente | Descarga los repositorios de plugins |
| fzf 0.60 | Existente | Filtra y presenta resultados interactivamente |
| ripgrep 15.2 | Existente | Lista archivos y busca texto en el proyecto |
| lazy.nvim | Directa | Gestiona instalación, carga y lockfile |
| fzf-lua | Directa | Proporciona los tres selectores |
| nvim-tree.lua | Directa | Muestra el árbol y opera sobre archivos |
| mini.nvim | Directa | Proporciona únicamente el módulo `mini.pairs` |
| nvim-ts-autotag | Directa | Gestiona pares de etiquetas mediante Tree-sitter |
| nvim-lspconfig | Directa | Aporta configuraciones de servidores LSP |

No hay dependencias Lua transitivas obligatorias. `nvim-web-devicons` es
opcional para nvim-tree y no se declara ni se instala. Los iconos están
desactivados, por lo que no se necesita una Nerd Font. Ninguno de estos plugins
ejecuta un proceso de construcción; Git solo descarga sus repositorios.

## Atajos

| Atajo | Acción | Función de fzf-lua |
| --- | --- | --- |
| `<leader>ff` | Buscar archivos | `files()` |
| `<leader>fg` | Buscar texto en el proyecto | `live_grep()` |
| `<leader>fb` | Ver buffers abiertos | `buffers()` |

La búsqueda de archivos ejecuta explícitamente `rg --files`, incluye archivos
ocultos y excluye `.git`. La búsqueda de texto usa ripgrep y respeta sus reglas
normales de exclusión, incluido `.gitignore`.

## Controles dentro de fzf-lua

| Tecla | Acción |
| --- | --- |
| `Ctrl+j` o flecha abajo | Bajar una posición |
| `Ctrl+k` o flecha arriba | Subir una posición |
| `Enter` | Abrir el elemento seleccionado |
| `Esc` | Cerrar fzf-lua |

Estos controles se convierten en enlaces internos del proceso `fzf` y solo
existen mientras su interfaz está abierta. Fuera de `fzf-lua`, `Ctrl+h/j/k/l`
conservan los atajos globales para cambiar entre ventanas de Neovim.

## Explorador nvim-tree

Usa fzf-lua cuando conozcas parte del nombre del archivo o del texto buscado:
es la ruta rápida y principal. Usa nvim-tree cuando necesites entender la
estructura de carpetas o crear, renombrar y borrar elementos en su contexto.

| Atajo | Acción |
| --- | --- |
| `<leader>ee` | Abrir o cerrar el árbol |
| `<leader>ef` | Abrir el árbol y enfocar el archivo actual |

`<leader>ef` realiza una revelación puntual. No activa seguimiento permanente,
no cambia la raíz del árbol y avisa si el buffer actual no es un archivo.
nvim-tree tampoco se abre automáticamente al iniciar ni al abrir un directorio.

### Controles dentro del árbol

| Tecla | Acción |
| --- | --- |
| `j` / `k` | Bajar / subir por los elementos |
| `Enter` | Abrir un archivo o expandir/contraer un directorio |
| `Ctrl+h/j/k/l` | Cambiar a la ventana situada en esa dirección |
| `a` | Crear un archivo; termina el nombre en `/` para crear un directorio |
| `r` | Renombrar el elemento seleccionado |
| `d` | Borrar el elemento seleccionado, previa confirmación |
| `g?` | Mostrar u ocultar la ayuda con todos los mapas efectivos |
| `q` | Cerrar el árbol |

Para pasar del árbol al archivo normalmente se usa `Ctrl+l`, porque el árbol
está a la izquierda. `Enter` abre el elemento en una ventana de edición y deja
el árbol disponible. Para volver al árbol se usa `Ctrl+h`. También puede
cerrarse con `q` desde el árbol o con `<leader>ee` desde cualquier ventana.

Crear, renombrar y borrar solicitan entrada de forma explícita. El borrado y el
envío a la papelera mantienen confirmación, con respuesta negativa por defecto.
La integración Git, los diagnósticos, los indicadores de modificación, los
filtros y los decoradores visuales están desactivados.

## Sustitución de netrw

`netrw`, el explorador incluido en Neovim, está desactivado para que no compita
con nvim-tree por los buffers de directorio. Se pierden `:Explore`, `:Vexplore`,
`:Sexplore`, la navegación al ejecutar `:edit .` y las funciones de navegación
o transferencia remota de netrw.

Para recuperarlo, elimina de `nvim/init.lua` estas dos asignaciones y reinicia
Neovim:

```lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
```

También cambia `disable_netrw` a `false` en la configuración de nvim-tree. La
convivencia es posible, pero no se adopta aquí porque dos exploradores tratando
de abrir directorios producen un comportamiento menos predecible.

## Pares automáticos

`mini.nvim` se carga al entrar por primera vez en modo insertar, pero solo se
inicializa `mini.pairs`. No se activa ningún otro módulo de la colección.

| Al escribir | Resultado |
| --- | --- |
| `(` | `()` |
| `[` | `[]` |
| `{` | `{}` |
| `"` | `""` |
| `'` | `''` |
| Acento grave (`\``) | Dos acentos graves |

El cursor queda entre ambos caracteres. Al escribir el cierre delante del
cierre ya generado, el cursor avanza sin duplicarlo. El comportamiento se
limita al modo insertar; no modifica la línea de comandos ni el terminal.

## Etiquetas automáticas

`nvim-ts-autotag` se limita a `html`, `javascriptreact` y `typescriptreact`.
Al escribir `>` cierra etiquetas HTML y componentes JSX/TSX que necesiten un
par. Al renombrar una etiqueta de apertura o cierre, actualiza su pareja al
salir del modo insertar. Las etiquetas vacías y autocontenidas no reciben un
cierre adicional; el cierre mediante una barra escrita manualmente permanece
desactivado.

Neovim, LSP y Tree-sitter reconocen y completan estas estructuras, pero no
coordinan de forma nativa su autocierre y autorrenombrado. El plugin requiere
Neovim 0.9.5 o posterior y un parser compatible; esta configuración tiene
Neovim 0.12.4 y parsers fijados para HTML, JavaScript, TypeScript y TSX.

No entra en conflicto con `mini.pairs`: este último administra `()`, `[]`,
`{}` y comillas, mientras que autotag solo añade comportamiento local para
`>` y las etiquetas. Tampoco modifica los mapas ni las APIs del completado LSP.

## Aislamiento y versiones

Los repositorios descargados se guardan bajo la raíz XDG seleccionada, por
ejemplo `.xdg/0.12.4/data/nvim/lazy`, nunca en la
instalación activa. Sus commits exactos quedan registrados en
`nvim/lazy-lock.json`, que sí se versiona.

`fzf-lua` crea un socket local para comunicarse con procesos headless. El script
de arranque dirige también `XDG_RUNTIME_DIR` a `.xdg/0.12.4/runtime` y aplica
permisos `0700`, manteniendo ese socket dentro del aislamiento.

Lazy no comprueba ni instala actualizaciones automáticamente. Una actualización
futura debe ejecutarse de forma explícita, revisar los cambios y volver a
ejecutar `./scripts/comprobar.sh` antes de aceptar el lockfile nuevo.

La comprobación genera un informe en `.xdg/0.12.4/checkhealth.txt`. El script
invoca explícitamente la salud de `fzf-lua`; `checkhealth` comprueba además
`nvim-treesitter`, sus ocho parsers externos y el binario de Tree-sitter fijado.
