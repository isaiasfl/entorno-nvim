# Guía del alumno

> **Para la primera clase usa la instalación mínima.** El instalador completo
> se conserva para prácticas posteriores que necesiten LSP, parsers o PDF.

## Instalación mínima recomendada (Ubuntu, Pop!_OS y WSL2)

```sh
git clone https://github.com/isaiasfl/entorno-nvim.git
cd entorno-nvim
./scripts/instalar-alumno.sh --sistema
```

Este carril instala únicamente los paquetes básicos que falten (`git`, `tmux`,
`curl`, `tar` y certificados), descarga un Neovim Linux local y verificado e
instala los plugins fijados. No requiere el Neovim antiguo de Ubuntu y no usa
un posible `nvim.exe` de Windows heredado por WSL2.

No instala Node, servidores LSP, Tree-sitter CLI, parsers, Pandoc, navegador,
Poppler, LazyGit, `fzf`, `fd` ni `ripgrep`. Tampoco instala clientes de IA ni
gestiona credenciales. Para comprobar el estado sin modificar nada:

```sh
./scripts/instalar-alumno.sh --comprobar
```

Para abrir el perfil de Sistemas Informáticos con la integración de IA:

```sh
./bin/entorno-dev --perfil si --ia /ruta/al/proyecto
```

La IA se podrá seleccionar solamente si el alumno ya tiene instalado y
configurado un cliente compatible. El editor y tmux funcionan sin él.

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

- Sin opciones abre el perfil `profesor` con tmux, editor, agente y terminal.
- `--perfil dwec` (web), `--perfil si` (Python), `--perfil inicial` o
  `--perfil profesor` (predeterminado).
- Para clase, añade `--perfil dwec --sin-ia` a cualquiera de los dos comandos
  anteriores si solo necesitas el editor y la terminal.
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
| `<leader>w` | Guardar (`leader` es `Espacio`) |
| `<leader>gg` | Lazygit desde Neovim |
| `gd`, `grr`, `grn`, `K` | Definición, referencias, renombrar, ayuda |
| `<leader>ut` | Cambiar tema visual |
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

**Quiero que `entorno-dev` esté en el `PATH`.**
Opcionalmente: `./scripts/instalar-entorno-dev.sh`. Crea el enlace en
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
