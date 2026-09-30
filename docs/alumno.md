<img src="../IMG/logo.png" alt="entorno-nvim · IFL" width="560">

# Guía del alumno

> **Para la primera clase usa la instalación esencial.** El instalador completo
> se conserva para prácticas posteriores que necesiten LSP web, parsers o PDF.

## Instalación esencial recomendada (Ubuntu, Pop!_OS y WSL2)

```sh
git clone https://github.com/isaiasfl/entorno-nvim.git
cd entorno-nvim
./scripts/instalar-alumno.sh
```

El instalador pregunta la asignatura (**1 = DWEC**, **2 = SI**) y la recuerda:
para actualizar basta con repetir el comando y pulsar Enter. Si faltan
programas del sistema, muestra el comando y pregunta antes de usar `sudo`.

Este carril instala los paquetes básicos que falten (`git`, `tmux`, `fzf`,
`fd-find`, `ripgrep`, `curl`, `tar`, `xz-utils` y certificados), descarga
Neovim y Node 24 locales y verificados e instala los plugins y servidores de
HTML, CSS, JSON, JavaScript, TypeScript y Tailwind con versiones fijadas. No
requiere el Neovim antiguo de Ubuntu y no usa un posible `nvim.exe` de Windows
heredado por WSL2.

El perfil **SI** (Sistemas Informáticos) instala en su lugar Bash Language
Server, ShellCheck y Pyright.

No instala Tree-sitter CLI, parsers externos, Pandoc, navegador, Poppler ni
LazyGit. Tampoco instala clientes de IA ni gestiona credenciales. Para comprobar
el estado sin modificar nada:

```sh
./scripts/instalar-alumno.sh --comprobar
```

Para abrir un proyecto (usa el perfil instalado, sin IA):

```sh
entorno-dev /ruta/al/proyecto
```

La terminal del perfil incluye `node`, `npm`, `npx` y el compilador `tsc`
fijado por el entorno. Para una comprobación rápida use `tsc --noEmit archivo.ts`.
Use `npx tsc` solamente cuando el proyecto declare `typescript` en sus
`devDependencies`; de lo contrario npm puede descargar el paquete homónimo
incorrecto llamado `tsc`.

La IA se podrá seleccionar solamente si el alumno ya tiene instalado y
configurado un cliente compatible. El editor y tmux funcionan sin él. El
instalador crea `~/.local/bin/entorno-dev` sin sobrescribir contenido ajeno y
avisa si hace falta añadir `~/.local/bin` al `PATH` de la terminal actual.

### Actualizar

Guarda tu trabajo y, desde la carpeta `entorno-nvim`:

```sh
./scripts/actualizar.sh
```

La primera vez, si tu copia aún no tiene `actualizar.sh`:
`git restore . && git pull --ff-only && sh scripts/actualizar.sh`.

### Perfil SI: ShellCheck es imprescindible

En Bash, todos los errores y avisos los detecta ShellCheck. El instalador SI
lo exige; si falta, Neovim avisa al abrir un `.sh`. Compruébalo con
`shellcheck --version`.

### Ortografía en español e inglés

Se activa sola en Markdown, texto y mensajes de commit (no en el código).
`Espacio us` la activa o desactiva, `]s`/`[s` saltan entre faltas, `z=`
sugiere y `zg` añade una palabra como correcta. No necesita `hunspell`: el
diccionario de Neovim se descarga verificado dentro del entorno.

## Instalación completa (avanzada)

Esta guía instala el entorno **sin `sudo`**, sin sustituir tu Neovim y sin tocar
tu configuración personal de tmux, Neovim o shell. Todo queda dentro de la
carpeta del repositorio clonado.

## 1. Requisitos del sistema

El instalador solo necesita herramientas básicas. Copia el comando que
corresponda a tu plataforma en una terminal (esto sí usa `sudo` y lo decides tú):

| Plataforma | Comando orientativo |
| --- | --- |
| Debian / Ubuntu / WSL2 (Ubuntu) | `sudo apt install git tmux fzf fd-find ripgrep lazygit chromium poppler-utils curl unzip build-essential` |
| Arch / CachyOS / Omarchy | `sudo pacman -S git tmux fzf fd ripgrep lazygit chromium poppler curl unzip base-devel` |
| macOS | `brew install git tmux fzf fd ripgrep lazygit poppler` |

- **Node no hace falta instalarlo**: el propio instalador descarga Node 24 LTS
  verificado dentro del repositorio.
- **Pandoc es opcional** (solo para exportar Markdown a PDF en el perfil
  `profesor`).
- En **WSL2**, el navegador es opcional: sin él funciona todo salvo la
  exportación a PDF y el visor externo.

## 2. Clonar e instalar

```sh
git clone https://github.com/isaiasfl/entorno-nvim.git
cd entorno-nvim
./scripts/instalar.sh
```

Un solo comando hace todo:

1. Comprueba qué falta y separa **imprescindibles** de **opcionales**.
2. Descarga e instala sin `sudo` todo lo que va dentro del repositorio: Node 24
   LTS verificado, Neovim, LuaLS, tree-sitter, plugins, parsers y servidores LSP.
3. Si faltan paquetes **imprescindibles del sistema** (git, tmux, fzf, lazygit,
   Chromium…), muestra el comando exacto de tu distribución y se detiene.
4. Al terminar ejecuta `comprobar-requisitos.sh` y resume el estado.

`instalar.sh` es repetible: si algo ya está correcto, lo conserva. Los
**opcionales** (Pandoc, poppler) no bloquean; solo avisan.

### Si quieres que instale también los paquetes del sistema

```sh
./scripts/instalar.sh --sistema
```

Muestra el comando (`sudo apt install …` o `sudo pacman -S …`), **pide
confirmación** y solo entonces lo ejecuta con `sudo`. Es la forma cómoda de no
copiar comandos a mano.

### Solo quiero un diagnóstico

```sh
./scripts/comprobar-requisitos.sh
```

Este comando **no instala nada**: únicamente lee el estado y clasifica cada
componente en `OK`, `FALTA` (imprescindible) u `OPCIONAL`.

## 3. Abrir tu proyecto

Vuelve a tu carpeta de trabajo y lanza el entorno apuntando a ella:

```sh
cd /ruta/a/mi-proyecto
/ruta/a/entorno-nvim/bin/entorno-dev
```

O en un solo paso, desde cualquier carpeta:

```sh
/ruta/a/entorno-nvim/bin/entorno-dev /ruta/a/mi-proyecto
```

- Sin opciones usa el perfil elegido en `instalar-alumno.sh`, sin IA: editor
  arriba y terminal abajo.
- `--perfil dwec` (web), `--perfil si` (Bash y Python), `--perfil inicial` o
  `--perfil profesor` cambian el perfil solo para esa sesión.
- `--sin-tmux` abre solo Neovim; `--sin-ia` omite el panel de agente.
- `--elegir` abre el selector de proyectos.

Para abrir un archivo concreto sin tmux:

```sh
/ruta/a/entorno-nvim/scripts/arrancar.sh index.html
```

## 4. Atajos imprescindibles

| Atajo | Acción |
| --- | --- |
| `Ctrl-a g` | Abrir lazygit en la raíz del proyecto |
| `Ctrl-a ?` | Ayuda contextual por categorías |
| `Ctrl-a P` | Selector de proyectos (popup) |
| `Ctrl-a h/j/k/l` | Navegar entre paneles de tmux |
| `Ctrl-h/j/k/l` | Navegar entre splits de Neovim |
| `Espacio` y esperar | Ver ayuda de los atajos disponibles |
| `<leader>w` | Guardar (`leader` es `Espacio`) |
| `<leader>gg` | Lazygit desde Neovim |
| `gd`, `grr`, `grn`, `K` | Definición, referencias, renombrar, ayuda |
| `gl` / `<leader>ld` | Diagnósticos de la línea / de todo el archivo |
| `<leader>lj` o `/**` + `Enter` | Generar JSDoc desde la función JS/TS |
| `cabts` o `!` + `Ctrl+j` | Insertar cabecera TypeScript o plantilla HTML |
| `<leader>ut` | Cambiar tema visual |
| `<leader>us` / `]s` / `z=` | Ortografía: activar / siguiente falta / sugerencias |
| `<leader>mp` / `<leader>mv` | Generar PDF / generar y ver |

La lista completa está en [guia-completa-teclas.md](guia-completa-teclas.md).

## 5. Solución de problemas

**El instalador dice que falta Node o Corepack.**
Ejecuta `./scripts/instalar-node.sh`. Descarga Node 24 LTS verificado dentro de
`.tools/`. Si tu arquitectura no tiene artefacto fijado, instala Node 24 por tu
cuenta y vuelve a probar.

**En WSL2 no hay portapapeles del sistema.**
Si no usas WSLg, instala `win32yank` o comprueba que `clip.exe` y
`powershell.exe` están en el `PATH`. El entorno los detecta automáticamente.

**No se genera el PDF en WSL2.**
Falta un navegador. Instala `chromium` dentro de la distribución o usa Linux
nativo/macOS para el perfil `profesor`. El resto del entorno funciona igual.

**Windows, WSL2 o la ruta tienen espacios.**
El entorno admite rutas con espacios; escríbelas entre comillas.

**Aparece `^M` al final de las líneas o todos los archivos salen modificados.**
Git para Windows convirtió los finales de línea. Ejecuta
`./scripts/actualizar.sh` (o, la primera vez,
`git restore . && git pull --ff-only && sh scripts/actualizar.sh`): los corrige.

**El entorno está en `/mnt/c/...` (WSL2).**
Clónalo en tu carpeta de Linux (`cd ~ && git clone ...`): las carpetas de
Windows son lentas y no admiten los sockets de Neovim.

**He movido o vuelto a clonar la carpeta `entorno-nvim`.**
Cierra las sesiones antiguas con `tmux -L entorno-nvim kill-server` y repite
el instalador desde la carpeta nueva. Si la copia anterior ya no existe, el
comando `entorno-dev` se redirige solo; si existe, se pregunta antes.

**Quiero que `entorno-dev` esté en el `PATH`.**
Los instaladores ya lo preparan. Para repararlo: `./scripts/instalar-entorno-dev.sh`. Crea el enlace en
`~/.local/bin` sin sobrescribir nada ajeno.

**Uso ARM (Apple Silicon o WSL2 sobre ARM).**
Node sí se instala, pero Neovim, LuaLS y tree-sitter solo tienen artefacto
fijado para Linux/Windows x86_64 y macOS. Instálalos aparte y pásalos con
`NVIM_BIN` y `LUALS_BIN`.

## 6. Qué no hace

- Sin `--sistema` no ejecuta `sudo` ni instala paquetes del sistema.
- No reemplaza `~/.config/nvim` ni `~/.tmux.conf`.
- No descarga scripts remotos tipo `curl | sh`; cada descarga se verifica con
  SHA-256.
- No actualiza nada de forma automática.

### Ayuda, bloques y plantillas habituales

`Espacio ?` o F1 abre una ayuda de teclas; q o Esc la cierra. Puede desplazarse
con j/k. En modo normal, `ciw` cambia la palabra y permite escribir; `diw` la
borra; `viw` la selecciona. Dentro de las llaves de una función, `di{` borra su
contenido y `ci{` lo cambia. `da{` incluye las llaves, pero no la declaración.
`c` significa cambiar, `d` borrar y `v` seleccionar visualmente.

`za` alterna el pliegue bajo el cursor; `zc` cierra, `zo` abre, `zM` cierra todos
y `zR` abre todos. Inicialmente el código se muestra abierto.

En HTML: `!`, div, section, article, header, footer, main, nav, p, h1, h2, span,
ul, ol, li, table, thead, tbody, tr, td, th, form, input, label, select, option,
textarea, button, a, img, link:css, script:src y meta:vp.
En JSX/TSX: `rafce`, `rfce`, `rafc`, `rfc`, `us`/useState, `ue`/useEffect,
`ur`/useRef, `um`/useMemo, `uc`/useCallback, imp y clg. Los hooks requieren
importar su nombre desde react. Use Ctrl+j en insertar para ver o expandir
plantillas y Ctrl+l/Ctrl+h para pasar entre sus campos. No es Emmet: las
expresiones como `ul>li*5` no se expanden.

La ayuda incluye el esquema `h ← j ↓ k ↑ l →`, movimientos por palabras (`w`,
`b`, `e`), búsquedas en una línea (`f`, `t`, `;`, `,`) y `jk` rápido para salir
de insertar, además de Esc. El completado LSP se solicita también al escribir
letras, conservando los disparadores propios del servidor. Ctrl+Space solicita
sugerencias; Ctrl+n/Ctrl+p permite completar palabras del texto sin LSP.

### Acceso permanente al comando

Al terminar, ambos instaladores ofrecen añadir `~/.local/bin` al PATH.
Muestran el archivo de Bash, Zsh o Fish que se modificará y piden `s` para
aceptar. Enter rechaza. Guardan copia de un archivo existente y no duplican
su propia entrada. Abra una terminal nueva para usar `entorno-dev`.
En ejecuciones no interactivas o con una shell desconocida, no lo modifican.
`--yes` solo omite la pausa de inicio; no acepta este cambio de la shell.
