# Markdown y PDF

## Necesidad

El flujo debe manejar exámenes con tablas e imágenes y producir una
previsualización cercana al PDF final. También debe ser reproducible y evitar
archivos de estilo ocultos en la configuración personal.

## Estado actual

La configuración anterior genera HTML con Pandoc y después intenta convertirlo
con WeasyPrint. Depende de una plantilla y un CSS bajo `~/.config/mdpdf`, y abre
el resultado con `xdg-open`. Pandoc está instalado, pero WeasyPrint no está en el
`PATH`. También están disponibles pdfLaTeX, XeLaTeX y LuaLaTeX.

## Criterio propuesto

No se elegirá todavía un plugin de previsualización ni se instalará un motor.
Primero se añadirá al repositorio un documento de muestra, una imagen local y
los estilos necesarios. Se compararán dos rutas:

1. Pandoc a HTML/PDF con CSS compartido, que favorece la coherencia visual entre
   navegador y PDF pero puede requerir un conversor adicional.
2. Pandoc a PDF mediante XeLaTeX o LuaLaTeX, ya disponibles, con buena tipografía
   e impresión pero una previsualización distinta del PDF.

La decisión se tomará midiendo tablas, saltos de página, imágenes, tipografía,
velocidad y comportamiento en Linux y macOS. Cualquier dependencia Node o
script de construcción requerirá revisión específica antes de ejecutarse.
