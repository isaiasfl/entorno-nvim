# Git y lazygit

La integración usa el `lazygit` 0.50.0 proporcionado por Debian y el terminal
nativo de Neovim. No instala plugins Git ni ejecuta acciones Git por su cuenta.

Desde un archivo del proyecto, `<leader>gg` abre lazygit en una ventana
flotante y sitúa su directorio de trabajo en la raíz Git correspondiente. Al
salir de lazygit con `q`, la ventana se cierra y el foco vuelve a Neovim.
Desde una terminal normal, el mismo flujo se inicia ejecutando `lazygit` dentro
del repositorio.

## Flujo básico

| Acción | Tecla habitual en lazygit |
| --- | --- |
| Revisar el estado | La vista inicial muestra archivos y cambios |
| Ver el diff | Seleccionar un archivo o commit y pulsar `Enter` |
| Preparar o retirar un archivo | `Space` sobre el archivo |
| Crear un commit | `c`, escribir el mensaje y confirmar |
| Enviar commits al remoto | `P` y confirmar el push |
| Salir y volver a Neovim | `q` |

`?` muestra la ayuda contextual de la vista activa. Stage, commit y push siempre
requieren una acción explícita del usuario; la configuración no automatiza
ninguna operación ni almacena credenciales.
