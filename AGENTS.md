# AGENTS.md

## Objetivo

Construir desde cero una configuración de Neovim moderna, rápida, comprensible
y portátil para Isaías. Debe funcionar en Debian 13 y, cuando sea razonable,
en CachyOS y macOS, tanto en equipos Intel como AMD.

La configuración nueva se desarrolla y prueba primero dentro de este
repositorio. La configuración activa no se sustituye ni enlaza hasta que exista
una versión mínima comprobada y el usuario lo apruebe.

## Comunicación y forma de trabajo

- Hablar siempre en español.
- Explicar brevemente las decisiones importantes antes de aplicarlas.
- Trabajar en fases pequeñas, coherentes y verificables.
- Actuar con autonomía en operaciones normales, reversibles y limitadas al
  repositorio; no pedir aprobación para cada lectura, comando o edición.
- Después de cada fase, ejecutar las comprobaciones oportunas, revisar
  `git diff`, resumir los cambios y corregir los fallos detectados.
- No ocultar errores ni afirmar que una comprobación pasó si no se ejecutó.
- Mantener documentación de instalación, restauración, mantenimiento y
  decisiones técnicas.

## Autonomía dentro del repositorio

Se permite sin aprobación previa:

- leer e inspeccionar archivos y ejecutar comandos normales de Linux;
- crear, modificar, mover, renombrar y borrar archivos del repositorio;
- ejecutar pruebas, linters, formateadores y diagnósticos;
- usar Git para `status`, `diff`, `log`, `add`, restaurar cambios propios y
  crear commits;
- corregir errores propios y actualizar la documentación relacionada.

Antes de modificar un archivo existente, confirmar que hay una copia
recuperable o crear una. No borrar ni revertir cambios ajenos.

## Acciones que requieren aprobación

Detenerse, explicar la acción y pedir aprobación antes de:

- usar `sudo` o ejecutar cualquier proceso como `root`;
- instalar, actualizar o eliminar paquetes del sistema;
- instalar herramientas globales con npm, pnpm, pip, pipx, cargo, gem u otros
  gestores;
- modificar archivos fuera del repositorio;
- modificar `~/.config/nvim`, `~/.local/share/nvim`,
  `~/.local/state/nvim` o `~/.cache/nvim`;
- crear enlaces simbólicos desde la configuración activa al repositorio;
- cambiar configuraciones globales de Git, Node, npm, pnpm, shells o sistema;
- ejecutar acciones destructivas o difíciles de revertir;
- ejecutar `git push`, `git reset --hard`, `git clean -fd`, rebase, force push,
  borrar ramas o modificar remotos;
- acceder a rutas que puedan contener secretos o credenciales.

Nunca modificar particiones, GRUB, red, usuarios, permisos globales ni
servicios del sistema sin una petición explícita.

## Secretos y datos sensibles

No leer ni mostrar archivos `.env`, tokens, claves API, credenciales de npm o
SSH, almacenes de contraseñas, cookies ni sesiones. Los directorios de estado y
deshacer de Neovim pueden contener copias de archivos sensibles: se permite
inventariar su estructura general, pero no leer su contenido.

## Git y autoría

Se pueden crear commits al terminar unidades pequeñas y comprobadas. Antes del
primer commit se debe consultar, sin modificar, `git config user.name` y
`git config user.email`. Si falta alguno, no se hace el commit.

- Usar exclusivamente la identidad Git ya configurada.
- No cambiar `user.name` ni `user.email`.
- No usar como autor a Codex, OpenAI, bots o asistentes.
- No añadir `Co-authored-by`, firmas ni créditos relativos a IA.
- Usar mensajes pequeños, descriptivos y preferentemente en español.
- No hacer `push` salvo petición expresa.

## Seguridad de dependencias

- Preferir funciones nativas y herramientas ya instaladas.
- No añadir dependencias innecesarias ni ejecutar instaladores remotos como
  `curl ... | sh` o `wget ... | bash`.
- Antes de incorporar una dependencia, documentar qué resuelve, si es directa o
  transitiva, la alternativa sencilla y por qué compensa incorporarla.
- Fijar versiones cuando sea posible y conservar los lockfiles.
- No actualizar dependencias de forma masiva sin revisar los cambios.
- No ejecutar scripts descargados sin inspeccionarlos.
- Si una dependencia aparece en una alerta de seguridad fiable, detenerse y
  avisar. No afirmar que se comprobaron incidentes actuales sin acceso real a
  fuentes fiables.

## Node y pnpm

Node no se introduce si Neovim no lo necesita. Para proyectos JavaScript nuevos
del repositorio se prefiere pnpm:

1. Comprobar primero las versiones de Node, Corepack, npm y pnpm.
2. No instalar ni actualizar pnpm si requiere cambios globales sin aprobación.
3. Adaptarse a la versión instalada y versionar `pnpm-lock.yaml`.
4. Preferir versiones exactas para infraestructura y dependencias sensibles.
5. Bloquear scripts de dependencias por defecto cuando la versión lo permita,
   usar un `minimumReleaseAge` prudente y habilitar comprobaciones estrictas de
   integridad y builds ignorados.
6. Antes de aprobar un script de instalación o construcción, identificar el
   paquete, justificarlo, inspeccionarlo y pedir aprobación.
7. Nunca aprobar todos los builds indiscriminadamente; usar `ignored-builds` y
   `approve-builds`, o sus equivalentes, solo para paquetes concretos revisados.

## Preferencias del usuario

- Sistema principal: Debian 13; también usa CachyOS y macOS.
- Neovim inicial: 0.11.4.
- Shells habituales: Bash, Zsh y Fish.
- Idioma de trabajo: español.
- Quiere mejorar seriamente con Neovim y la terminal.
- No necesita conservar el mapeo `jk`.
- Prepara exámenes en Markdown con imágenes, tablas y exportación a PDF.
- Busca coherencia entre previsualización y PDF.
- Prefiere una configuración limpia, rápida, portátil y documentada.
- Los atajos deben ser cómodos en PC y Mac.

## Restricciones técnicas de Neovim

- Usar Lua y mantener `init.lua` pequeño, dividido en módulos claros.
- No instalar frameworks completos ni copiar distribuciones prefabricadas.
- Evitar comportamiento mágico y dependencias innecesarias.
- Bloquear versiones de plugins mediante lockfile.
- No asumir una Nerd Font; usar símbolos estándar o degradar con elegancia.
- No mezclar configuración personal con archivos generados.
- Detectar herramientas externas y funcionar razonablemente cuando falten.
- Comprobar si una herramienta ya existe antes de proponer su instalación.
- Antes de instalar paquetes, mostrar el comando y explicar su necesidad.

## Alcance inicial

1. Inventariar el entorno sin modificar la configuración activa.
2. Verificar la copia de seguridad existente.
3. Diseñar una estructura modular en Lua.
4. Configurar un gestor de plugins mantenible.
5. Añadir gradualmente opciones, atajos, archivos, búsqueda, LSP,
   autocompletado, formato, diagnósticos, Git y Markdown.
6. Probar el arranque aislado y medir errores.
7. Documentar instalación, restauración y mantenimiento.

## Estructura prevista

```text
.
├── AGENTS.md
├── CONTEXTO_INICIAL.md
├── README.md
├── docs/
│   ├── decisiones.md
│   ├── markdown-pdf.md
│   └── restauracion.md
├── nvim/
│   ├── init.lua
│   ├── lazy-lock.json
│   └── lua/
│       ├── config/
│       │   ├── options.lua
│       │   ├── keymaps.lua
│       │   ├── autocmds.lua
│       │   └── lazy.lua
│       └── plugins/
└── scripts/
    ├── instalar.sh
    ├── comprobar.sh
    └── restaurar.sh
```

## Criterios para la implementación mínima

- La configuración anterior permanece recuperable.
- La configuración del repositorio arranca de forma aislada sin errores.
- `nvim --headless "+checkhealth" +qa` no presenta errores críticos causados
  por el repositorio.
- Existen instrucciones claras de instalación y restauración.
- Los cambios están divididos en pasos comprensibles y comprobados.
