# Markdown y PDF

## Resultado

La cadena elegida es:

```text
Markdown → Pandoc → HTML autocontenido + CSS → Chromium/Chrome → PDF A4
```

No usa plugins de Neovim ni archivos ocultos de la configuración anterior. La
plantilla, el estilo, el ejemplo y el exportador viven en el repositorio.

## Por qué esta cadena

En Debian están disponibles Pandoc 3.1.11.1, Chromium 151, Google Chrome 151,
pdfLaTeX, XeLaTeX y LuaLaTeX. No están disponibles WeasyPrint, wkhtmltopdf,
Paged.js, Typst ni Tectonic.

Se eligió HTML/CSS con Chromium porque:

- el CSS es la única fuente de estilos para pantalla e impresión;
- Pandoc resuelve tablas, bloques de código, imágenes relativas y metadatos;
- Chromium soporta A4, saltos y cajas de margen paginadas con contadores;
- `--embed-resources` produce un HTML temporal autocontenido antes de imprimir;
- Chromium o Chrome están disponibles en Debian, CachyOS y macOS.

Pandoc con XeLaTeX o LuaLaTeX también es estable para impresión y queda como
alternativa si en el futuro se requieren fórmulas o composición tipográfica muy
avanzada. No se usa ahora porque obligaría a mantener estilos LaTeX separados
del CSS. WeasyPrint habría sido una buena ruta HTML/CSS, pero falta en el equipo
y no aporta una ventaja que justifique instalarlo. `wkhtmltopdf` usa un motor
HTML antiguo; Paged.js añadiría Node y otra dependencia.

## Archivos

- `scripts/markdown-pdf.sh`: exportador reproducible.
- `scripts/abrir-pdf.sh`: apertura portable del PDF ya generado.
- `markdown/filters/metadata-css.lua`: conversión segura de metadatos a texto CSS.
- `markdown/templates/documento.html`: plantilla HTML de Pandoc.
- `markdown/styles/examen.css`: estilos de pantalla e impresión.
- `examples/examen/examen.md`: examen de validación.
- `examples/examen/examen2.md`: ejemplo ampliado con código y numeración.
- `examples/examen/assets/circuito.svg`: imagen relativa del ejemplo.
- `tests/comprobar_markdown_pdf.sh`: prueba funcional que genera PDF reales.
- `tests/comprobar_markdown_pdf.lua`: integración nativa con Neovim.

Los PDF de `examples/` se ignoran en Git porque son artefactos generados.

## Uso

Desde la terminal:

```sh
./scripts/markdown-pdf.sh ruta/documento.md
./scripts/markdown-pdf.sh ruta/documento.md ruta/salida.pdf
```

Sin segundo argumento, el PDF se crea junto al Markdown con el mismo nombre.
Las rutas con espacios se admiten si se entrecomillan en la shell.

Desde Neovim, con el Markdown abierto:

- `<leader>mp` guarda el archivo y genera el PDF junto a él;
- `<leader>mv` guarda, genera el mismo PDF y lo abre en un visor externo;
- `:MarkdownPdf` guarda y genera, sin abrir un visor;
- `:MarkdownPdf ruta/salida.pdf` permite elegir la salida.

La ejecución es asíncrona y Neovim muestra una notificación al terminar.
`<leader>mp` y `:MarkdownPdf` no abren el PDF; `<leader>mv` utiliza el lanzador
portable documentado a continuación.

### Edición, previsualización y exportación

Neovim edita el Markdown; no representa visualmente un PDF dentro de un buffer.
El flujo más fiel consiste en abrir una vez el PDF generado en el visor del
sistema y mantener Markdown y visor en paralelo:

1. abrir `examen.md` en Neovim;
2. pulsar `<leader>mv` para guardar, generar `examen.pdf` y abrirlo;
3. usar `<leader>mp` cuando solo se quiera regenerar;
4. repetir `<leader>mv` para llevar al visor el PDF actualizado.

Para una salida distinta se usa `:MarkdownPdf examen-revision.pdf`. No se añade
un plugin de previsualización: el PDF de Chromium es la referencia real de lo
que recibirán los alumnos.

La visualización no crea una ruta alternativa: se ejecuta después de que el
mismo pipeline Pandoc/CSS/Chromium termine correctamente y recibe exactamente
el PDF generado. En Linux se delega por defecto en `xdg-open` y en macOS en
`open`; ambos permiten que el escritorio o la aplicación reutilicen una ventana
existente cuando lo soportan. Mientras un visor iniciado directamente siga
ejecutándose, Neovim evita lanzarlo de nuevo para ese PDF.

Puede seleccionarse un visor concreto antes de abrir Neovim:

```sh
export ENTORNO_PDF_VIEWER=/ruta/al/visor
```

El valor debe ser un ejecutable o un nombre disponible en `PATH`. Si necesita
argumentos especiales o una opción propia para reutilizar ventanas, debe
indicarse un pequeño wrapper ejecutable. No se exige Okular, Zathura, un
navegador ni ningún otro visor concreto.

## Metadatos y contenido

La cabecera YAML del documento admite estas variables:

```yaml
---
title: "Título del documento"
lang: es
module: "Desarrollo Web en Entorno Cliente"
centre: "IES Hermenegildo Lanz"
teacher: "Isaías FL"
---
```

`module`, `centre` y `teacher` son opcionales. Cuando existen, se convierten en
la cabecera izquierda, la cabecera derecha y `Profesor: nombre` en el pie
izquierdo. La numeración `Página N de M` se añade automáticamente en el pie
derecho mediante los contadores paginados de Chromium.

La plantilla solo transporta esos valores. Fuente, tamaños, color, márgenes,
separación y líneas divisorias se controlan centralmente mediante las variables
y reglas `@page` de `markdown/styles/examen.css`. Los márgenes reservan espacio
exclusivo para las cajas, evitando que cabecera y pie invadan tablas, imágenes,
código o el contenido de la primera y última página. Antes de interpolarlos, el
filtro Lua convierte `module`, `centre` y `teacher` a texto plano y escapa
comillas, barras inversas, saltos y controles para formar cadenas CSS válidas.
Así, caracteres razonables no rompen silenciosamente la cabecera o el pie.

Cada documento cambia sus textos editando únicamente el front matter:

- `module`: cabecera izquierda;
- `centre`: cabecera derecha;
- `teacher`: pie izquierdo con el prefijo `Profesor:`;
- `title`: título interno del PDF, no la cabecera marginal.

Para ocultar una de las zonas basta con omitir su metadato. La página actual y
el total se calculan automáticamente. El aspecto común de cabecera y pie se
modifica en `@page` y en las variables `--tamano-cabecera`, `--tamano-pie`,
`--color-marginal` y `--linea-marginal` del CSS central.

Para forzar un salto de página:

```markdown
::: page-break
:::
```

Para intentar mantener un bloque unido en una página:

```markdown
::: no-break
Contenido que no debería partirse.
:::
```

Los títulos `#`, `##` y `###` no dibujan líneas horizontales. Cuando un
documento necesite una separación explícita puede añadirse manualmente con una
línea Markdown formada por tres guiones, fuera del bloque YAML inicial:

```markdown
---
```

Los bloques de código admiten lenguaje para coloreado y, opcionalmente,
numeración de líneas útil en ejercicios:

````markdown
```{.python .numberLines}
print("Hola")
```
````

Las imágenes se escriben con rutas relativas al propio Markdown:

```markdown
![Descripción](assets/imagen.png){width=70%}
```

## Personalización

Los colores, familias tipográficas, márgenes A4, tablas, código y espaciado se
definen en `markdown/styles/examen.css`. Las variables de `:root` son el punto
de partida para cambios de identidad visual. Se usan alternativas tipográficas
comunes y no se presupone una Nerd Font.

Puede probarse otro estilo o plantilla sin modificar el script:

```sh
MDPDF_STYLE=ruta/otro.css ./scripts/markdown-pdf.sh documento.md
MDPDF_TEMPLATE=ruta/otra.html ./scripts/markdown-pdf.sh documento.md
```

Los emojis dependen de las fuentes instaladas y del motor del navegador. Para
elementos esenciales es preferible usar texto o una imagen versionada.

## Dependencias y portabilidad

Las dependencias directas son Pandoc y un navegador Chromium compatible:
Chromium, Google Chrome o Brave. `pdfinfo` y
`pdftotext` mejoran la prueba, pero son opcionales durante el uso normal. El
navegador se detecta por nombre; en macOS se buscan además las aplicaciones
habituales. En macOS se prioriza Chrome sobre Brave porque Brave 149 se bloqueó
en la prueba headless de Apple Silicon sin generar el PDF. `CHROMIUM_BIN`
permite indicar expresamente otro ejecutable.

Las cajas de margen `@page`, las cabeceras y pies y los contadores
`counter(page)` y `counter(pages)` se han validado con Chromium
151.0.7922.108. La versión mínima exacta de Chromium que soporta conjuntamente
estas funciones, incluida `Página X de Y`, queda por confirmar: no se deduce de
forma fiable a partir del navegador instalado y no se fija aquí una cifra
inventada. En otro sistema debe comprobarse el PDF de ejemplo antes de adoptar
una versión anterior.

Los scripts relacionados se han revisado para evitar usos evidentes no
portables como `dirname --`, `basename --` y `readlink -f`. Emplean shell POSIX
y detección separada para las rutas habituales de Chrome en macOS. Esta revisión
no sustituye una prueba real en CachyOS o macOS, que sigue pendiente.

Antes de instalar nada en otro equipo, se puede diagnosticar con:

```sh
command -v pandoc chromium google-chrome brave-browser pdfinfo pdftotext
```

## Modelo de seguridad

El exportador está diseñado para Markdown propio y confiable. No debe usarse
como compilador seguro de documentos arbitrarios de terceros: Pandoc admite
HTML crudo, los documentos pueden referenciar recursos remotos y Chromium se
ejecuta actualmente con `--allow-file-access-from-files` para que las imágenes
y estilos relativos funcionen durante la impresión.

No se implementa un sandbox en esta fase. Si en el futuro se procesan trabajos
de alumnos o Markdown no confiable habrá que evaluar, como una unidad separada:

- desactivar `raw_html`;
- impedir recursos remotos y bloquear la red de Chromium;
- revisar la necesidad de `--allow-file-access-from-files`;
- añadir sanitización específica si el modelo de amenazas lo exige.

## Comprobación

```sh
./tests/comprobar_markdown_pdf.sh
```

La prueba genera `examples/examen/examen.pdf`, cubre rutas con espacios,
metadatos ausentes y parciales, caracteres especiales, tablas con cadenas
largas, ausencia de navegador y la integración `:MarkdownPdf`/`<leader>mp`. Si
Poppler está disponible, también valida páginas, contenido y numeración mediante
`pdfinfo` y `pdftotext`.
