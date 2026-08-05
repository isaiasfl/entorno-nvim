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
- Copia completa verificada en
  `/home/isaiasfl/copias-seguridad/nvim-20260805-221016`: 623 MB.

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

- Adoptar `lazy.nvim` directamente como gestor.
- Empezar con capacidades nativas y añadir plugins solo ante carencias medidas.
- Mantener fuera del alcance inicial la IA y la depuración.
- Elegir el motor de PDF después de una prueba reproducible entre HTML/CSS y
  LaTeX, priorizando coherencia visual y portabilidad.

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
