# Plugins y búsqueda

## Alcance

La primera fase de plugins incorpora únicamente:

- `lazy.nvim`, gestor directo de plugins;
- `fzf-lua`, búsqueda de archivos, texto y buffers.

No incluye LSP, Mason, Treesitter, Git, IA, depuración, explorador de archivos,
iconos ni temas.

## Dependencias

| Componente | Tipo | Función |
| --- | --- | --- |
| Neovim 0.11.4 | Existente | Ejecuta la configuración y `fzf-lua` |
| Git 2.47.3 | Existente | Descarga `lazy.nvim` y `fzf-lua` |
| fzf 0.60 | Existente | Filtra y presenta resultados interactivamente |
| ripgrep 15.2 | Existente | Lista archivos y busca texto en el proyecto |
| lazy.nvim | Directa | Gestiona instalación, carga y lockfile |
| fzf-lua | Directa | Proporciona los tres selectores |

No hay dependencias Lua transitivas obligatorias. Los iconos y previsualizadores
externos ofrecidos por `fzf-lua` son opcionales y no se habilitan.

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

## Aislamiento y versiones

Los repositorios descargados se guardan en `.xdg/data/nvim/lazy`, nunca en la
instalación activa. Sus commits exactos quedan registrados en
`nvim/lazy-lock.json`, que sí se versiona.

`fzf-lua` crea un socket local para comunicarse con procesos headless. El script
de arranque dirige también `XDG_RUNTIME_DIR` a `.xdg/runtime` y aplica permisos
`0700`, manteniendo ese socket dentro del aislamiento.

Lazy no comprueba ni instala actualizaciones automáticamente. Una actualización
futura debe ejecutarse de forma explícita, revisar los cambios y volver a
ejecutar `./scripts/comprobar.sh` antes de aceptar el lockfile nuevo.

La comprobación genera un informe en `.xdg/checkhealth.txt`. Como Neovim 0.11.4
no descubre automáticamente el módulo `_health` de este commit de `fzf-lua`, el
script invoca ese módulo oficial de forma explícita y añade su resultado al
informe general.
