# Entorno docente portable: primera fase

## Estado de esta fase

El arranque predeterminado vuelve a ser el personal: perfil profesor y tmux
con editor, agente y terminal. PDF y los atajos historicos estan habilitados.
Los perfiles reducidos son optativos; `--sin-tmux` abre solo el editor y
`--sin-ia` omite la integracion y el panel de agente.
El editor puede arrancar sin plugins ni servidores preparados, sin red.
Usa el Neovim del sistema si no existe el binario privado, con una version minima
de 0.12. Esto permite trabajar en modo nativo; **no significa que el
autocompletado de lenguajes este disponible sin sus servidores**.

El comportamiento docente completo se prepara con las versiones fijadas.
La base esta dirigida a Omarchy/Arch, Debian y Ubuntu, con o sin escritorio,
y Ubuntu dentro de WSL2. Node 24 LTS se descarga verificado dentro del
repositorio (`scripts/instalar-node.sh`), de modo que el alumno no depende de un
Node 24 del sistema. `scripts/lib/plataforma.sh` centraliza la deteccion de
distribucion, WSL2 y arquitectura. En WSL2 el navegador es opcional: sin WSLg se
mantienen editor, tmux, lazygit y Git, pero el PDF puede no estar disponible.
WSL2 y Debian requieren validacion real adicional; las pruebas locales de esta
fase se realizan en Omarchy.

## Uso desde una carpeta

Desde este repositorio:

```sh
./bin/entorno-dev
./bin/entorno-dev --perfil dwec /ruta/a/mi-proyecto
./bin/entorno-dev --perfil si --tmux /ruta/a/laboratorio
./bin/entorno-dev --perfil profesor --tmux --ia /ruta/a/mi-proyecto
```

Desde cualquier otra carpeta se puede invocar la ruta absoluta al lanzador.
No hace falta instalar un comando global, cambiar PATH ni crear enlaces.
Las opciones van antes de la carpeta. Para abrir un archivo y pasar argumentos
de Neovim directamente:

```sh
ENTORNO_PERFIL=dwec /ruta/entorno-nvim/scripts/arrancar.sh index.html
```

`--elegir` conserva el selector de proyectos tmux. Busca en `~/Work`,
`~/Proyectos` y `~/Projects`, si existen. `ENTORNO_TMUX_PROJECT_ROOTS`
permite elegir otras raices.

## Perfiles

| Perfil | Servidores seleccionados, si estan preparados | Diagnosticos | PDF | IA |
| --- | --- | --- | --- | --- |
| inicial | Web, para completado | Desactivados | No | Solo con `--ia` |
| dwec | HTML/CSS/JSON, JS/TS/JSX/TSX y Tailwind | Si | No | Solo con `--ia` |
| si | Bash y Python | Si | No | Solo con `--ia` |
| profesor (predeterminado) | Web, Python y Lua | Si | Si | Si; desactivar con `--sin-ia` |

La seleccion reside en `nvim/lua/config/profile.lua`. El perfil SI incorpora
Bash Language Server 5.6.0 con Node 24 local, ShellCheck y Pyright. Siguen
pendientes las integraciones de Zsh, Docker, kubectl y Kubernetes.

`:EntornoInfo` indica el perfil, la IA y los componentes pendientes. Si faltan
plugins, funcionan el explorador nativo, la apertura de archivos, los buffers
y la busqueda con ripgrep cuando existe. Los fallos internos de plugins
instalados no se silencian: el modo nativo solo cubre componentes ausentes.

## Aislamiento y convivencia

- Las nuevas instalaciones de Neovim, LuaLS y Tree-sitter CLI van a `.tools/`.
  `ENTORNO_TOOLS_ROOT` permite cambiar esa raiz; una ruta relativa se interpreta
  desde el repositorio. Los overrides individuales de los instaladores siguen
  disponibles, pero el arranque debe recibir las rutas correspondientes.
- Los LSP web, Python y Bash mantienen sus `node_modules` dentro de `tools/`.
- Los plugins y la cache permanecen en `.xdg/0.12.4/`. Estado, undo y swap se
  separan en `.xdg/0.12.4/state/<perfil>/nvim/`.
- Se conserva `XDG_RUNTIME_DIR`: Wayland y el portapapeles necesitan el runtime
  real del escritorio. El socket principal y los contextos propios van al
  subdirectorio `runtime/` de la raiz aislada.
- Visores y lazygit recuperan las rutas XDG originales del usuario para
  conservar asociaciones y configuracion personal. Como aplicaciones externas,
  pueden escribir su propio estado normal; esto no es una caja de aislamiento.
- La sesion tmux incluye perfil e indicador IA en su nombre, evitando reutilizar
  un editor con otro perfil. Sin IA hay editor y terminal; con IA se anade el
  panel de selector. Las sesiones antiguas no se cierran ni se migran.
- `NVIM_BIN` selecciona el binario **dentro del wrapper aislado**, tambien con
  tmux. `ENTORNO_EDITOR_COMMAND` es un override avanzado del comando completo,
  usado en pruebas; omite deliberadamente el wrapper y no es la via docente.

No se reemplaza `~/.config/nvim`, el comando `nvim`, la shell ni la configuracion
de Omarchy. `instalar.sh` ya no crea `~/.local/bin/entorno-dev`. El instalador
explicito de ese enlace sigue disponible para quien quiera instalarlo.
`activar.sh` y `restaurar.sh` se conservan como procedimientos historicos de V1;
**no son necesarios ni recomendados para convivir con Omarchy**.

Node y Corepack ya no son requisitos externos: `scripts/instalar-node.sh`
descarga Node 24 LTS verificado dentro de `.tools/`. En arquitecturas sin
artefacto fijado (por ejemplo Linux ARM) se usa el Node del sistema y Neovim,
LuaLS o tree-sitter deben prepararse aparte. Pandoc es opcional: solo hace
falta para el perfil profesor y la exportacion Markdown/PDF; los perfiles
inicial, DWEC y SI funcionan sin el. El arranque nativo puede usar Neovim 0.12+ existente, mientras
`comprobar-requisitos.sh` distingue requisitos obligatorios de opcionales. Un perfil no es una barrera de seguridad:
los comandos conservan los permisos del usuario.

## Comprobaciones

```sh
sh tests/comprobar_portabilidad.sh
sh tests/comprobar_tmux.sh
sh tests/comprobar_activacion.sh
```

La primera prueba usa directorios temporales sin plugins, verifica los cuatro
perfiles, edicion/guardado, ubicacion del undo, runtime del escritorio,
navegacion nativa y opt-in de IA. No instala dependencias ni inicia agentes.
La prueba tmux utiliza un socket independiente y agentes simulados.
La suite completa `scripts/comprobar.sh` selecciona profesor con IA habilitada
para probar la funcionalidad historica; exige las dependencias preparadas.

## Siguientes fases

1. Preparacion local del runtime Node/Corepack y DWEC completo: pruebas reales
   de React/TSX/Tailwind, formato, ejecucion y diagnosticos por proyecto.
2. Validacion de la misma version en Ubuntu/WSL2 y Debian sin escritorio.
3. Modulo SI: Bash/Zsh y ayuda de Dockerfile/Compose/YAML, antes de desplegar
   servicios. Los clústeres y practicas de redes requieren laboratorios propios.
4. Evaluar Herdr como integracion opcional; el editor funciona sin multiplexor.
