# Decisiones e inventario

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

## Node 24 LTS

La instalación vigente usa Node `>=24 <25`, en lugar de conservar el límite
histórico de Node 22. Las herramientas LSP no requieren la rama anterior y Node
24 ofrece una base LTS más actual para máquinas nuevas. pnpm continúa fijado por
`packageManager` y los lockfiles; no se instala globalmente.
