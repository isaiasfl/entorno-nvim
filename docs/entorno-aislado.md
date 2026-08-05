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

`Esc` conserva su funcionamiento normal y `kj` no está mapeado.

## Comprobación automática

```sh
./scripts/comprobar.sh
```

La comprobación:

1. arranca Neovim 0.11.4 en modo headless;
2. confirma que `stdpath("config")` apunta a `nvim/` en este repositorio;
3. confirma que `config.options`, `config.keymaps` y `config.autocmds` se
   cargaron;
4. valida el mapeo `jk`, su descripción y que `Esc` y `kj` no se remapearon;
5. ejecuta `checkhealth` y falla si el informe contiene errores;
6. guarda el informe en `.xdg/checkhealth.txt`.

## Rutas utilizadas

| Finalidad | Ruta durante las pruebas |
| --- | --- |
| Configuración | `./nvim` |
| Datos | `./.xdg/data/nvim` |
| Estado | `./.xdg/state/nvim` |
| Caché | `./.xdg/cache/nvim` |
| Informe de salud | `./.xdg/checkhealth.txt` |

`.xdg/` es temporal, reproducible y está ignorado por Git. Puede retirarse sin
afectar a la configuración activa; los scripts lo recrean cuando es necesario.

## AppImage actual

El Neovim instalado es un AppImage. En entornos sin FUSE, los scripts definen
`APPIMAGE_EXTRACT_AND_RUN=1` para que el propio AppImage se extraiga de manera
temporal. No sustituyen ni modifican `/usr/local/bin/nvim`.
