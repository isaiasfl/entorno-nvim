# Terminal, tmux y agentes

## Arquitectura

Cada proyecto usa una sesion tmux independiente con un layout inicial de tres
paneles:

```text
Neovim | agente
----------------
     terminal
```

El panel derecho comienza como una shell normal. No se inicia ni configura
automaticamente Codex, OpenCode, JARVIS u otro proveedor. El usuario ejecuta en
ese panel el agente que necesite; la sesion y el transporte de contexto no
conocen su identidad.

El layout solo se crea al crear la sesion. Al volver a un proyecto existente se
conservan sus paneles, procesos, tamanos y ventanas tal como esten.

## Instalacion de tmux

tmux es la unica dependencia nueva. Se valido con tmux 3.5a de Debian 13. La
configuracion no usa TPM, plugins,
tmux-resurrect, continuum ni `vim-tmux-navigator`.

Comandos de referencia, que deben ejecutarse expresamente en cada sistema:

```sh
# Debian
sudo apt install tmux

# CachyOS/Arch
sudo pacman -S tmux

# macOS con Homebrew
brew install tmux
```

La configuracion versionada esta en `tmux/tmux.conf`. `scripts/proyecto.sh` la
carga al crear el servidor y la vuelve a cargar cuando el servidor ya existe.
No es necesario copiarla a `~/.tmux.conf` para usar el flujo del repositorio.

## Seleccion de proyectos

Las raices se configuran de forma explicita mediante una lista separada por dos
puntos. El selector nunca recorre todo el directorio personal:

```sh
export ENTORNO_TMUX_PROJECT_ROOTS="$HOME/Proyectos:$HOME/Projects"
./scripts/proyecto.sh
```

Sin argumento, `proyecto.sh` busca marcadores `.git` solo bajo esas raices y
presenta los resultados con fzf. Detecta indistintamente `fd` y `fdfind`. Los
directorios `.git` normales y los archivos `.git` de los worktrees se
reconocen, aunque esta fase no crea ni administra worktrees.

Tambien puede abrirse una ruta concreta sin usar el selector:

```sh
./scripts/proyecto.sh /ruta/al/proyecto
```

Si la ruta pertenece a un repositorio, se usa su raiz Git. El nombre de sesion
combina el nombre del directorio con una suma derivada de su ruta canonica para
evitar colisiones entre proyectos y worktrees con nombres iguales.

`NVIM_BIN` permite escoger el ejecutable o wrapper de Neovim. Para probar esta
configuracion aislada desde el propio repositorio:

```sh
NVIM_BIN="$PWD/scripts/arrancar.sh" ./scripts/proyecto.sh "$PWD"
```

En una configuracion ya activada basta con el valor predeterminado `nvim`.

## Teclas de tmux

El prefijo permanece en su valor estandar, `Ctrl-b`.

| Tecla | Accion |
| --- | --- |
| `Ctrl-b h/j/k/l` | Moverse al panel izquierdo/inferior/superior/derecho |
| `Ctrl-b H/J/K/L` | Redimensionar en esas direcciones |
| `Ctrl-b \|` | Crear un panel a la derecha |
| `Ctrl-b -` | Crear un panel debajo |
| `Ctrl-b c` | Crear una ventana |
| `Ctrl-b z` | Maximizar o restaurar el panel actual |
| `Ctrl-b [` | Entrar en modo copia Vi |
| `Ctrl-b s` | Elegir una sesion |
| `Ctrl-b d` | Separarse sin detener la sesion |

Las divisiones y ventanas nuevas heredan el directorio del panel actual. El
raton esta desactivado, los indices empiezan en 1 y las ventanas se renumeran.
Se habilitan truecolor y eventos de foco mediante opciones compatibles con
tmux moderno en Linux y macOS.

Dentro de Neovim, `Ctrl-h/j/k/l` sigue navegando entre sus splits. Para cruzar
a otro panel de tmux se usa primero `Ctrl-b` y despues la misma direccion. Esta
separacion explicita evita plugins y reglas especiales segun el proceso activo.

## Panel de agente

El panel del agente se identifica mediante la opcion de panel de tmux:

```text
@entorno_role=agent
```

Su posicion puede cambiar despues de crear la sesion. El transporte busca el
metadato dentro de la sesion, no coordenadas ni numeros de panel. Debe existir
exactamente un panel con ese rol.

Para iniciar un agente, entrar en el panel con `Ctrl-b l` y ejecutar manualmente
el cliente deseado, por ejemplo `codex`, `opencode` o, cuando exista,
`jarvis-coder`. Ningun proveedor ni credencial se configura aqui.

## Enviar contexto desde Neovim

`<leader>ac`, literalmente `Espacio a c`, queda reservado dentro del prefijo
conceptual `<leader>a` para acciones futuras de agentes.

- En modo normal envia proyecto, ruta relativa del archivo, linea, columna y
  el prompt solicitado mediante `vim.ui.input()`.
- En modo visual anade el tipo de seleccion, el rango exacto y el texto
  seleccionado.
- El modo normal no lee ni envia el contenido completo del archivo.

El mensaje se codifica como JSON en una sola linea, con un limite de 32 KiB. Se
escribe temporalmente bajo `XDG_RUNTIME_DIR` con permisos `0600`, se carga en un
buffer interno de tmux y se pega con bracketed paste. No usa el portapapeles del
sistema y no envia Enter: hay que revisar el prompt en el agente y pulsar Enter
manualmente.

Tras un envio correcto se eliminan el archivo temporal y el buffer auxiliar de
tmux. Si Neovim no esta dentro de tmux, no existe el panel `agent`, hay mas de
uno o falla el pegado, se muestra un error con la ruta y el archivo se conserva
para no perder el contexto.

La configuracion rechaza `.env`, rutas SSH, almacenes de contrasenas, keyrings y
nombres habituales de archivos de credenciales o claves privadas. Esta barrera
no sustituye la revision humana: una seleccion visual es una decision explicita
de compartir ese texto con el agente que el usuario haya iniciado.

## Flujo diario

1. Ejecutar `scripts/proyecto.sh` y escoger el repositorio con fzf.
2. Trabajar en Neovim en el panel izquierdo.
3. Entrar en el panel derecho con `Ctrl-b l` y arrancar manualmente el agente.
4. Usar el panel inferior para pruebas, servidores y comandos de desarrollo.
5. En Neovim, situarse en una linea o seleccionar codigo y pulsar
   `<leader>ac`.
6. Escribir una solicitud de explicacion, revision o cambio.
7. Cambiar al agente, revisar el texto pegado y pulsar Enter.
8. Volver con `Ctrl-b h`; Neovim comprueba cambios externos al recuperar foco.
9. Usar `<leader>gg` para lazygit cuando haga falta.
10. Separarse con `Ctrl-b d` y recuperar despues la misma sesion.

## Recuperacion y limites

Volver a ejecutar `proyecto.sh` para la misma ruta conecta con la sesion
existente sin reconstruirla. Tambien se puede usar `tmux attach` o `Ctrl-b s`.
Cerrar el emulador no detiene la sesion, pero un reinicio del equipo si elimina
los procesos: el script recrea el layout, no las conversaciones.

Las funciones de reanudacion de conversaciones pertenecen a cada cliente de
agente. Mantenerlas fuera de esta capa permite usar el mismo flujo con Codex,
OpenCode, JARVIS y herramientas futuras, y adaptar la configuracion para
alumnos sin incluir servidores, tokens ni credenciales.

En macOS debe comprobarse que el terminal conoce `tmux-256color`. Las sesiones
anidadas y el uso remoto por SSH requeriran una evaluacion posterior. Los Git
worktrees ya pueden seleccionarse como proyectos separados, pero su creacion y
mantenimiento quedan fuera de esta fase.
