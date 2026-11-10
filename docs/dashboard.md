# Dashboard IFL

## Decisión

La pantalla inicial está implementada con la API nativa de Neovim. No se añade
`dashboard-nvim`, `alpha-nvim`, `mini.starter` ni otro plugin: para un logotipo
Unicode y diez acciones, un módulo pequeño ofrece menos arranque, menos
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
| `?` | Abrir Ayuda y atajos |
| `q` | Salir |

Las búsquedas reutilizan el buscador ya fijado en el lockfile y el explorador y
lazygit reutilizan sus integraciones existentes. El dashboard carga cada uno
solo cuando se pulsa su acción.

## Diseño y mantenimiento

El IFL ancho usa bloques Unicode, con acento azul suave. Menú con iconos a
la izquierda y teclas alineadas a la derecha, acentos salvia/amarillo y mayor
separación vertical desde 38 filas. Con menos de 26 filas se oculta el logo
para conservar todas las acciones. Los iconos requieren Nerd Font; con
`ENTORNO_ICONOS=0` se sustituyen por un punto sencillo.

El pie muestra carpeta y perfil. La versión y los detalles se consultan en
`:EntornoInfo`. `:IFL` permite volver. El conjunto se centra y recalcula al
redimensionar la ventana; no se han añadido dependencias ni restauración de
sesiones. El diseño anterior es recuperable en el historial Git, commit `3eda676`.

La implementación está en `nvim/lua/config/dashboard.lua` y la prueba en
`tests/comprobar_dashboard.lua`.

El pie usa texto claro sin cursiva. Las teclas normales de edición se ignoran
en la bienvenida para evitar E21; las acciones del menú conservan prioridad.
La protección de solo lectura se mantiene; no se habilita modifiable.
