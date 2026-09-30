# Changelog

## Sin publicar

- Reinstalar tras mover o borrar la carpeta del repositorio ya no falla:
  el comando `entorno-dev` roto se redirige a la copia actual con un aviso.
  Si apunta a otra copia existente, se pregunta antes de cambiarlo.
- Si el comando `entorno-dev` no se puede actualizar, la instalación termina
  con un aviso y la alternativa `./bin/entorno-dev`, no con un error genérico.
- `instalar-alumno.sh` sin opciones muestra un menú (1 = DWEC, 2 = SI),
  recuerda la elección y la propone con Enter al actualizar. `entorno-dev`
  usa ese perfil por defecto.
- El instalador de alumno pregunta antes de instalar paquetes del sistema que
  falten, sin necesidad de `--sistema`; `--sin-sistema` lo impide.
- Mensajes más claros ante opciones erróneas, ejecución como root o falta de
  paquetes, con el comando exacto para continuar.
- `scripts/actualizar.sh`: corrige finales CRLF, restaura `lazy-lock.json`,
  ofrece cerrar sesiones antiguas, hace `git pull --ff-only` y reinstala con
  el perfil recordado.
- Ortografía en español e inglés (`spelllang=es,en`) en Markdown, texto y
  commits; diccionario de Neovim verificado por SHA-256, sin hunspell.
  `Espacio us` la alterna.
- Neovim avisa si falta ShellCheck al abrir Bash: sin él no hay diagnósticos.
- El instalador de alumno avisa si el repositorio está en `/mnt/c` en WSL2.
- `.gitattributes` fuerza finales de línea LF aunque Git use `core.autocrlf`,
  evitando `^M` en Neovim y archivos marcados como modificados en WSL2.

## 1.1.0 — 2026-09-27

- Ayuda de teclas con Espacio ? y F1, movimientos, edición, errores y snippets.
- Snippets propios para HTML, JavaScript, TypeScript y componentes/hooks React.
- JSDoc generado mediante TypeScript al escribir /** y Enter o Espacio lj.
- Completado nativo solicitado al escribir letras de nombres de variables.
- Líneas ajustadas al ancho, diagnósticos legibles en ventanas y hover delimitado.
- Guías de indentación de colores con plugin fijado; pliegues nativos.
- Instaladores con plan previo, Enter para iniciar, --yes para automatización,
  fases, colores, resumen de resultados y aviso explícito de fallo.
- README con rutas de instalación, diagrama Mermaid, opciones, actualización
  y activación opcional del comando nvim.

### Mejoras docentes incluidas desde la 1.0.0

- El instalador esencial admite `--perfil dwec` e instala únicamente Node,
  Neovim, plugins y servidores web, sin herramientas de PDF ni fixtures de
  prueba.
- Las terminales de las sesiones reciben el Node local verificado, por lo que
  `node`, `npm`, `npx` y Corepack funcionan sin modificar la shell del alumno.
- Los perfiles web exponen también el compilador `tsc` fijado por el entorno;
  los proyectos pueden seguir declarando su propia versión de TypeScript.
- Las instalaciones mínimas de Debian comprueban `xz-utils` y los certificados
  TLS antes de descargar Node, evitando un fallo que podía quedar oculto en
  sistemas WSL más completos.
- En Debian y Ubuntu, el modo `--sistema` comprueba `apt-get`, `sudo` y los
  certificados después de instalar, y explica cuándo debe intervenir el
  profesor o administrador.

Todos los cambios relevantes de este proyecto se documentan aquí.

### Evolución portable — 2026-09-13

- primera fase del entorno docente portable: perfiles inicial, DWEC, SI y
  profesor, con IA desactivada salvo opcion expresa;
- entrada sin tmux y sesiones optativas, con dos paneles sin IA y tres con IA;
- arranque nativo sin descargas ni bloqueo por servidores o plugins ausentes;
- herramientas privadas nuevas bajo `.tools/`, sin enlace global automatico;
- estado por perfil, runtime Wayland conservado y rutas personales recuperadas
  para lazygit y visores;
- correccion de `NVIM_BIN` en tmux para que conserve el wrapper aislado;
- pruebas de perfiles y navegacion nativa; regresion tmux adaptada a 3.7;
- Omarchy: pruebas locales de esta fase; WSL2/Debian y el entorno completo de
  lenguajes siguen pendientes de validacion en esta revision.

Los scripts de activacion/restauracion V1 se conservan, pero no son parte de
la via portable. No se actualizan dependencias ni se instalan herramientas
globales en esta fase.

## [1.0.0] - 2026-08-10

### Incluye

- configuración modular de Neovim 0.12.4 con dashboard nativo;
- búsqueda, exploración, edición, Git y Tree-sitter fijados;
- LSP y completado nativos para Lua, web y Python;
- sesiones tmux aisladas por proyecto y transporte seguro hacia agentes CLI;
- exportación Markdown a PDF A4 mediante Pandoc, CSS y Chromium;
- instalación, comprobación, activación y restauración reproducibles.

### Limitaciones conocidas

- solo Debian 13 x86_64 está probado;
- Arch/CachyOS y macOS siguen como objetivos sin validación real;
- BashLS está aplazado;
- Markdown/PDF presupone documentos propios y confiables;
- no se instala ni configura ningún proveedor de agentes.

El tag anotado `v1.0.0` queda pendiente de aprobación expresa y no forma parte
de esta preparación.
