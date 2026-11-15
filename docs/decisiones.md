# Decisiones e inventario

## Validación HTML local (2026-10-23)

Dependencia directa `html-validate` 11.16.2 en `tools/lsp-web`, fijada por
versión exacta y lockfile. Compatible con el Node 24.21.0 ya distribuido;
publicada el 04/10, respeta la antigüedad mínima de siete días. No instala
herramientas globales ni otro plugin de Neovim. Sus dependencias transitivas
quedan fijadas por pnpm, con scripts de instalación bloqueados.

El servidor HTML existente no valida el marcado. Esta herramienta permite
señalar atributos desconocidos (`idddd`), ids repetidos, etiquetas desconocidas
y cierres incorrectos. La alternativa sencilla es validar manualmente fuera
del editor; compensa incorporarla para proporcionar diagnósticos al alumnado.
Fuente y API: https://html-validate.org/guide/api/getting-started.html.

El contenido se valida localmente por stdin, incluso sin guardar, sin enviar
archivos a servicios externos. Una configuración fija evita cargar plugins o
scripts de configuración del proyecto que se esté editando. Se priorizan
errores del marcado sobre preferencias de estilo y no se exige documento
completo a un fragmento HTML.

Se añadieron doce paquetes nuevos (dependencia directa y transitivas), sin
actualizar los servidores existentes. Se ignoran reglas de estilo y se aceptan
custom elements con guion. Pruebas funcionales: atributos, duplicados, cierre
de input, elementos desconocidos, limpieza al corregir, fragmentos, caracteres
Unicode y resultados obsoletos. La comunicación Node/Neovim requiere ejecutar
estas pruebas fuera del sandbox: dentro, Node no devuelve stdout mediante
vim.system en este entorno; fuera sí, comprobado con un proceso mínimo.

Auditoría pnpm del 23/10: 48 dependencias, cero avisos conocidos. La prueba
específica de Neovim pasa y la activación en la sesión del señor produjo tres
diagnósticos HTML, sin modificar su texto.

## Emmet con la misma tecla de las plantillas (2026-10-22)

Dependencia directa `mattn/emmet-vim`, commit
`92ef2f74f4093edc99db5e9e4cf7e40116a85bd6`, fijado también en lazy-lock.json.
Resuelve abreviaturas HTML/CSS, multiplicación y estructuras anidadas que las
plantillas estáticas no interpretan. Alternativa sencilla: snippets y duplicar
líneas; compensa añadirlo para aprender y escribir HTML con menos pasos.
No añade dependencias transitivas, builds, Node ni servidor LSP.
Fuente e instrucciones revisadas: https://github.com/mattn/emmet-vim.

Se carga solo en HTML/CSS y no instala sus atajos globales. Ctrl+j da prioridad
a una plantilla propia exacta; si no existe, expande Emmet. En línea vacía
conserva el selector de plantillas. Los otros lenguajes conservan mini.snippets,
incluido `clg` en JS/TS. Tab y los saltos Ctrl+l/h no se reasignan.
El plugin se instala con `scripts/instalar-plugins.sh` dentro del estado aislado
del repositorio; no se modifica la configuración activa de Neovim.

Verificación 22/10: `tests/comprobar_emmet.lua` pasa pulsando Ctrl+j mediante
feedkeys: repetición, ids, bloque DAW, script, `!`, `main`, `clg` en JS/TS y
plantilla/CSS Emmet dentro de una regla. Añadida a `scripts/comprobar.sh`.
Núcleo y edición pasan; checkhealth termina sin entradas ERROR, con avisos
de herramientas opcionales, tipos de archivo, depreciación y paquetes.
El sandbox bloquea sockets de Neovim/fzf; núcleo/edición/salud se comprobaron
fuera del sandbox, conservando los directorios aislados del repositorio.

## Objetivos entendidos

El objetivo técnico es construir una configuración Lua modular para Neovim
0.11.4, rápida, mantenible y portable. Debe cubrir progresivamente navegación,
búsqueda, LSP, completado, formato, diagnósticos, Git y Markdown, con versiones
de plugins bloqueadas y degradación razonable cuando falten herramientas.

El objetivo personal es ganar soltura real con Neovim y la terminal, reducir la
dependencia de los cursores y disponer de un flujo reproducible para preparar
exámenes en Markdown con imágenes, tablas y PDF. Los atajos deben resultar
cómodos en teclados de PC y Mac y no es necesario conservar `jk` para salir del
modo de inserción.

## Inventario del 5 de agosto de 2026

### Sistema y repositorio

- Debian GNU/Linux 13.6, arquitectura x86_64.
- Neovim 0.11.4 distribuido como AppImage en `/usr/local/bin/nvim`.
- El repositorio estaba en la rama `main`, sin commits previos.
- La identidad Git local o heredada está completa y no se ha modificado.

En el entorno de diagnóstico el AppImage no puede usar FUSE. Neovim sí responde
al ejecutarlo en modo de extracción temporal mediante
`APPIMAGE_EXTRACT_AND_RUN=1`; esta particularidad debe contemplarse en los
scripts de comprobación sin alterar el sistema.

### Configuración activa

La configuración activa ocupa unos 2,6 MB y parte de la plantilla de LazyVim.
Usa `lazy.nvim`, un lockfile y aproximadamente cuarenta plugins. Incluye extras
para TypeScript, ESLint, Prettier, Tailwind, Python, depuración, Markdown y
servicios de IA. También contiene personalizaciones de transparencia, scroll,
atajos, ortografía y exportación Markdown a PDF.

El flujo Markdown actual invoca Pandoc y WeasyPrint, depende de CSS y plantilla
ubicados fuera de la configuración de Neovim y abre el PDF con `xdg-open`.
WeasyPrint no está disponible actualmente en el `PATH`; por ello el flujo no es
portable ni completamente reproducible en este equipo.

No se inspeccionaron los módulos de IA, tokens, logs, sesiones, archivos de
deshacer ni contenido de estado. El inventario mostró que esas áreas pueden
contener datos sensibles y deben permanecer fuera del proyecto.

### Datos y copia de seguridad

- Datos de Neovim: aproximadamente 618 MB.
- Estado de Neovim: aproximadamente 1,9 MB.
- Caché de Neovim: aproximadamente 76 MB.
- Copia completa histórica bajo `~/copias-seguridad`: 623 MB en el inventario
  inicial.

La copia contiene configuración, datos y estado. No se modificó ni se leyó el
contenido de sus archivos potencialmente sensibles.

### Herramientas disponibles

| Área | Disponible | No disponible en `PATH` |
| --- | --- | --- |
| Base | Git 2.47.3, ripgrep 15.2, fdfind 10.2, fzf 0.60 | - |
| Construcción | GCC 14.2, Make 4.4, CMake 3.31 | Clang |
| Git interactivo | lazygit 0.50 | - |
| JavaScript | Node 22.23.2, npm 10.9.8, Corepack 0.34.6, Prettier 3.6.2 | pnpm, ESLint |
| Python | Python 3.13.5, pipx 1.7.1 | WeasyPrint |
| Markdown/PDF | Pandoc 3.1.11.1, pdfLaTeX, XeLaTeX, LuaLaTeX | Typst |
| Shell | Bash 5.2 | Zsh, Fish, ShellCheck, shfmt |
| Lua | LuaJIT incluido en Neovim | Lua, LuaRocks, StyLua |

Mason conserva ejecutables para Ruff, vtsls, shfmt, StyLua, markdownlint-cli2,
Pyright, Tailwind, Marksman, lua-language-server, Prettier, ESLint LSP y el
adaptador de depuración de JavaScript. Son parte de los datos activos de la
configuración anterior: no deben considerarse una instalación portable ni una
dependencia garantizada del proyecto nuevo.

## Riesgos detectados

1. Los datos y el estado anteriores contienen tokens, sesiones y copias de
   deshacer potencialmente sensibles; nunca deben copiarse al repositorio.
2. El ejecutable AppImage depende de FUSE en ejecución normal dentro de este
   entorno, lo que puede falsear pruebas si no se aísla correctamente.
3. La configuración anterior tiene una superficie de dependencias grande y usa
   actualizaciones flotantes, aunque su lockfile fija los commits actuales.
4. Mason oculta diferencias entre equipos: una herramienta puede funcionar hoy
   sin estar instalada en un sistema nuevo.
5. Los plugins de previsualización Markdown basados en Node pueden ejecutar
   scripts de construcción; deberán justificarse e inspeccionarse antes de
   permitirlos.
6. El flujo de PDF actual mezcla archivos externos, una herramienta ausente y
   `xdg-open`, que no existe en macOS.
7. Atajos con `Alt`, portapapeles y símbolos de Nerd Font pueden variar entre
   terminales, Linux y macOS.

## Arquitectura inicial propuesta

```text
nvim/init.lua
  -> config.options
  -> config.keymaps
  -> config.autocmds
  -> config.lazy
       -> plugins.editor
       -> plugins.search
       -> plugins.lsp
       -> plugins.git
       -> plugins.markdown
```

La propuesta usa `lazy.nvim` directamente, sin LazyVim, con especificaciones
pequeñas por responsabilidad y `lazy-lock.json` versionado. Las opciones,
atajos y autocmds serán nativos. Cada integración externa comprobará el
ejecutable antes de activarse y mostrará un diagnóstico comprensible si falta.

Antes de elegir cada plugin se comparará con la función nativa equivalente. La
primera versión puede usar el explorador y el completado LSP nativos para medir
qué carencias reales justifican dependencias. No se incluirán IA, depuración ni
adornos en el arranque mínimo.

## Plan por fases

1. **Inventario y reglas:** documentar el estado, riesgos, recuperación y forma
   de trabajo. Esta es la fase actual.
2. **Núcleo aislado:** crear `init.lua`, opciones, atajos y autocmds; probar con
   directorios XDG temporales sin tocar la configuración activa.
3. **Gestión de plugins:** incorporar `lazy.nvim`, fijarlo y generar un lockfile;
   documentar el origen y la actualización controlada.
4. **Edición y búsqueda:** añadir solo las dependencias justificadas para
   archivos y búsqueda, aprovechando ripgrep, fdfind y fzf instalados.
5. **Lenguajes:** configurar LSP nativo, completado, diagnósticos y formato con
   detección de herramientas, empezando por Lua, JavaScript/TypeScript y Python.
6. **Git:** integrar indicadores y operaciones frecuentes sin ocultar los
   comandos Git subyacentes.
7. **Markdown y PDF:** crear una muestra con tabla e imagen, comparar opciones
   de previsualización/exportación y fijar un único flujo reproducible.
8. **Portabilidad:** probar Debian, documentar diferencias para CachyOS y macOS,
   Nerd Font, portapapeles y apertura de archivos.
9. **Activación:** preparar instalación y restauración; modificar o enlazar la
   configuración activa solo con aprobación expresa.

## Decisiones pendientes de aprobación

- Empezar con capacidades nativas y añadir plugins solo ante carencias medidas.
- Mantener fuera del alcance inicial la IA y la depuración.

## Fase 2: núcleo aislado

La fase 2 fue aprobada el 5 de agosto de 2026. Se implementó un núcleo que solo
usa la API nativa de Neovim 0.11.4 y carga tres módulos: opciones, atajos y
autocomandos.

El aislamiento usa estas decisiones:

- `XDG_CONFIG_HOME` apunta a la raíz del repositorio para cargar `nvim/init.lua`.
- Datos, estado y caché se guardan bajo `.xdg/`, ignorado por Git.
- `APPIMAGE_EXTRACT_AND_RUN=1` permite probar el AppImage actual cuando FUSE no
  está disponible; otros binarios de Neovim ignoran esta variable.
- Los scripts no consultan ni reutilizan la configuración activa.
- No se carga ningún plugin, gestor de plugins ni ejecutable de Mason.

Los atajos evitan combinaciones `Alt` por sus diferencias entre terminales y
macOS. Tampoco se activa el portapapeles del sistema automáticamente hasta poder
comprobar sus proveedores en cada plataforma.

## Fase 3: plugins mínimos

La fase 3 incorpora `lazy.nvim` directamente, sin LazyVim, y un único plugin
funcional: `fzf-lua`. Ambos quedan fijados por commit en `nvim/lazy-lock.json` y
se descargan bajo el directorio XDG aislado del repositorio.

`fzf-lua` fue elegido porque cubre archivos, texto y buffers sin dependencias
Lua transitivas obligatorias. Usa los ejecutables `fzf` y `rg` ya instalados.
Los iconos se desactivan y no se añaden Nerd Fonts, `bat`, extensiones nativas ni
otros plugins opcionales.

Telescope se descartó en esta fase porque su versión actual requiere Neovim
0.11.7 y `plenary.nvim`, mientras el entorno usa Neovim 0.11.4. También suele
recomendar un sorter nativo adicional, aumentando el alcance y las dependencias.

Lazy tiene deshabilitados LuaRocks, las especificaciones locales de proyecto,
la comprobación automática de actualizaciones y las fuentes de paquetes. Las
actualizaciones deben ser explícitas y conservar el lockfile revisado.

## Fase 7: Markdown y PDF

La fase fija Pandoc a HTML autocontenido y Chromium/Chrome como motor de
impresión. Esta combinación usa un CSS versionado como fuente única de estilo y
funciona con las herramientas ya disponibles en Debian, sin rescatar archivos
de LazyVim ni instalar un plugin Markdown.

El exportador detecta sus dependencias, resuelve imágenes desde el directorio
del documento y genera un PDF A4 con cabeceras, pies, numeración y saltos
controlados. El módulo Lua solo aporta el comando `:MarkdownPdf` y el mapa
`<leader>mp`; el trabajo reproducible permanece en un script independiente de
Neovim. El ejemplo y la prueba funcional cubren títulos, tabla, SVG relativo,
código, emoji y dos páginas.

XeLaTeX y LuaLaTeX se descartaron como ruta principal porque exigirían mantener
otro sistema de estilos. WeasyPrint, Paged.js, Typst y wkhtmltopdf no están
disponibles y no ofrecen una ventaja suficiente para añadir otra dependencia.

## Dashboard IFL

La pantalla de inicio se implementa con un buffer nativo no listado y de solo
lectura. Se abre únicamente en una interfaz sin argumentos ni entrada estándar,
se puede recuperar con `:IFL` y restaura las opciones locales de la ventana al
salir. El logotipo ASCII evita depender de una Nerd Font.

Las acciones reutilizan `fzf-lua` de forma diferida para archivos, texto y
recientes, además de ofrecer archivo nuevo, acceso a la configuración y salida.
No se incorpora un plugin de dashboard porque la API nativa cubre el alcance
completo con menos dependencias y sin ampliar el tiempo de arranque.

## Endurecimiento de tmux y agentes

El flujo usa un socket tmux dedicado para no alterar el servidor personal. El
envío de contexto valida el proceso real del panel, deniega shells y procesos
desconocidos y permite incorporar agentes mediante una lista de identidades y
un lanzador agnóstico para wrappers. El límite se comparte entre Lua y shell,
los temporales tienen permisos privados y una purga acotada, y las rutas
sensibles comunes se bloquean como medida preventiva.

El panel de Neovim conserva una shell al cerrar el editor y las reconexiones no
reconstruyen layouts existentes. La compatibilidad se revisó con sintaxis POSIX
y alternativas GNU/BSD. La suite tmux se validó después también con tmux 3.6b
en macOS Apple Silicon; CachyOS y la suite completa de Neovim en macOS siguen
pendientes.

## Tmux diario: prefijo, ratón y estado

La fase posterior adopta `Ctrl-a` como prefijo por ergonomía y conserva una vía
explícita para enviar la tecla literal mediante `Ctrl-a Ctrl-a`. Se acepta que
esta combinación sustituye temporalmente el «principio de línea» de Readline y
otras acciones propias de aplicaciones mientras tmux espera una orden.

El ratón se activa como apoyo para selección, ventanas, redimensionado y scroll,
sin reemplazar los bindings `h/j/k/l`. La barra de estado muestra únicamente la
sesión, las ventanas y el nombre corto del directorio activo. No se incorporan
TPM, SessionX, Resurrect, Continuum ni integración automática de portapapeles en
esta fase.

Una fase posterior amplía esa base con una barra ASCII propia, todavía sin TPM
ni plugins. `proyecto.sh` registra la raíz canónica en
`@entorno_project_root`; un helper POSIX obtiene desde ella la rama y los cambios
versionados de Git y localiza el agente por `@entorno_role`, no por la posición
del panel. El intervalo de 15 segundos y `--untracked-files=no` limitan el coste
en repositorios grandes a cambio de no señalar archivos nuevos sin seguimiento.
La presentación usa el nombre base del proyecto sin alterar el identificador
real de la sesión y diferencia la ventana activa con una paleta limitada a los
16 colores ANSI. Los índices de ventana facilitan futuros espacios `git`,
`server` o `logs`; los separadores y el estado `AI:-` permanecen en ASCII.
La revisión visual posterior añade corchetes a la ventana activa como fallback
sin color, controla explícitamente los separadores y destaca la hora, sin mover
presentación al helper ni introducir una fuente especial.

## Limpieza visual al lanzar agentes

El ciclo selector → shell → agente se conserva para no alterar el contrato del
transporte de contexto. Después de validar el destino y publicar
`@entorno_agent_command` y `@entorno_agent_process`, `scripts/agente.sh` limpia
el scrollback tmux y la pantalla ANSI inmediatamente antes de `exec`. La
limpieza no afecta al rol, la metadata ni el proceso que valida `<leader>ac`.

## Node 24 LTS

La instalación vigente usa Node `>=24 <25`, en lugar de conservar el límite
histórico de Node 22. Las herramientas LSP no requieren la rama anterior y Node
24 ofrece una base LTS más actual para máquinas nuevas. pnpm continúa fijado por
`packageManager` y los lockfiles; no se instala globalmente.

## Node vendorizado y plataformas docentes

Exigir al alumno un Node 24 del sistema era el principal bloqueo real: Debian 13
no lo trae, Arch es una distribución rodante y no todas las instalaciones
incluyen `corepack`. Para que el mismo repositorio funcione en WSL2, Debian y
Arch sin administrar el sistema, `scripts/instalar-node.sh` descarga Node 24
LTS dentro de `.tools/`, con `SHA-256` publicado por nodejs.org y validación de
rutas del archivo antes de extraer. `scripts/lib/plataforma.sh` concentra la
detección de sistema, distribución, WSL2 y arquitectura, y decide el artefacto
(`linux-x64`, `linux-arm64`, `darwin-arm64`, `darwin-x64`). El Node del sistema
solo se usa como respaldo si no existe artefacto fijado para esa arquitectura.

`scripts/arrancar.sh` antepone ese Node al `PATH` porque los lanzadores de los
servidores LSP invocan `node` por `PATH`. En WSL2 el navegador pasa a ser
opcional: sin WSLg no hay portapapeles X11 y el PDF puede no estar disponible,
pero el editor, tmux, lazygit y Git funcionan. La configuración detecta el
portapapeles de Windows (`win32yank.exe` o `clip.exe`/`powershell.exe`) y el
visor del PDF intenta `wslview` o `explorer.exe` antes de `xdg-open`. La guía
para el alumno vive en [alumno.md](alumno.md).

## Instalador comodo y seguro

`instalar.sh` es el unico comando que necesita el alumno. Clasifica lo que falta
en imprescindible y opcional, descarga sin `sudo` todo lo que vive en el
repositorio y, si falta un paquete del sistema, imprime el comando exacto para
la distribucion detectada. La opcion `--sistema` muestra ese comando, pide
confirmacion por terminal y solo entonces lo ejecuta con `sudo`; nunca instala
paquetes en silencio. `comprobar-requisitos.sh` queda como diagnostico de solo
lectura. Se mantiene la regla de no usar `sudo` sin consentimiento explicito.

## 2026-09-27: productividad y descubrimiento

Se incorporan snippets propios en formato VS Code para HTML y React, sin una
colección externa ni Emmet. Los componentes no importan React por defecto
(runtime JSX moderno); los hooks indican el import necesario. Las plantillas
son editables en `nvim/snippets/`. `rafce` y `rfce` incluyen export default.

Se añade la dependencia directa indent-blankline.nvim, fijada por commit:
representa cada nivel de indentación con una guía de color. La alternativa
mini.indentscope solo representa el bloque activo; no resuelve la visualización
de todos los niveles solicitada. No requiere herramientas externas.

Los pliegues usan Tree-sitter cuando existe parser y la indentación como
alternativa. Arrancan abiertos. La ayuda `Espacio ?` / F1 muestra operaciones
nativas, plantillas, diagnósticos y pliegues sin multiplicar menús principales.

## Docker, formato al guardar y ayuda para el alumnado (2026-09-30)

Se añaden dos dependencias directas en `tools/lsp-docker`, fijadas en su
lockfile y con la misma política pnpm que el resto (`minimumReleaseAge` de 7
días, sin scripts de construcción aprobados):

- `dockerfile-language-server-nodejs` 0.15.0 (MIT): errores y completado de
  instrucciones en Dockerfile. Alternativa sencilla: ninguna nativa.
- `@microsoft/compose-language-service` 1.0.0 (MIT): completado y ayuda en
  `compose.yaml`. No valida todo el esquema; sí completa claves y servicios.

Total de 17 paquetes, ninguno con scripts de instalación.

El formato al guardar, antes descartado, se activa a petición del profesor.
No añade Prettier ni conform.nvim: usa el formateo de los servidores ya
presentes (TypeScript, HTML, CSS, JSON, Docker) y, si existen como paquetes
del sistema, `shfmt` (vía bash-language-server) y `ruff server` para Python.
`Espacio uf` lo desactiva. `shfmt` y `ruff` son opcionales: el instalador SI
los ofrece solo si el gestor de paquetes los tiene.

TypeScript recibe `locale = "es"` para dar sus mensajes en español. ShellCheck,
Pyright y los servidores de Docker no tienen traducción.

Si falta un servidor del perfil, Neovim avisa al abrir ese tipo de archivo:
antes solo lo registraba `:EntornoInfo` y el alumno creía que no había errores.
Los diagnósticos muestran letra en el margen, subrayado simple y el mensaje en
la línea del cursor, porque Windows Terminal y tmux no dibujan undercurl.

Snippets propios para Bash, Python, Dockerfile, Docker Compose y CSS, en el
mismo formato VS Code. `compose*.yaml` se detecta como `yaml.docker-compose`.
El menú `Espacio l` repite `gd`, `K`, `grr`, `grn` y `gra` con nombres claros.

## Perfil único del alumnado y menú al estilo LazyVim (2026-09-30)

Los perfiles `dwec` y `si` se unifican en `alumno`: el coste es de unos
130 MB más en SI y ninguno en rendimiento, porque cada servidor solo arranca
al abrir su tipo de archivo (Tailwind, además, solo si el proyecto lo usa).
Con perfiles separados, lo que faltaba no se notaba como error: simplemente
no se marcaba nada. `dwec` y `si` se siguen aceptando y equivalen a `alumno`.

El menú de `Espacio` toma la organización de LazyVim sin copiar su código:
`b` archivos abiertos, `f` buscar, `g` Git, `l` código, `s` plantillas,
`t` texto (cada entrada muestra su tecla nativa para aprenderla), `r`
ejecutar el archivo, `u` opciones. `Esc` limpia la búsqueda, como en
LazyVim; `Espacio d`, `h` y `q` salen del primer nivel. Los avisos se
limitan a una línea: si no caben, Neovim pide ENTER y se come las teclas.


## 2026-10-08 — Instalador de alumnado compatible con Linux ARM64

El mismo `instalar-alumno.sh` admite x86_64, aarch64 y arm64, incluido WSL2
sobre Windows ARM. Se eliminan las dos restricciones x86_64 (entrada y
Neovim); Node ya disponía de artefacto ARM64 fijado. No se añaden dependencias
ni se cambia el carril completo del profesor (LuaLS/Tree-sitter).

Neovim conserva la versión 0.12.4: tarball ARM64 oficial con digest publicado
por la API de GitHub, comprobado sobre la descarga, y SHA-256 del binario
extraído fijado. Se verifica también el binario existente antes de continuar.
Los paquetes apt/pacman conservan sus nombres y su consentimiento; el gestor
selecciona la arquitectura nativa. ARM32 se rechaza antes de modificar nada.
No se certifica una instalación real en WSL ARM64 sin el portátil del alumno.
Fuente: https://github.com/neovim/neovim/releases/tag/v0.12.4.

Validación: `sh -n` de los scripts modificados, `git diff --check`, pruebas
interactivas existentes (`tests/comprobar_instalador_entrada.py`) y
`python3 tests/comprobar_arm.py /tmp/entorno-nvim-arm64.tar.gz` pasadas.
La última usa uname simulado y el tarball oficial descargado: comprueba
entrada del instalador en modo lectura, extracción, SHA-256 y rechazo de
una descarga corrupta. No ejecuta el binario ARM ni instala paquetes.
En la primera pasada ShellCheck no estaba disponible; se añadió una
comprobación con el binario oficial temporal en la segunda revisión.


### Segunda revisión y publicación — 2026-10-08

- Se requiere Python 3 para ejecutar ejercicios; el paquete se llama `python3`
  en Debian/Ubuntu y `python` en Arch/CachyOS. Es una dependencia directa del
  flujo Python, no un paquete npm ni una instalación global añadida aquí.
- El perfil se guarda tras finalizar, la comprobación respeta XDG alternativo
  y detecta también Docker Compose ausente. El arranque falla si Neovim
  registra un error, y el Neovim existente se verifica antes de ejecutarlo.
- README: un solo script para x86_64/ARM64, primera instalación, recuperación
  tras el rechazo ARM y actualización sin recomendar descartar cambios.
- Instalación limpia real x86_64 en copia de archivos versionados bajo `/tmp`,
  con HOME temporal y `--yes --sin-sistema`: Neovim 0.12.4, Node 24.21.0,
  plugins fijados, LSP web/Bash/Python/Docker, diccionario y lanzador preparados.
  Repetición y `--comprobar` pasadas. No se ejecutaron apt/pacman ni sudo.
  El anfitrión es Omarchy x86_64; no equivale a probar Debian/WSL limpios.
- Pruebas funcionales LSP web y Python pasadas. Dentro de la sandbox los
  servidores se cerraban al iniciar; repetidas fuera del aislamiento de
  procesos sobre la misma copia temporal pasaron. `checkhealth` sin ERROR;
  hay avisos de proveedores opcionales y de plugins empaquetados.
- ARM64: tarballs oficiales Neovim/Node descargados y hashes fijados
  comprobados, Node/Corepack/npm presentes, extracción Neovim y rechazo de
  corrupción pasados. Detección y comandos de paquetes simulados para
  x86_64/aarch64/arm64 en Debian/Ubuntu/Arch/CachyOS; ARM32 rechazado.
  No se han ejecutado binarios ARM ni instalado sobre WSL ARM real.
- Pruebas de entrada/cancelación, comprobación con XDG alternativo y Docker
  Compose ausente, `sh -n` y `git diff --check` pasadas. ShellCheck 0.11.0
  oficial descargado y verificado en `/tmp`: análisis con `-x -P scripts
  -e SC2034,SC1007` pasado (excluye variables de bibliotecas compartidas y
  el patrón CDPATH vacío preexistente en auxiliares).

Pendiente de campo: el alumno debe probar instalación y uso en WSL2 ARM64;
si falla, conservar mensaje completo, `uname -m` y distribución, sin secretos.


### Aclaración del actualizador — 2026-10-08

Revisado `scripts/actualizar.sh`: descarga con `git pull --ff-only` y después
invoca el instalador de alumnado. Si la instalación ARM falló antes de guardar
el perfil, la rama por defecto también invoca `instalar-alumno.sh`, con pausa
Enter; no el instalador completo del profesor. El README recomienda ahora
el actualizador también para ese caso. Git manual solo si el script no existe.

## TypeScript: puntos y coma al guardar — 2026-11-06

El formato al guardar ya existía. Se añade typescript.format.semicolons = "insert"
a ts_ls, usando el servidor instalado, sin Prettier ni nuevas dependencias.
La sangría sigue las opciones del buffer (por defecto dos espacios). No se añade
un punto y coma ciegamente a cada línea: el formateador respeta bloques y cadenas.
Espacio uf conserva la desactivación. Prueba real con BufWritePre, servidor
TypeScript y archivo temporal: sangría, declaraciones/llamadas, llaves sin ;,
cadena con ; interno, idempotencia y desactivación.

## Delta como mejora opcional de lazygit — 2026-11-06

Dependencia directa opcional git-delta (ejecutable delta). Aporta resaltado del
diff y números de línea; alternativa sencilla: renderizado nativo de lazygit.
No sustituye lazygit ni cambia la configuración global de Git. Un lanzador
común para Neovim y tmux añade un overlay del repositorio a la configuración
existente; detecta la versión de lazygit para escoger diffRenderers (>=0.64)
o pagers (anteriores). Si falta delta o la versión es desconocida, usa lazygit
normal. El comprobador avisa sin bloquear; los instaladores ofrecen el paquete
solo con la confirmación de sistema habitual, y alumnado solo si está disponible.
No se fija el paquete del sistema; su versión real se registra en el cierre.

Fuente: https://github.com/jesseduffield/lazygit/blob/master/docs/Custom_DiffRenderers.md

## Iconos sin dependencias: interruptor único — 2026-11-15

Problema: buena parte del alumnado usa WSL2 y ve cuadros en lugar de iconos.
Una Nerd Font instalada dentro de la distribución no cambia nada, porque quien
dibuja los glifos es Windows Terminal o la terminal de VS Code, con fuentes de
Windows. No existe forma fiable de detectar la fuente del terminal: ni Windows
Terminal ni VS Code la exponen, y `fc-list` solo ve el sistema Linux.

Decisión: no se adivina ni se cambia el comportamiento de nadie. `config/iconos.lua`
es la única fuente de verdad, con prioridad `ENTORNO_ICONOS` (sesión) >
`.xdg/iconos` (persistente) > activados, que es lo que ya había. `:EntornoIconos`
alterna, guarda y reaplica sin reiniciar: la barra y la bienvenida se redibujan y
el árbol se reconstruye con `nvim-tree.setup()`, que el plugin documenta como
reaplicable; después se reabre si estaba visible, porque `setup()` vacía la vista.
Sin Nerd Font el árbol pasa a flechas ASCII `>` y `v` y deja de pedir devicons.

Alternativa descartada: ASCII automático en WSL. Habría quitado los iconos a quien
ya tenía la fuente instalada, es decir, roto algo para arreglar otra cosa. También
se descartó preguntar en el instalador: rompe `--yes` y las instalaciones no
interactivas.

La fuente no se distribuye ni se instala sola: no hay descargas nuevas, ni cambios
fuera del repositorio, ni privilegios. `docs/alumno.md` explica las tres rutas
(Windows Terminal, VS Code, Linux) y el instalador imprime un aviso informativo
solo cuando no detecta Nerd Font en Linux, o siempre en WSL2. Prueba
`tests/comprobar_iconos.lua` cubre prioridad, persistencia y ausencia de glifos
privados en árbol, barra y bienvenida.

## Ruff sin gestor de paquetes — 2026-11-15

Problema: la columna «Con ruff» del formato de Python era incumplible en las dos
distribuciones obligatorias. Debian 13 y Ubuntu 26.04 no incluyen `ruff`
(`apt-cache policy ruff` sin candidato, verificado en contenedores limpios), y
`pip install ruff` choca con PEP 668 (entorno gestionado externamente): el alumno
acababa en venv, `--break-system-packages` o `pipx` instalado a mano.

Decisión: se trata como el resto de herramientas fijadas del proyecto. Nuevo
`scripts/instalar-ruff.sh` descarga `ruff-x86_64-unknown-linux-gnu.tar.gz` o
`ruff-aarch64-unknown-linux-gnu.tar.gz` de la release 0.17.5, verifica SHA-256,
comprueba que el archivo contiene un único ejecutable, valida `ruff --version` y
lo deja en `.tools/ruff-0.17.5/bin/`. Sin `sudo`, sin `pip`, sin red en cada
arranque. `arrancar.sh` antepone esa ruta al PATH y `config/lsp.lua` solo activa
`ruff server` con 0.5.3 o posterior; si detecta una versión anterior, avisa y no
arranca un servidor que fallaría.

Alternativas descartadas: `pipx` (otra dependencia y otra descarga, no está en
Debian por defecto), `pip --break-system-packages` (rompe el sistema del alumno)
y añadir el paquete de terceros de turno. En macOS no se distribuye artefacto y
se remite a `brew`/`pipx`: el entorno funciona sin ruff.

Nadie cambia de comportamiento sin pedirlo: el instalador de alumnado ofrece el
binario una vez, de forma interactiva, y en instalación desatendida (`--yes`) lo
omite. Prueba real: instalación y detección por el cliente LSP `ruff` en un
búfer Python, con `:EntornoInfo` mostrándolo disponible.

## Ruff como formateador y Pyright en modo push — 2026-11-15

Dos hallazgos al probar ruff dentro del editor, medidos con arranques repetidos
sobre el fixture de Python:

1. Con ruff activo como servidor LSP, Pyright dejaba de publicar diagnósticos en
   uno de cada tres arranques. No era culpa de ruff: ocurría igual sin él.
   Neovim 0.12 consulta diagnósticos (`textDocument/diagnostic`) al adjuntar el
   cliente y Pyright, todavía analizando el proyecto, no respondía; después solo
   se refrescaban al modificar el búfer. Consecuencia real: abrir un archivo
   Python sin errores visibles hasta escribir algo.
2. Dos clientes consultando diagnósticos duplicaban avisos (F821 de Ruff y
   «undefined variable» de Pyright en la misma línea).

Decisión: `ruff` no se configura como cliente LSP. El formato al guardar ejecuta
`ruff format --stdin-filename <archivo> -` con el contenido del búfer y aplica
la salida (2 s de límite; si falla, formato LSP habitual). Pyright se configura
con `capabilities = { textDocument = { diagnostic = false } }`, de modo que use
diagnósticos push: publica al abrir y en cada cambio. Verificado con tres
arranques consecutivos del test de Python y con un cambio posterior, sin
duplicados en la misma línea.

`vim.lsp.diagnostic._refresh()` no lo arreglaba y un `didChange` vacío manual sí
publicaba, pero desincronizaba la versión del documento y rompía las
actualizaciones posteriores: descartado.

## Comas en estilos dentro de `#{?}` en tmux — 2026-11-15

Detectado en la VM de Debian: la barra inferior mostraba texto suelto del tipo
`,bg=colour3,bold] PREFIJO`. El separador de argumentos de `#{?condicion,a,b}`
es la coma, y un estilo como `#[fg=colour0,bg=colour3,bold]` contiene comas, así
que tmux cortaba la condición en `#[fg=colour0` y el resto se imprimía literal.

Solución: dentro de una condición, las comas del estilo se escapan como `#,`
(`#[fg=colour0#,bg=colour3#,bold]`), que tmux expande a coma al evaluar la
condición sin partirla. Reproducido y verificado con `tmux display-message -p`:
sin escapar, la condición devolvía solo `#[fg=colour0`; escapada, devuelve el
estilo completo. Los estilos fuera de condiciones no cambian.

## Cómo se versiona el entorno — 2026-11-15

`VERSION` en la raíz es la única fuente de verdad. Lo leen la bienvenida, el
banner del instalador y `entorno_version_repo()` en los scripts; no hay ningún
número escrito a mano en otro sitio, así que no pueden desincronizarse.

Criterio, semántico y aplicado a lo que recibe el alumnado:

- **PATCH** (1.2.0 → 1.2.1): fallos y ergonomía de algo ya publicado, sin
  cambiar comandos. Ejemplo: la terminal nueva sin `entorno-dev`.
- **MINOR** (1.1.0 → 1.2.0): funciones nuevas compatibles. Ejemplo: iconos
  opcionales, Ruff, vista previa del explorador, instalador de una línea.
- **MAJOR**: cambios que obligan a hacer algo distinto (renombrar o quitar
  comandos, cambiar rutas de estado).

Cada publicación añade su sección con el mismo número en `CHANGELOG.md`, y el
alumnado la ve en la portada sin tener que mirar Git. `actualizar.sh` muestra
además las novedades desde el commit anterior, así que versión y cambios
coinciden.
