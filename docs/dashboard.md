# Dashboard IFL

## Decisión

La pantalla inicial está implementada con la API nativa de Neovim. No se añade
`dashboard-nvim`, `alpha-nvim`, `mini.starter` ni otro plugin: para un logotipo
ASCII y seis acciones, un módulo pequeño ofrece menos arranque, menos
dependencias y un comportamiento más fácil de entender.

## Comportamiento

El dashboard aparece únicamente al iniciar Neovim sin archivos ni entrada
estándar y con una interfaz conectada. Por tanto, no sustituye un archivo pedido
en la línea de comandos, no aparece en procesos headless y no altera tuberías.

También puede abrirse en cualquier momento con:

```vim
:IFL
```

El buffer es temporal, no figura en la lista de buffers, no admite cambios y no
crea archivo swap. Oculta localmente números, columna de signos, marcas de fin
de buffer y contenido de la línea de estado; al abandonarlo restaura las
opciones que tenía la ventana.

## Acciones

| Tecla | Acción |
| --- | --- |
| `f` | Buscar archivos con fzf-lua |
| `g` | Buscar texto con fzf-lua |
| `e` | Abrir el explorador existente nvim-tree |
| `b` | Mostrar buffers con fzf-lua |
| `r` | Mostrar archivos recientes con fzf-lua |
| `l` | Abrir lazygit en el terminal nativo |
| `n` | Crear un buffer vacío |
| `c` | Abrir `nvim/init.lua` |
| `q` | Salir |

Las búsquedas reutilizan el buscador ya fijado en el lockfile y el explorador y
lazygit reutilizan sus integraciones existentes. El dashboard carga cada uno
solo cuando se pulsa su acción.

## Diseño y mantenimiento

El logotipo textual usa caracteres de bloque Unicode estándar y no requiere
Nerd Font. Los grupos `IFLLogo`, `IFLSubtitle`, `IFLKey`, `IFLDescription` e
`IFLSecondary` separan logotipo, subtítulo, teclas, acciones e información
discreta. Enlazan con grupos estándar del esquema de colores, por lo que se
adaptan sin fijar una paleta propia.

El menú se calcula como una caja única: todas las teclas y descripciones
comparten columna y el conjunto se vuelve a centrar al cambiar el tamaño de la
interfaz. Bajo el menú aparecen la versión efectiva de Neovim y el directorio
actual, abreviado cuando no cabe.

La implementación está en `nvim/lua/config/dashboard.lua` y la prueba en
`tests/comprobar_dashboard.lua`.
