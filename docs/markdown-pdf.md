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
- `markdown/templates/documento.html`: plantilla HTML de Pandoc.
- `markdown/styles/examen.css`: estilos de pantalla e impresión.
- `examples/examen/examen.md`: examen de validación.
- `examples/examen/assets/circuito.svg`: imagen relativa del ejemplo.
- `tests/comprobar_markdown_pdf.sh`: prueba funcional que genera un PDF real.

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
- `:MarkdownPdf` hace lo mismo;
- `:MarkdownPdf ruta/salida.pdf` permite elegir la salida.

La ejecución es asíncrona y Neovim muestra una notificación al terminar. El
comando no abre el PDF automáticamente, para conservar portabilidad y evitar
acoplar el flujo a `xdg-open` o `open`.

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
código o el contenido de la primera y última página. Conviene evitar comillas
dobles dentro de los tres metadatos porque se insertan como contenido CSS.

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

Las dependencias directas son Pandoc y Chromium o Google Chrome. `pdfinfo` y
`pdftotext` mejoran la prueba, pero son opcionales durante el uso normal. El
navegador se detecta por nombre; en macOS se buscan además las aplicaciones
habituales. `CHROMIUM_BIN` permite indicar otro ejecutable.

Antes de instalar nada en otro equipo, se puede diagnosticar con:

```sh
command -v pandoc chromium google-chrome pdfinfo pdftotext
```

## Comprobación

```sh
./tests/comprobar_markdown_pdf.sh
```

La prueba genera `examples/examen/examen.pdf`, comprueba que no esté vacío, que
tenga al menos dos páginas y, si Poppler está disponible, valida contenido y
numeración mediante `pdfinfo` y `pdftotext`.
