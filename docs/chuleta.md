# Chuleta diaria

Para la referencia extensa: [guía completa de teclas y uso](guia-completa-teclas.md),
con [inventario de teclas de LazyGit](lazygit-teclas-defaults.md).

Entrada personal: `/ruta/entorno-nvim/bin/entorno-dev /ruta/proyecto`.
Conserva el perfil completo, PDF y tmux con editor, agente y terminal.
Use `--sin-tmux` para abrir solo Neovim o `--sin-ia` para omitir el agente.
Los ejemplos con `entorno-dev` abreviado presuponen
el enlace opcional instalado. `:EntornoInfo` muestra lo que falta preparar.

## TMUX

En la pantalla inicial, `e` abre el explorador. En Neovim, `Espacio e`
tambien lo abre; se conservan `Espacio e e` y `Espacio e f`.
`Espacio e` espera brevemente por si completa una de esas secuencias.
El diagnostico flotante pasa a `Espacio l d`.
En el explorador nativo, `Espacio e` tambien cierra y devuelve el archivo
anterior o la pantalla principal. `:IFL` permite volver al inicio directamente.

| Acción | Comando o tecla |
| --- | --- |
| Abrir proyecto actual con tmux | `entorno-dev --tmux` |
| Abrir otra ruta con tmux | `entorno-dev --tmux /ruta` |
| Elegir proyecto | `entorno-dev --elegir` o `Ctrl-a P` |
| Moverse por paneles | `Ctrl-a h/j/k/l` |
| Redimensionar | `Ctrl-a H/J/K/L` |
| Dividir | `Ctrl-a \|` / `Ctrl-a -` |
| Crear ventana | `Ctrl-a c` |
| Abrir/reutilizar lazygit | `Ctrl-a g` |
| Ir al editor | `Ctrl-a n` |
| Abrir selector IA | `Ctrl-a i` |
| Volver al panel agente | `Ctrl-a a` |
| Ayuda contextual | `Ctrl-a ?` |
| Ventana anterior | `Ctrl-a p` |
| Maximizar/restaurar panel | `Ctrl-a z` |
| Entrar en copy-mode | `Ctrl-a [` |
| Seleccionar/copiar en copy-mode | `v` / `y` |
| Elegir sesión | `Ctrl-a s` |
| Separarse sin cerrar | `Ctrl-a d` |
| Enviar `Ctrl-a` literal | `Ctrl-a Ctrl-a` |

El ratón también permite seleccionar paneles y ventanas, redimensionar y hacer
scroll. Muchos terminales requieren mantener `Shift` para seleccionar texto
directamente con el emulador en vez de con tmux.

La ayuda `Ctrl-a ?` usa un popup amplio con categorías navegables: flujo diario,
editor, inteligencia artificial, tmux/espacio de trabajo, Git, terminal,
navegación y configuración. La cabecera recuerda `PREFIX = CTRL-a` y
`SPACE = leader Neovim`. Enter abre una categoría, Esc vuelve o cierra desde la
raíz y `q` cierra desde cualquier nivel.

### Sesiones en el socket dedicado

La vía normal para cumplir «un proyecto = una sesión» es `proyecto.sh`. Para
aprender y administrar el servidor directamente:

```sh
tmux -L entorno-nvim list-sessions
tmux -L entorno-nvim attach-session -t nombre
tmux -L entorno-nvim switch-client -t nombre
tmux -L entorno-nvim kill-session -t nombre
```

Cerrar SSH o separarse conserva las sesiones y sus procesos. Reiniciar la
máquina no: la persistencia tras reinicios queda aplazada.

## NEOVIM

| Acción | Tecla |
| --- | --- |
| Guardar / salir | `<leader>w` / `<leader>q` |
| Duplicar línea | `<leader>d` |
| Mover línea o selección (Linux) | `Alt-Shift-j/k` |
| Mover línea o selección (macOS) | `Cmd-Shift-↓/↑` |
| Buscar archivo / texto | dashboard `f` / `g` |
| Explorador | dashboard `e` |
| Definición / referencias / rename | `gd` / `grr` / `grn` |
| Hover / completar | `K` / `Ctrl-Space` |
| Formatear con LSP | `<leader>lf` |
| Volver al dashboard | `:IFL` |

## AGENTES

Solo disponibles con `--ia`; no se habilitan por elegir el perfil profesor.

1. Arrancar el cliente en el panel marcado como agente.
2. Usar `<leader>ac` en normal o visual.
3. Revisar el texto pegado.
4. Pulsar Enter manualmente.

El transporte rechaza shells y procesos desconocidos; no envía Enter.

## GIT

| Acción | Comando o tecla |
| --- | --- |
| Abrir lazygit | `Ctrl-a g` (tmux) / `<leader>gg` (Neovim) |
| Estado rápido | `git status --short` |
| Revisar cambios | `git diff` |
| Revisar espacios | `git diff --check` |

## MARKDOWN/PDF

El modulo PDF se habilita con `--perfil profesor`.

| Acción | Comando o tecla |
| --- | --- |
| Generar PDF | `<leader>mp` o `:MarkdownPdf` |
| Generar y visualizar | `<leader>mv` |
| Terminal | `./scripts/markdown-pdf.sh documento.md` |

Los textos marginales se definen con `module`, `centre` y `teacher` en el YAML.
