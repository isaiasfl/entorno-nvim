# Chuleta diaria

## TMUX

| Acción | Comando o tecla |
| --- | --- |
| Abrir proyecto actual | `entorno-dev` |
| Abrir otra ruta | `entorno-dev /ruta` |
| Elegir proyecto | `entorno-dev --elegir` o `Ctrl-a P` |
| Moverse por paneles | `Ctrl-a h/j/k/l` |
| Redimensionar | `Ctrl-a H/J/K/L` |
| Dividir | `Ctrl-a \|` / `Ctrl-a -` |
| Crear ventana | `Ctrl-a c` |
| Ir al editor | `Ctrl-a n` |
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
| Buscar archivo / texto | dashboard `f` / `g` |
| Explorador | dashboard `e` |
| Definición / referencias / rename | `gd` / `grr` / `grn` |
| Hover / completar | `K` / `Ctrl-Space` |
| Formatear con LSP | `<leader>lf` |
| Volver al dashboard | `:IFL` |

## AGENTES

1. Arrancar el cliente en el panel marcado como agente.
2. Usar `<leader>ac` en normal o visual.
3. Revisar el texto pegado.
4. Pulsar Enter manualmente.

El transporte rechaza shells y procesos desconocidos; no envía Enter.

## GIT

| Acción | Comando o tecla |
| --- | --- |
| Abrir lazygit | `<leader>gg` |
| Estado rápido | `git status --short` |
| Revisar cambios | `git diff` |
| Revisar espacios | `git diff --check` |

## MARKDOWN/PDF

| Acción | Comando o tecla |
| --- | --- |
| Generar PDF | `<leader>mp` o `:MarkdownPdf` |
| Generar y visualizar | `<leader>mv` |
| Terminal | `./scripts/markdown-pdf.sh documento.md` |

Los textos marginales se definen con `module`, `centre` y `teacher` en el YAML.
