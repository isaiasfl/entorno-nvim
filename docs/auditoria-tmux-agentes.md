# Auditoría de endurecimiento de tmux y agentes

Revisión contrastada en Debian 13 el 10 de agosto de 2026. No se leyeron
credenciales, archivos `.env`, claves, sesiones de proveedores ni almacenes de
contraseñas.

## Hallazgos confirmados y corregidos

- Los usos `dirname --`, `basename --` y otros operandos `--` no eran portables
  a las utilidades BSD de macOS. Se sustituyeron por formas POSIX y se trataron
  separadamente los posibles operandos que empiezan por guion.
- `readlink -f` no es portable a macOS. Las comprobaciones de enlaces creados
  por el propio proyecto comparan ahora sus destinos absolutos sin `-f`.
- El transporte confiaba solo en la marca del panel. Ahora comprueba el proceso
  real, deniega shells y desconocidos, y admite identidades ampliables.
- Un nombre comercial no siempre coincide con `pane_current_command`: Codex
  apareció como `node`. Se añadió un lanzador con identidad y proceso esperado,
  sin autorizar genéricamente Node.
- El socket predeterminado compartía el servidor tmux del usuario. Todo el flujo
  usa ahora el socket dedicado `entorno-nvim`.
- Lua fijaba 32768 bytes aunque la capa shell aceptaba un override. Lua resuelve
  ahora el límite efectivo y lo pasa explícitamente al transporte.
- Faltaban purga acotada de temporales y varios patrones sensibles comunes. Se
  añadieron la purga segura a 24 horas y la barrera preventiva documentada.
- Cancelar fzf podía continuar con una ruta vacía; ahora sale limpiamente.
- Neovim se ejecutaba con `exec`, por lo que al salir desaparecía su panel. El
  shell padre permanece y permite volver a abrir el editor.
- El nombre saneado de algunas sesiones terminaba en `_` por procesar el salto
  de línea. El saneamiento se hace ahora sin introducir ese carácter.
- Se definió una política explícita para tmux local anidado y se añadió
  `send-prefix` para un tmux remoto deliberado.
- Una prueba usaba `git worktree add --orphan`, ausente en Git antiguos. Ahora
  crea una rama normal y añade el worktree con opciones ampliamente disponibles.

## Hallazgos matizados o descartados

- El transporte ya usaba bracketed paste, no enviaba Enter, exigía exactamente
  un panel `agent`, creaba temporales `0600`, rechazaba enlaces simbólicos y
  conservaba el archivo ante errores. No se reescribieron esos principios; las
  pruebas se ampliaron para demostrar que siguen vigentes.
- Una lista rígida con solo nombres de proveedores no habría resuelto el riesgo:
  los wrappers pueden aparecer como `node` o `env`. La política combina proceso
  observado, denegación de shells, lista extensible e identidad temporal.
- Autorizar `node` por defecto se descartó porque permitiría pegar en cualquier
  proceso Node, no necesariamente en un agente.

## Pendiente conscientemente

- La revisión eliminó GNU-ismos identificados y añadió alternativas GNU/BSD
  para `stat`, pero CachyOS y macOS no estaban disponibles para pruebas reales.
- `pi` y `jarvis-coder` no estaban instalados, por lo que no se inventó su valor
  de `pane_current_command`; se conservan como identidades conocidas y el
  lanzador cubre wrappers futuros.
- Se probó la detección local de tmux anidado, no una conexión SSH real.
- No se configuraron OpenCode, JARVIS, Codex ni Claude, ni se realizó el
  empaquetado final. Esas fases quedan fuera de este endurecimiento.
