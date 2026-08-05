# Contexto inicial para Codex

Quiero iniciar un proyecto nuevo para reconstruir desde cero mi entorno de Neovim.

## Situación actual

```text
Sistema: Debian 13
Neovim: NVIM v0.11.4
Build type: Release
LuaJIT: 2.1.1741730670
```

Este Debian está instalado en un M.2 portátil que conecto a diferentes ordenadores de casa y del instituto. Puede arrancar sobre Intel o AMD, con gráfica integrada o dedicada. También uso CachyOS y un Mac mini, por lo que me interesa que las decisiones sean razonablemente portátiles.

## Objetivo personal

Quiero ser rápido y eficiente programando con Neovim y trabajando en terminal. Uso Bash, Zsh y Fish. Trabajo en español. Hasta ahora he usado algo de `hjkl`, aunque recurro demasiado a los cursores, y no me importa abandonar el mapeo `jk`.

También preparo exámenes en Markdown. Suelo guardar las imágenes en una carpeta y anteriormente dependía de varios plugins de VS Code. La previsualización no coincidía bien con el PDF final y terminé usando CSS personalizado. Quiero una solución futura más simple, reproducible y que permita exámenes con buen aspecto, tablas e imágenes.

## Primera tarea

No cambies todavía mi configuración.

1. Inspecciona únicamente:
   - `nvim --version`;
   - la ubicación y contenido general de `~/.config/nvim`;
   - los directorios de datos, estado y caché de Neovim;
   - las herramientas externas relacionadas que ya estén instaladas.
2. No leas secretos ni archivos `.env`.
3. Propón una copia de seguridad fechada y reversible.
4. Propón las fases del proyecto.
5. Muéstrame el plan y espera mi aprobación antes de instalar paquetes o sustituir enlaces/configuraciones.
6. Registra las decisiones importantes en `docs/decisiones.md`.

La configuración nueva deberá vivir primero dentro de este repositorio. No enlaces ni reemplaces `~/.config/nvim` hasta que tengamos una versión mínima que arranque correctamente.
