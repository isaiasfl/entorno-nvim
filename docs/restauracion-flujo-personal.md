# Recuperacion del flujo personal

Se restaura el perfil completo como predeterminado, con PDF, atajos de IA
y tmux con tres paneles. Los perfiles docentes reducidos quedan optativos.
La sesion personal vuelve al nombre historico por proyecto, sin sufijo de
perfil. No se eliminan ni migran sesiones abiertas.

Atajos originales: Espacio e e (explorador), Espacio e f (archivo actual),
Espacio m p (PDF), Espacio m v (PDF y visor), Espacio a c (contexto de agente).
Ctrl-a seguido de ? conserva la ayuda de tmux. tmux/tmux.conf y la
configuracion del plugin explorador no se han modificado.

La copia previa a esta correccion esta en
`/tmp/entorno-antes-restauracion-4zMCEq`; es temporal, no un respaldo permanente.
Los originales versionados siguen en Git. No se modifica Omarchy ni se
instalan dependencias. Los plugins y las herramientas de PDF ausentes siguen
requiriendo preparacion: restaurar los atajos no instala esas herramientas.

Leccion: conservar primero el flujo personal; cualquier simplificacion para
alumnos debe ser optativa y comprobarse sin cambiar los valores habituales.

Se instalaron los 11 plugins en las revisiones del lockfile dentro de
`.xdg/0.12.4/data/nvim/lazy`, sin modificar la configuracion de Omarchy.
`tests/comprobar_explorador_real.lua` comprueba NvimTree real: panel lateral,
apertura desde inicio y cierre con Espacio e. No basta comprobar el sustituto
Netrw para declarar recuperado el explorador original.
