# Chuleta diaria

## TMUX

| Acción | Comando o tecla |
| --- | --- |
| Abrir proyecto | `./scripts/proyecto.sh /ruta` |
| Elegir proyecto | `./scripts/proyecto.sh` o `Ctrl-b P` |
| Moverse por paneles | `Ctrl-b h/j/k/l` |
| Redimensionar | `Ctrl-b H/J/K/L` |
| Dividir | `Ctrl-b \|` / `Ctrl-b -` |
| Separarse sin cerrar | `Ctrl-b d` |

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
