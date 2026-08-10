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
crea archivo swap. Oculta localmente números, columna de signos y otros adornos;
al abandonarlo restaura las opciones que tenía la ventana.

## Acciones

| Tecla | Acción |
| --- | --- |
| `f` | Buscar archivos con fzf-lua |
| `g` | Buscar texto con fzf-lua |
| `r` | Mostrar archivos recientes con fzf-lua |
| `n` | Crear un buffer vacío |
| `c` | Abrir `nvim/init.lua` |
| `q` | Salir |

Las tres búsquedas reutilizan el único buscador ya fijado en el lockfile. El
dashboard no carga `fzf-lua` hasta que se pulsa una de esas acciones.

## Diseño y mantenimiento

El logotipo usa exclusivamente ASCII y no requiere Nerd Font. Los grupos
`IFLLogo`, `IFLTitle`, `IFLAction` e `IFLFooter` enlazan con grupos estándar del
esquema de colores, por lo que se adaptan sin fijar una paleta propia. El
contenido vuelve a centrarse cuando cambia el tamaño de la interfaz.

La implementación está en `nvim/lua/config/dashboard.lua` y la prueba en
`tests/comprobar_dashboard.lua`.
