# Activación en el equipo principal

> Procedimiento historico V1. No es necesario para el entorno docente y no
> debe usarse para convivir con Omarchy: sustituye `~/.config/nvim`.
> Use el [lanzador separado](entorno-docente.md).

## Estado previo inventariado

El 9 de agosto de 2026, antes de activar este repositorio, se comprobó:

| Elemento | Estado previo |
| --- | --- |
| `~/.config/nvim` | Directorio real, modo `0755`, 2,6 MiB |
| Configuración | LazyVim 8; `init.lua` cargaba `config.lazy` y existía `lazyvim.json` |
| `~/.local/bin/nvim` | No existía |
| `nvim` resuelto por la shell | `/usr/local/bin/nvim` |
| `/usr/local/bin/nvim` | AppImage Neovim 0.11.4, conservado sin cambios |
| Neovim nuevo | `~/.local/opt/nvim-0.12.4/bin/nvim`, versión 0.12.4 |
| Precedencia | `~/.local/bin` aparecía antes que `/usr/local/bin` en `PATH` |

SHA-256 de los binarios inventariados:

```text
79e7e160f9505819a5e12f3d9366be94213f5309fb912ef4ef3af52df3982977  /usr/local/bin/nvim
caf8f91f51241216ce62110338aa45848896cfd27e82282353fdd9e2038f5552  ~/.local/opt/nvim-0.12.4/bin/nvim
```

También se inventariaron los datos anteriores de Neovim:

| Ruta | Tamaño previo aproximado |
| --- | --- |
| `~/.local/share/nvim` | 621 MiB |
| `~/.local/state/nvim` | 1,9 MiB |
| `~/.cache/nvim` | 77 MiB |

No se inspeccionó el contenido potencialmente sensible de estado, caché,
deshacer o sesiones. La configuración nueva usa
`~/.local/share/nvim/entorno-nvim` para sus propios plugins y parsers, de modo
que no comparte sus revisiones con LazyVim. El primer intento de arranque,
anterior a este aislamiento, llegó a añadir repositorios de plugins que
faltaban bajo `~/.local/share/nvim/lazy`; no se borraron ni se sustituyeron los
datos antiguos. LazyVim conserva su configuración y puede volver a sincronizar
su lockfile durante un rollback.

## Activación reversible

Desde la raíz del repositorio:

```sh
./scripts/activar.sh
```

El script comprueba que no se ejecuta como root, que `~/.local/bin` precede a
`/usr/local/bin`, que los destinos existen y que el backup fechado no colisiona.
Después:

1. mueve íntegramente la configuración activa anterior a un backup fechado
   bajo `~/copias-seguridad`;
2. crea `~/.config/nvim` como symlink al directorio `nvim/` del checkout actual;
3. crea `~/.local/bin/nvim` como symlink al binario 0.12.4;
4. registra el último backup en
   `~/.local/state/entorno-nvim/ultimo-backup` con permisos `0600`.

Cada activación registra su ruta concreta bajo
`~/copias-seguridad/nvim-activa-AAAAMMDD-HHMMSS`. Las copias históricas que ya
existían permanecen separadas e intactas.

Si una operación falla antes de terminar, el script revierte los movimientos
que haya realizado. No modifica archivos de shell, `/usr/local/bin/nvim` ni el
AppImage 0.11.4.

## Verificación

```sh
which nvim
nvim --version
readlink ~/.config/nvim
nvim --headless '+lua print(vim.fn.stdpath("config"))' +qa
```

El resultado esperado es `~/.local/bin/nvim`, Neovim 0.12.4 y la configuración
del repositorio. En el primer arranque, Lazy instala las revisiones exactas del
lockfile bajo `~/.local/share/nvim/entorno-nvim`. Los parsers se instalaron con
el `tree-sitter-cli` 0.26.11 ya disponible. `scripts/arrancar.sh` continúa
disponible para pruebas con XDG aislado. La configuración antepone ese CLI
solo al `PATH` de su propio proceso; no cambia el `PATH` de la shell.

## Restauración

Para restaurar el último backup registrado:

```sh
./scripts/restaurar.sh
```

También se puede indicar expresamente otro backup creado por `activar.sh`:

```sh
./scripts/restaurar.sh ~/copias-seguridad/nvim-activa-AAAAMMDD-HHMMSS
```

La restauración se niega a actuar si los symlinks actuales ya no apuntan a este
repositorio y al binario fijado. Copia la configuración anterior desde el
backup, conserva ese backup para usos posteriores y retira el symlink de
`~/.local/bin/nvim` cuando antes no existía. Así, la shell vuelve a resolver
`/usr/local/bin/nvim` y conserva disponible el AppImage 0.11.4.
