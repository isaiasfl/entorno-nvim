# Tree-sitter y parsers

## Arquitectura

Neovim 0.12.4 aporta el resaltador Tree-sitter y los parsers nativos de Lua,
Markdown y Markdown inline. Esos tres parsers no se reemplazan. El proyecto
instala externamente solo:

- `bash`;
- `python`;
- `javascript`;
- `typescript`;
- `tsx`;
- `json`;
- `html`;
- `css`.

El resaltado se activa mediante `vim.treesitter.start()` solo cuando
`vim.treesitter.language.add()` confirma que el parser está disponible. No se
habilitan indentación, plegado, textobjects ni instalación bajo demanda.

## Gestor congelado

`nvim-treesitter/nvim-treesitter` quedó archivado el 3 de abril de 2026. Se usa
su último commit, `4916d6592ede8c07973490d9322f187e07dfefac`, porque conserva
un registro explícito de revisiones y no necesita otro plugin. El sucesor
comunitario evaluado añade un plugin de registro y versiones resueltas de forma
dinámica, fuera del alcance aprobado.

Esta elección es conservadora y reproducible, pero no recibe mantenimiento.
Antes de actualizar Neovim o ampliar lenguajes se debe reevaluar el gestor y no
usar `TSUpdate` sobre este estado congelado.

## tree-sitter-cli

Se usa la release oficial 0.26.11 para Linux x86_64:

| Dato | Valor |
| --- | --- |
| Activo | `tree-sitter-cli-linux-x64.zip` |
| URL | `https://github.com/tree-sitter/tree-sitter/releases/download/v0.26.11/tree-sitter-cli-linux-x64.zip` |
| SHA-256 | `ff1b7f9863f2faafd78dc0e66d902ee85b37f709b314b22c009f51caf233eebd` |
| Contenido | Un único ejecutable llamado `tree-sitter` |
| Instalación | `~/.local/opt/tree-sitter-cli-0.26.11/bin/tree-sitter` |

`scripts/arrancar.sh` antepone al `PATH` únicamente el directorio de este
ejecutable durante el proceso de Neovim. No cambia el `PATH` de la sesión ni del
sistema. Otra instalación puede seleccionarse explícitamente:

```sh
TREE_SITTER_BIN=/ruta/a/tree-sitter ./scripts/arrancar.sh
```

La instalación antigua 0.25.10 sigue intacta en `/usr/local/bin/tree-sitter` y
apunta al paquete npm global. Esta duplicidad es temporal y reversible.

**Tarea futura:** cuando toda la configuración esté validada, revisar y retirar
con aprobación expresa la instalación global de npm, y consolidar una única
versión de `tree-sitter-cli`.

## Fuentes fijadas

| Parser | Repositorio | Revisión |
| --- | --- | --- |
| bash | `tree-sitter/tree-sitter-bash` | `a06c2e4415e9bc0346c6b86d401879ffb44058f7` |
| python | `tree-sitter/tree-sitter-python` | `v0.25.0` |
| javascript | `tree-sitter/tree-sitter-javascript` | `58404d8cf191d69f2674a8fd507bd5776f46cb11` |
| typescript | `tree-sitter/tree-sitter-typescript`, subdirectorio `typescript` | `75b3874edb2dc714fb1fd77a32013d0f8699989f` |
| tsx | `tree-sitter/tree-sitter-typescript`, subdirectorio `tsx` | `75b3874edb2dc714fb1fd77a32013d0f8699989f` |
| json | `tree-sitter/tree-sitter-json` | `001c28d7a29832b06b0e831ec77845553c89b56d` |
| html | `tree-sitter/tree-sitter-html` | `73a3947324f6efddf9e17c0ea58d454843590cc0` |
| css | `tree-sitter/tree-sitter-css` | `dda5cfc5722c429eaba1c910ca32c2c0c5bb1a3f` |

`ecma`, `jsx` y `html_tags` son colecciones de consultas compartidas del
plugin; no generan parsers adicionales. Los ocho binarios compilados viven en
la raíz XDG seleccionada, por ejemplo
`.xdg/0.12.4/data/nvim/site/parser/`, y están ignorados por Git.

## Instalación y actualización

La instalación nunca ocurre al arrancar. Se ejecuta de forma explícita:

```sh
NVIM_BIN=~/.local/opt/nvim-0.12.4/bin/nvim \
NVIM_XDG_ROOT=.xdg/0.12.4 \
./scripts/instalar-parsers.sh
```

No hay hook `build`, `TSUpdate` automático ni lista abierta de lenguajes. Para
actualizar se deben revisar de nuevo el gestor, cada repositorio y cada revisión,
y después reinstalar y ejecutar la suite completa.

El instalador descarga por HTTPS archivos asociados a las revisiones fijadas,
pero no verifica una suma independiente para cada tarball. Después compila y
carga código nativo dentro de Neovim. Este es el principal riesgo residual de
cadena de suministro.

## React y Tailwind CSS

El parser `tsx` reconoce la sintaxis JSX/React dentro de TypeScript. Tree-sitter
no comprende componentes, tipos de React ni APIs del proyecto; esas funciones
corresponderán al LSP.

Tailwind CSS no es un lenguaje sintáctico independiente y no necesita parser.
Queda como necesidad futura de LSP y autocompletado mediante Tailwind CSS
Language Server cuando se implemente esa fase.

## Reversión

Para dejar de usar el CLI paralelo se puede seleccionar otro con
`TREE_SITTER_BIN`. Su directorio bajo `~/.local/opt` solo debe eliminarse con
aprobación y cuando ningún proyecto lo use.

Los parsers aislados se regeneran con `scripts/instalar-parsers.sh`; eliminar la
raíz XDG de la versión devuelve el entorno a los parsers nativos. Para retirar
la integración del repositorio también hay que eliminar la especificación del
plugin, el autocomando y su entrada en `lazy-lock.json`.
