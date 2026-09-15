#!/bin/sh
# Sustituto del binario, no de la configuracion: solo comprueba el lanzador.
printf '%s\n' "$PWD" "$ENTORNO_PERFIL" "${ENTORNO_IA:-0}" "$XDG_CONFIG_HOME" "$XDG_STATE_HOME"
