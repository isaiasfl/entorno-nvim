# Restauración y recuperación

## Copias existentes

Las copias anteriores se conservan bajo `~/copias-seguridad`. Pueden contener
tokens, sesiones y archivos de deshacer sensibles, por lo que no deben
versionarse, sincronizarse ni inspeccionarse salvo necesidad concreta.

## Activación actual y copia adicional

La activación real se gestiona con `scripts/activar.sh`. Antes de sustituir
`~/.config/nvim`, el script conserva íntegramente la configuración activa en un
directorio fechado bajo `~/copias-seguridad`. La ruta exacta queda registrada
en `~/.local/state/entorno-nvim/ultimo-backup`.

`scripts/restaurar.sh` valida los destinos activos antes de retirar symlinks y
restaura una copia desde ese backup sin consumirlo. El procedimiento detallado
y el inventario previo están en [activacion.md](activacion.md).

Los directorios `~/.local/share/nvim`, `~/.local/state/nvim` y
`~/.cache/nvim` de la instalación anterior no se eliminan. La copia histórica
indicada arriba tampoco se modifica.

## Binario paralelo

Neovim 0.12.4 se activa mediante `~/.local/bin/nvim`, sin reemplazar
`/usr/local/bin/nvim`. El binario 0.11.4 puede seleccionarse expresamente:

```sh
NVIM_BIN=/usr/local/bin/nvim ./scripts/arrancar.sh
```

La configuración actual requiere 0.12.4, por lo que volver realmente a 0.11.4
exige además restaurar una revisión compatible del repositorio.

El directorio `~/.local/opt/nvim-0.12.4` solo debe eliminarse cuando ninguna
sesión lo esté usando y después de una aprobación explícita. La restauración
retira el symlink de usuario y deja que el `PATH` vuelva a encontrar el binario
0.11.4 conservado.
