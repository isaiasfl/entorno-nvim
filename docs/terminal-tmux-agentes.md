# Terminal, tmux y agentes

## Arquitectura aislada

Cada proyecto usa una sesión tmux independiente con este layout inicial:

```text
Neovim | agente
----------------
     terminal
```

El flujo usa por defecto el servidor dedicado `entorno-nvim`, mediante
`tmux -L entorno-nvim`. Así no carga opciones, atajos ni sesiones en el servidor
tmux personal del usuario. Puede elegirse otro nombre antes de arrancar:

```sh
export ENTORNO_TMUX_SOCKET=otro-entorno
./scripts/proyecto.sh /ruta/al/proyecto
```

Para inspeccionar o recuperar el servidor predeterminado se usan, por ejemplo,
`tmux -L entorno-nvim list-sessions` y `tmux -L entorno-nvim attach`.
`proyecto.sh` solo crea el layout cuando la sesión no existe: al reconectar
conserva paneles, procesos, tamaños y ventanas.

La configuración versionada está en `tmux/tmux.conf`. Se validó con tmux 3.5a
en Debian 13 y no usa TPM, plugins, `tmux-resurrect` ni
`vim-tmux-navigator`. CachyOS y macOS necesitan una versión moderna de tmux,
pero la ejecución real en esos sistemas todavía no se ha verificado.

tmux es la única dependencia específica de esta fase. Estos comandos son solo
referencias para una instalación aprobada expresamente en cada sistema; esta
revisión no instaló paquetes:

```sh
# Debian
sudo apt install tmux

# CachyOS / Arch
sudo pacman -S tmux

# macOS con Homebrew
brew install tmux
```

En macOS también debe comprobarse que el emulador de terminal conoce el tipo
`tmux-256color`.

## Selección de proyectos

Las raíces se configuran explícitamente mediante una lista separada por dos
puntos; nunca se recorre todo el directorio personal:

```sh
export ENTORNO_TMUX_PROJECT_ROOTS="$HOME/Proyectos:$HOME/Projects"
./scripts/proyecto.sh
```

El selector reconoce `fd` y `fdfind`, repositorios normales y worktrees. Si se
cancela fzf, termina sin crear una sesión parcial. También puede abrirse una
ruta concreta:

```sh
./scripts/proyecto.sh /ruta/al/proyecto
```

El nombre de sesión combina el nombre limpio del directorio con una suma de su
ruta canónica. Esto evita colisiones sin dejar un guion bajo espurio al final.
`NVIM_BIN` permite escoger Neovim o un wrapper; para esta configuración aislada:

```sh
NVIM_BIN="$PWD/scripts/arrancar.sh" ./scripts/proyecto.sh "$PWD"
```

Al salir de Neovim, el panel de trabajo vuelve a su shell en vez de desaparecer.
Puede abrirse de nuevo con `nvim .` o con el wrapper correspondiente. Volver a
ejecutar `proyecto.sh` conecta con la sesión existente sin reconstruir el layout.

## Teclas y tmux anidado

El prefijo permanece en `Ctrl-b`.

| Tecla | Acción |
| --- | --- |
| `Ctrl-b h/j/k/l` | Cambiar de panel |
| `Ctrl-b H/J/K/L` | Redimensionar panel |
| `Ctrl-b \|` / `Ctrl-b -` | Dividir a derecha / debajo |
| `Ctrl-b c` | Crear una ventana |
| `Ctrl-b z` | Maximizar o restaurar el panel |
| `Ctrl-b [` | Entrar en modo copia Vi |
| `Ctrl-b s` | Elegir una sesión |
| `Ctrl-b d` | Separarse sin detenerla |
| `Ctrl-b Ctrl-b` | Enviar el prefijo a un tmux remoto |

Dentro de Neovim, `Ctrl-h/j/k/l` sigue navegando entre splits. Para cruzar a
tmux se pulsa primero `Ctrl-b`.

Ejecutar `proyecto.sh` desde el mismo servidor dedicado cambia de cliente sin
anidar tmux. Si se detecta que la terminal ya pertenece a otro socket, el script
se detiene con un mensaje claro: hay que separarse y lanzarlo desde una terminal
externa. En una sesión SSH con tmux remoto, `Ctrl-b Ctrl-b` envía el prefijo al
servidor remoto. Esta política mínima evita anidamientos locales ambiguos; el
flujo SSH real aún no se ha probado en este equipo.

## Destino seguro para el contexto

El panel derecho se marca con `@entorno_role=agent`, pero comienza como una
shell. Antes de pegar, el transporte consulta su `pane_current_command` y exige
exactamente un panel con ese rol.

Las shells `bash`, `sh`, `dash`, `zsh`, `fish`, `ksh`, `tcsh` y `nu` se deniegan
siempre. Un proceso desconocido también se deniega por defecto y el error indica
el valor detectado y cómo autorizar un agente nuevo. Los agentes conocidos por
defecto son `codex`, `opencode`, `claude`, `pi` y `jarvis-coder`, sin que esta
lista cierre la arquitectura a otros proveedores.

En este Debian se midieron estos valores reales:

| Cliente disponible | `pane_current_command` observado |
| --- | --- |
| Codex | `node` de forma persistente |
| OpenCode | `node` al arrancar; después `opencode` |
| Claude Code | `env` al arrancar; después `claude` |
| Bash / sh / dash | `bash` / `sh` / `dash` |
| pi / jarvis-coder | No estaban instalados; no se midieron |

Por tanto, `node` no se permite globalmente: también podría ser una aplicación
arbitraria. Para agentes envueltos por Node u otro proceso se usa el lanzador
agnóstico, que asocia temporalmente una identidad permitida con el proceso real:

```sh
$ENTORNO_NVIM_ROOT/scripts/agente.sh --name codex --process node codex
```

Al terminar el cliente, el lanzador retira esa asociación. La identidad solo es
válida mientras el proceso observado siga coincidiendo, por lo que volver a una
shell no deja una autorización obsoleta.

Para añadir un agente nuevo sin cambiar código, se amplía la lista y se inicia
directamente o mediante el lanzador. La variable admite espacios, comas o dos
puntos:

```sh
export ENTORNO_AGENT_ALLOWED_COMMANDS="mi-agente otro-agente"
$ENTORNO_NVIM_ROOT/scripts/agente.sh \
  --name mi-agente --process node mi-agente
```

La variable debe estar en el entorno de Neovim y del panel de agente. Ni este
flujo ni el lanzador instalan, configuran o leen credenciales de proveedores.

## Envío desde Neovim

`<leader>ac` (`Espacio a c`) envía metadatos de proyecto, archivo y posición,
además del prompt solicitado. En modo visual añade rango, tipo y texto exacto;
se soportan selecciones por caracteres, líneas y bloque. El modo normal no lee
el archivo completo.

El payload se codifica como JSON en una sola línea, se escribe con modo `0600`
en el directorio runtime `agent-context` de modo `0700`, se carga en un buffer
interno de tmux y se pega mediante bracketed paste. No usa el portapapeles y
nunca envía Enter: el usuario debe revisar el texto y enviarlo manualmente.

El límite predeterminado es 32768 bytes. Lua calcula un único valor efectivo y
lo entrega al transporte, de modo que ambas capas respetan el mismo override:

```sh
export ENTORNO_AGENT_CONTEXT_MAX_BYTES=65536
```

Tras un envío correcto se eliminan el temporal y el buffer tmux. Ante un error,
el temporal se conserva y el mensaje muestra su ruta. En cada intento se purgan
solo archivos regulares propios con forma `context-<pid>-<nonce>.json` de más de
24 horas dentro del directorio runtime. No se siguen enlaces simbólicos ni se
borran nombres ajenos.

Se bloquean preventivamente `.env*`, `.git-credentials`, `.netrc`, `.npmrc`,
`.pypirc`, `.pgpass`, `.my.cnf`, `.s3cfg`, claves `*.pem`, `*.key`, `*.p12`,
`.kube/config`, `.docker/config.json` y rutas bajo `.ssh`, `.gnupg` o
`.password-store`, además de algunos nombres habituales de credenciales. Es una
barrera para errores comunes, no un sistema DLP: el usuario debe revisar siempre
el contexto y no seleccionar secretos.

## Flujo y recuperación

1. Ejecutar `scripts/proyecto.sh` y escoger el repositorio.
2. Arrancar en el panel derecho el agente directamente o con `scripts/agente.sh`.
3. Trabajar en Neovim y usar `<leader>ac` en modo normal o visual.
4. Revisar el contexto pegado en el agente y pulsar Enter manualmente.
5. Usar el panel inferior para pruebas y servidores.
6. Separarse con `Ctrl-b d`; `proyecto.sh` recupera después la misma sesión.

Un reinicio elimina los procesos de tmux; el script recrea el layout, pero no
las conversaciones. Su reanudación corresponde a cada cliente. OpenCode,
JARVIS y otros proveedores no se configuran en esta fase.
