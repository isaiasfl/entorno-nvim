# Identidad visual

El logo de entorno-nvim se conserva en [IMG/logo.png](../IMG/logo.png):
PNG de 1800 × 447 píxeles con canal alfa real. Se utiliza en el README,
las chuletas, la guía de alumnado, la referencia de teclas y el fragmento Moodle.
El nombre oficial para repositorio y comandos sigue siendo `entorno-nvim`.

## Presentaciones y otros materiales

Inserte `IMG/logo.png` como imagen en PowerPoint, LibreOffice Impress o Google
Slides y conserve sus proporciones. Funciona como cabecera de portada o firma
al pie; no lo estire ni lo use como fondo de las diapositivas. Para impresión,
use un fondo claro; en fondos oscuros, los tonos azul petróleo tienen menos
contraste, por lo que conviene colocarlo dentro de una tarjeta blanca.

No hay presentaciones editables de este proyecto en el repositorio en esta
revisión. El recurso queda disponible para incorporarlo cuando se creen.
El símbolo cuadrado para iconos todavía no es un archivo independiente.

## Moodle

El fragmento HTML referencia el logo publicado de la versión 1.1.0. Si el
centro no permite imágenes externas, suba `IMG/logo.png` al editor de Moodle
y sustituya el atributo `src` por la URL del archivo subido. No copie una ruta
local de su ordenador. El fondo blanco de la tarjeta garantiza contraste.

## Terminal

El instalador conserva el IFL de texto: no depende de soporte gráfico ni de
fuentes especiales. El logo gráfico no sustituye esa cabecera.

## Barras y foco de panel — 09/11/2026

Diseño nativo sin dependencias nuevas. Neovim usa `config/statusline.lua`:
modo coloreado, archivo, `[+]` al modificar, indicadores `E` (errores) y `A`
(avisos), línea/columna; desde 100 columnas añade tipo de archivo y porcentaje.
Las ventanas inactivas quedan discretas. Paleta verde oscuro, salvia y azul,
con colores distintos para insertar, selección y reemplazo; persiste al cambiar tema.

Tmux conserva la paleta ANSI de la terminal: proyecto en verde, ventana activa
y reloj en azul, avisos amarillos de PREFIJO/COPIA/ZOOM. Recorta proyectos largos
a 24 caracteres; por debajo de 100 columnas oculta Git/agente para dejar espacio.
Git y agente siguen usando el helper existente cada 15 segundos.

Para probar: desde otra terminal, `entorno .`. El lanzador recarga la configuración
de tmux también al reconectar. Un Neovim ya abierto debe cerrarse (guardando antes)
y abrirse de nuevo para cargar su barra. No se ha cambiado `~/.config/nvim`.

Base anterior verificada en local, GitHub y casa: `3eda67696543c9f6ce2fb1a32ae9db8cc20490eb`.
Publicación autorizada el 10/11/2026. Para recibir estos cambios, guardar el
trabajo, salir del entorno y ejecutar `./scripts/actualizar.sh` desde la raíz
del repositorio. Después abrir de nuevo el editor.

### Segunda pasada: puntas e iconos

Barra única de Neovim (`laststatus=3`), puntas Powerline, rama Git e iconos
por tipo de archivo; nombre destacado y cambios sin guardar en amarillo.
La rama se consulta asíncronamente con Git, con caché de diez segundos por
carpeta y solo cuando se vuelve a renderizar la barra. No se lee el contenido
de los archivos ni se añaden plugins. El modo y la posición conservan los
bloques salvia/azul. Sin indicadores de actualizaciones.

Los iconos requieren Nerd Font (JetBrainsMono Nerd Font en el equipo del señor).
Alternativa ASCII: `ENTORNO_ICONOS=0 entorno .` desde una sesión nueva; la
variable debe llegar al proceso de Neovim. No basta reconectar un editor abierto.
Tmux conserva ASCII, separa proyecto/ventana y oculta agentes no identificados.
Copia de la primera pasada conservada en `/tmp/entorno-barras-v1/` para esta sesión;
el punto estable anterior sigue siendo el commit `3eda676`.

### Foco de panel y contraste

Proyecto verde oscuro con texto salvia; ventana activa azul claro con texto
oscuro. Etiquetas superiores EDITOR/CONSOLA/AGENTE (PANEL para divisiones sin
rol). Solo el panel activo lleva `>` y etiqueta azul clara; su borde se destaca.
La barra inferior mantiene FOCO con el rol actual, también en panel único o
zoom. Son formatos nativos de tmux: se actualizan al seleccionar un panel,
sin sondeos ni dependencias. Las etiquetas consumen una fila por panel.
