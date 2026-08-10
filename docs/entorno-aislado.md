# Entorno aislado

## Propósito

La configuración se prueba sin leer ni escribir la configuración activa de
Neovim. No requiere enlaces simbólicos y no modifica el binario instalado.

## Arranque interactivo

Desde la raíz del repositorio:

```sh
./scripts/instalar-lsp-web.sh
./scripts/instalar-lsp-python.sh
./scripts/instalar-luals.sh
./scripts/arrancar.sh
```

El binario y la raíz XDG se pueden seleccionar de forma explícita:

```sh
NVIM_BIN="$HOME/.local/opt/nvim-0.12.4/bin/nvim" \
NVIM_XDG_ROOT="$PWD/.xdg/0.12.4" \
./scripts/arrancar.sh
```

`NVIM_BIN` debe contener únicamente el nombre o la ruta del ejecutable, sin
argumentos. Una ruta XDG relativa se interpreta desde la raíz del repositorio.

El script acepta los mismos argumentos que Neovim:

```sh
./scripts/arrancar.sh ruta/al/archivo.md
./scripts/arrancar.sh +checkhealth
```

## Atajos

| Modo | Atajo | Acción |
| --- | --- | --- |
| Insertar | `jk` | Salir al modo normal, equivalente a `Esc` |
| Normal | `<leader>h` | Limpiar el resaltado de la última búsqueda |
| Normal | `<leader>ul` | Alternar caracteres invisibles en la ventana actual |
| Normal | `<leader>ff` | Buscar archivos del proyecto |
| Normal | `<leader>fg` | Buscar texto dentro del proyecto |
| Normal | `<leader>fb` | Ver y abrir buffers cargados |
| Normal | `<leader>gg` | Abrir lazygit en un terminal flotante |
| Normal/Visual | `<leader>ac` | Enviar contexto al panel de agente de tmux |

`Esc` conserva su funcionamiento normal y `kj` no está mapeado.

### Líneas reales y líneas visuales

`j` y `k` se mantienen sin remapear: avanzan por líneas reales del archivo. Si
una línea larga ocupa varias filas de pantalla porque `wrap` está activo, `j`
salta a la siguiente línea real y puede recorrer varias filas visuales de una
vez.

`gj` y `gk` avanzan por filas visuales. Son útiles en Markdown y texto envuelto,
pero se invocan expresamente para aprender y conservar la diferencia entre los
dos tipos de movimiento.

### Salir del modo insertar

Tanto `jk` como `Esc` salen del modo insertar. `Esc` es la tecla nativa y no se
ha remapeado. `jk` es una alternativa cómoda que depende de `timeoutlen`: tras
escribir `j`, Neovim espera brevemente para saber si la siguiente tecla es `k`.

### Búsquedas y caracteres invisibles

Después de buscar con `/` o `?`, `<leader>h` oculta el resaltado sin borrar el
patrón de búsqueda. `n` y `N` pueden seguir recorriendo sus coincidencias.

Los tabs y espacios finales están ocultos por defecto. `<leader>ul` alterna su
visualización en la ventana actual mediante símbolos ASCII definidos en
`listchars`; no requiere Nerd Font.

## Política de sangría

La configuración general usa espacios y una anchura de dos columnas para Tab,
sangría automática y los operadores `>>` y `<<`. Los buffers Python usan
localmente cuatro espacios.

Estas reglas son valores de partida. Cuando un proyecto contenga
`.editorconfig` o establezca opciones locales mediante su configuración, las
reglas del proyecto deben prevalecer para mantener el estilo del código fuente.

## Comprobación automática

```sh
./scripts/comprobar.sh
```

La comprobación, para el binario seleccionado:

1. arranca Neovim en modo headless y puede validar su versión exacta;
2. confirma que `stdpath("config")` apunta a `nvim/` en este repositorio;
3. confirma que `config.options`, `config.keymaps` y `config.autocmds` se
   cargaron;
4. valida los atajos conservados, añadidos y eliminados;
5. comprueba `list`, la sangría Python y el ajuste de Markdown;
6. verifica que `.editorconfig` puede prevalecer sobre la sangría base;
7. comprueba que undo y swap usan rutas XDG ignoradas por Git;
8. ejecuta `checkhealth` y falla si el informe contiene errores;
9. comprueba que Lazy, `fzf-lua` y el catálogo LSP están registrados y pueden
   cargarse;
10. comprueba Pyright con un proyecto Python real y conserva las pruebas de
    LuaLS, servidores web y Tailwind;
11. valida los atajos de búsqueda y los ejecutables `fzf` y `rg`;
12. comprueba el layout tmux, las sesiones de proyecto y el transporte de
    contexto hacia el panel de agente;
13. guarda el informe en la raíz indicada mediante `NVIM_XDG_ROOT`.

`NVIM_TEST_FILE` permite sustituir temporalmente la prueba Lua para comprobar el
propio runner. Se verificó originalmente con ambas versiones que un archivo que
ejecuta `error()` produce estado de salida no cero. La comprobación vigente usa
0.12.4, que es la versión mínima requerida por la configuración actual.

## Rutas utilizadas

| Finalidad | Ruta durante las pruebas |
| --- | --- |
| Configuración | `./nvim` |
| Datos | `./.xdg/0.12.4/data/nvim` |
| Estado | `./.xdg/0.12.4/state/nvim` |
| Caché | `./.xdg/0.12.4/cache/nvim` |
| Sockets de ejecución | `./.xdg/0.12.4/runtime` |
| Plugins descargados | `./.xdg/0.12.4/data/nvim/lazy` |
| Informe de salud | `./.xdg/0.12.4/checkhealth.txt` |
| Corepack aislado | `./.xdg/0.12.4/corepack` |
| Almacén pnpm | `./.xdg/0.12.4/pnpm/store` |
| Ejecutables LSP web | `./tools/lsp-web/node_modules/.bin` |
| Ejecutables LSP Python | `./tools/lsp-python/node_modules/.bin` |
| LuaLS | `~/.local/opt/lua-language-server-3.19.0` |
| Logs de LuaLS | `./.xdg/0.12.4/state/nvim/luals` |

`.xdg/` es temporal, reproducible y está ignorado por Git. Puede retirarse sin
afectar a la configuración activa; los scripts lo recrean cuando es necesario.
El directorio `runtime` usa permisos `0700`, como exige la especificación XDG.
`node_modules` también está ignorado por Git; `package.json`,
`pnpm-workspace.yaml` y `pnpm-lock.yaml` son la fuente reproducible versionada.

`LSP_WEB_BIN` permite probar otro directorio de ejecutables sin cambiar el
`PATH`. El runner lo publica dentro de Neovim como
`ENTORNO_NVIM_LSP_WEB_BIN`; normalmente no hace falta definirlo.

`LSP_PYTHON_BIN` hace lo mismo para el directorio que contiene
`pyright-langserver`. El runner lo publica como
`ENTORNO_NVIM_LSP_PYTHON_BIN` y falla con una instrucción concreta cuando no se
ha ejecutado todavía `scripts/instalar-lsp-python.sh`.

`LUALS_BIN` permite seleccionar otro binario de LuaLS. El valor predeterminado
es `~/.local/opt/lua-language-server-3.19.0/bin/lua-language-server`; se pasa a
Neovim como `ENTORNO_NVIM_LUALS_BIN`, sin añadirlo al `PATH` global. El
instalador admite `LUALS_OPT_ROOT` para probar la instalación en otra raíz.

La comparación original se ejecutó sin compartir caché, estado, sockets ni
plugins. Tras incorporar nvim-treesitter, la configuración requiere 0.12.4 y la
orden de 0.11.4 se conserva solo como referencia histórica:

```sh
NVIM_BIN=/usr/local/bin/nvim \
NVIM_XDG_ROOT="$PWD/.xdg/0.11.4" \
NVIM_EXPECTED_VERSION=0.11.4 \
./scripts/comprobar.sh

NVIM_BIN="$HOME/.local/opt/nvim-0.12.4/bin/nvim" \
NVIM_XDG_ROOT="$PWD/.xdg/0.12.4" \
NVIM_EXPECTED_VERSION=0.12.4 \
./scripts/comprobar.sh
```

La primera orden termina ahora con el mensaje de versión mínima esperado. La
segunda es la comprobación vigente.

## AppImage actual

El Neovim instalado es un AppImage. En entornos sin FUSE, los scripts definen
`APPIMAGE_EXTRACT_AND_RUN=1` para que el propio AppImage se extraiga de manera
temporal. No sustituyen ni modifican `/usr/local/bin/nvim`.
