# Entorno aislado

## Propósito

La configuración se prueba sin leer ni escribir la configuración activa de
Neovim. No requiere enlaces simbólicos y no modifica el binario instalado.

## Arranque interactivo

Desde la raíz del repositorio:

```sh
./scripts/arrancar.sh
```

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

La comprobación:

1. arranca Neovim 0.11.4 en modo headless;
2. confirma que `stdpath("config")` apunta a `nvim/` en este repositorio;
3. confirma que `config.options`, `config.keymaps` y `config.autocmds` se
   cargaron;
4. valida los atajos conservados, añadidos y eliminados;
5. comprueba `list`, la sangría Python y el ajuste de Markdown;
6. verifica que `.editorconfig` puede prevalecer sobre la sangría base;
7. comprueba que undo y swap usan rutas XDG ignoradas por Git;
8. ejecuta `checkhealth` y falla si el informe contiene errores;
9. comprueba que Lazy y `fzf-lua` están registrados y pueden cargarse;
10. valida los atajos de búsqueda y los ejecutables `fzf` y `rg`;
11. guarda el informe en `.xdg/checkhealth.txt`.

## Rutas utilizadas

| Finalidad | Ruta durante las pruebas |
| --- | --- |
| Configuración | `./nvim` |
| Datos | `./.xdg/data/nvim` |
| Estado | `./.xdg/state/nvim` |
| Caché | `./.xdg/cache/nvim` |
| Sockets de ejecución | `./.xdg/runtime` |
| Plugins descargados | `./.xdg/data/nvim/lazy` |
| Informe de salud | `./.xdg/checkhealth.txt` |

`.xdg/` es temporal, reproducible y está ignorado por Git. Puede retirarse sin
afectar a la configuración activa; los scripts lo recrean cuando es necesario.
El directorio `runtime` usa permisos `0700`, como exige la especificación XDG.

## AppImage actual

El Neovim instalado es un AppImage. En entornos sin FUSE, los scripts definen
`APPIMAGE_EXTRACT_AND_RUN=1` para que el propio AppImage se extraiga de manera
temporal. No sustituyen ni modifican `/usr/local/bin/nvim`.
