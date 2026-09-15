# Instalación reproducible V1

> Evolucion docente: las nuevas instalaciones privadas van a `.tools/` dentro
> del repositorio y el instalador ya no crea el enlace `~/.local/bin/entorno-dev`.
> El arranque minimo, los perfiles y sus limites estan en
> [entorno-docente.md](entorno-docente.md). Las rutas `~/.local/opt` de este
> documento describen la instalacion historica V1.

## Alcance

`scripts/instalar.sh` coordina las instalaciones de usuario, lockfiles y
comprobaciones. No activa `~/.config/nvim`, no ejecuta `sudo`, no toca la
configuración tmux personal, no instala agentes CLI ni crea comandos globales.
Quien quiera el enlace opcional `~/.local/bin/entorno-dev` debe ejecutar
`scripts/instalar-entorno-dev.sh`; si el destino ya existe y no pertenece al
proyecto, ese script se detiene sin sobrescribirlo.

```sh
./scripts/comprobar-requisitos.sh
./scripts/instalar.sh
./scripts/arrancar.sh
```

Para ejecutar `entorno-dev` desde cualquier directorio, `~/.local/bin` debe
estar incluido en `PATH`. Muchas distribuciones lo añaden al iniciar sesión;
puede comprobarse con `command -v entorno-dev`.

El comprobador nunca modifica la máquina. El instalador se puede repetir: una
instalación correcta se verifica y se conserva; un destino existente pero
distinto provoca un error en lugar de ser sobrescrito.

## Plataformas

**PROBADO:** Debian 13 x86_64.

**OBJETIVO, NO PROBADO:** Arch/CachyOS x86_64 y macOS moderno. En Linux x86_64
los artefactos oficiales fijados de Neovim, tree-sitter CLI y LuaLS son comunes
a Debian y Arch. En macOS solo se automatiza tree-sitter CLI, cuyos ZIP para
Intel y Apple Silicon tienen checksum auditado. Neovim 0.12.4 y LuaLS 3.19.0
deben prepararse externamente y pasarse mediante `NVIM_BIN` y `LUALS_BIN`; la
V1 se niega a fingir una instalación reproducible sin artefactos auditados.

Si faltan paquetes del sistema, el instalador imprime un comando orientativo
para `apt`, `pacman` o Homebrew y termina. El usuario debe revisarlo y aprobar
su ejecución separadamente; el script nunca lo ejecuta.

## Orden y fuentes

1. Neovim 0.12.4 bajo `~/.local/opt`, con SHA-256 del tarball y del binario.
2. tree-sitter CLI 0.26.11, con ZIP y plataforma explícitos.
3. LuaLS 3.19.0, con SHA-256 del tarball y del binario.
4. LSP web y Pyright mediante Corepack/pnpm 11.18.0 y lockfiles congelados.
5. plugins mediante `:Lazy restore`, respetando `lazy-lock.json`.
6. parsers Tree-sitter enumerados explícitamente y compilados en la raíz XDG.
7. comprobación final de requisitos.
8. comprobación final sin crear enlaces globales. El enlace seguro opcional
   del lanzador `entorno-dev` se crea aparte con
   `scripts/instalar-entorno-dev.sh`.

No se usa Mason, npm global, TPM, `curl | sh` ni instalación automática al
arrancar Neovim. Las descargas directas usan HTTPS, staging temporal y
verificación antes de mover el resultado.

## Activación, actualización y retirada

La activación es deliberadamente separada: `./scripts/activar.sh`. Su rollback
es `./scripts/restaurar.sh`. Para actualizar una versión se cambian primero las
constantes y fuentes revisadas, después los lockfiles correspondientes y por
último se ejecuta la suite completa.

La desinstalación no es automática. Tras restaurar, se pueden eliminar de forma
manual la raíz `.xdg/` y los directorios concretos versionados de
`~/.local/opt`; los backups históricos no se borran.

## Prueba aislada

`tests/comprobar_instalacion.sh` crea HOME y XDG temporales, clona localmente
las revisiones ya fijadas de plugins, copia los parsers regenerables, arranca
Neovim, carga la configuración, valida tmux y genera el PDF real. No sustituye
ni enlaza la configuración activa y elimina solo su directorio temporal.
