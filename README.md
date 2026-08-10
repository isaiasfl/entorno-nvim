# entorno-nvim

## Qué es

`entorno-nvim` v1.0.0 es una configuración de Neovim y tmux comprensible,
versionada y reversible para programación, docencia y documentos Markdown.
La referencia probada es Debian 13 con Neovim 0.12.4.

## Qué incluye

- Neovim modular en Lua, dashboard IFL, búsqueda, explorador y Git.
- LSP nativo para Lua, web y Python; completado nativo de Neovim 0.12.
- Tree-sitter con ocho parsers externos fijados.
- sesiones tmux por proyecto en el socket dedicado `entorno-nvim`;
- Markdown → Pandoc → HTML/CSS → Chromium → PDF A4.

El [inventario V1](docs/inventario-v1.md) detalla componentes y versiones.

## Instalación rápida

```sh
git clone URL_DEL_REPOSITORIO entorno-nvim
cd entorno-nvim
./scripts/comprobar-requisitos.sh
./scripts/instalar.sh
./scripts/arrancar.sh
```

El instalador es idempotente, no usa `sudo`, no activa la configuración y no
elimina instalaciones anteriores. Si faltan paquetes del sistema, muestra un
comando orientativo y se detiene. Véase [instalación V1](docs/instalacion.md).

## Comprobar requisitos

```sh
./scripts/comprobar-requisitos.sh
```

Solo lee el estado y clasifica cada elemento como `OK`, `FALTA` u `OPCIONAL`.

## Activar

Tras probar el entorno aislado:

```sh
./scripts/activar.sh
```

Crea un backup fechado y enlaza `~/.config/nvim` al directorio `nvim/` del
repositorio. No modifica la configuración tmux personal. Detalles en
[activación](docs/activacion.md).

## Restaurar

```sh
./scripts/restaurar.sh
```

Restaura la configuración y el comando de Neovim anteriores desde el último
backup registrado. El backup histórico se conserva. Véase
[restauración](docs/restauracion.md).

## Flujo diario

```sh
export ENTORNO_TMUX_PROJECT_ROOTS="$HOME/Proyectos:$HOME/Projects"
./scripts/proyecto.sh
```

La sesión contiene Neovim, un panel de agente y una shell para pruebas o
servidores. La [chuleta diaria](docs/chuleta.md) resume los comandos habituales.

## Neovim

`./scripts/arrancar.sh` ejecuta Neovim con datos, caché, estado y sockets XDG
aislados. La configuración activa usa el mismo código mediante un enlace
simbólico reversible. [Arquitectura aislada](docs/entorno-aislado.md).

## tmux

El flujo usa `tmux -L entorno-nvim` y no carga ni altera `~/.tmux.conf`.
`Ctrl-b P` abre el selector de proyectos en un popup. Más detalles en
[terminal y tmux](docs/terminal-tmux-agentes.md).

## Agentes

El panel derecho admite agentes CLI intercambiables. `<leader>ac` pega contexto
solo tras validar el proceso de destino y nunca envía Enter. El entorno no
instala agentes ni gestiona sus credenciales.

## Markdown/PDF

`<leader>mp` genera el PDF real y `<leader>mv` lo genera y abre en el visor
externo. Cabecera y pie usan `module`, `centre` y `teacher` del YAML. Véase
[Markdown/PDF](docs/markdown-pdf.md).

## LSP

LuaLS 3.19.0, los servidores web fijados y Pyright 1.1.411 se instalan de forma
aislada, sin Mason ni npm global. BashLS sigue aplazado. Véase
[LSP y completado](docs/lsp.md).

## Mappings principales

| Mapa | Acción |
| --- | --- |
| `<leader>w` | Guardar |
| `<leader>gg` | Lazygit |
| `<leader>mp` / `<leader>mv` | Generar PDF / generar y visualizar |
| `<leader>ac` | Pegar contexto revisable en el agente |
| `gd`, `grr`, `grn`, `K` | Definición, referencias, rename y hover LSP |
| `Ctrl-h/j/k/l` | Navegar splits de Neovim |
| `Ctrl-b h/j/k/l` | Navegar paneles tmux |
| `Ctrl-b P` | Selector de proyectos tmux |

## Portabilidad

Probado: Debian 13 x86_64. Objetivo no probado: Arch/CachyOS x86_64 y macOS
moderno. Los scripts evitan incompatibilidades BSD evidentes, pero no se afirma
validación real fuera de Debian. Consulta [instalación V1](docs/instalacion.md).

## Seguridad

No se versionan secretos, estado de editores, credenciales ni configuraciones
privadas de agentes. El contexto hacia agentes tiene una barrera preventiva,
no un DLP. El compilador PDF solo está diseñado para Markdown propio y fiable.

## Actualización

Actualizar una versión fijada exige revisar origen, checksum o lockfile,
ejecutar `./scripts/comprobar.sh` y revisar el diff antes de confirmar. No hay
actualizaciones automáticas de plugins, parsers ni LSP.

## Desinstalación

Primero ejecuta `./scripts/restaurar.sh`. Después pueden retirarse manualmente
la raíz XDG del repositorio y los directorios versionados de `~/.local/opt`
cuando ningún proceso los use. El proyecto nunca borra backups automáticamente.
