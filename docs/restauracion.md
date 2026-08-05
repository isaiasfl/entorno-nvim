# Restauración y recuperación

## Copia existente

La copia completa anterior se encuentra en:

```text
/home/isaiasfl/copias-seguridad/nvim-20260805-221016
```

Fue verificada en modo lectura el 5 de agosto de 2026 y ocupa aproximadamente
623 MB. Contiene copias de la configuración, datos y estado de Neovim. Puede
incluir tokens, sesiones y archivos de deshacer sensibles, por lo que no debe
versionarse, sincronizarse ni inspeccionarse salvo necesidad concreta.

## Política de restauración

Durante el desarrollo no se modifican `~/.config/nvim`,
`~/.local/share/nvim`, `~/.local/state/nvim` ni `~/.cache/nvim`. Las pruebas de
la configuración nueva deben usar rutas XDG temporales.

Antes de una futura activación se documentarán y probarán estos pasos:

1. Cerrar todas las instancias de Neovim.
2. Crear una copia incremental nueva de las rutas activas.
3. Validar el arranque aislado del repositorio.
4. Activar la configuración solo tras aprobación expresa.
5. Comprobar arranque, salud, plugins y herramientas.
6. Si falla, retirar únicamente la activación nueva y restaurar desde la copia.

Todavía no existe ni se ejecutará un script de restauración. Su implementación
deberá validar rutas exactas, evitar sobrescrituras silenciosas y ofrecer una
simulación antes de copiar datos.

## Binario paralelo

Neovim 0.12.4 se instala sin reemplazar `/usr/local/bin/nvim`. Para volver a
0.11.4 basta con omitir `NVIM_BIN` o indicar expresamente:

```sh
NVIM_BIN=/usr/local/bin/nvim ./scripts/arrancar.sh
```

El directorio `~/.local/opt/nvim-0.12.4` solo debe eliminarse cuando ninguna
sesión lo esté usando y después de una aprobación explícita. No hay enlaces ni
cambios de `PATH` que revertir.
