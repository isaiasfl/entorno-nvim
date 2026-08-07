# Neovim 0.12.4 en paralelo

## Origen verificado

La versión `v0.12.4` está publicada como estable y `Release` en el repositorio
oficial `neovim/neovim`. Para este equipo Linux `x86_64` se utiliza:

```text
Activo: nvim-linux-x86_64.tar.gz
URL: https://github.com/neovim/neovim/releases/download/v0.12.4/nvim-linux-x86_64.tar.gz
SHA-256: 012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628
```

El digest corresponde específicamente al activo de `v0.12.4`; no se reutiliza
ninguna suma de versiones anteriores.

## Instalación

El tarball se valida antes de extraer. Su listado debe contener únicamente
rutas relativas bajo `nvim-linux-x86_64/`. Después se extrae en un directorio
temporal y se mueve a:

```text
~/.local/opt/nvim-0.12.4
```

Procedimiento reproducible utilizado:

```sh
workdir="$(mktemp -d /tmp/neovim-v0.12.4.XXXXXX)"
archive="$workdir/nvim-linux-x86_64.tar.gz"
listing="$workdir/listing.txt"

curl --fail --location --proto '=https' --tlsv1.2 \
  --output "$archive" \
  https://github.com/neovim/neovim/releases/download/v0.12.4/nvim-linux-x86_64.tar.gz

printf '%s  %s\n' \
  012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628 \
  "$archive" | sha256sum --check -

tar -tzf "$archive" > "$listing"
awk 'BEGIN { ok = 1 }
  /^\// || /(^|\/)\.\.(\/|$)/ || $0 !~ /^nvim-linux-x86_64(\/|$)/ {
    print "Ruta no valida: " $0 > "/dev/stderr"
    ok = 0
  }
  END { exit(ok ? 0 : 1) }' "$listing"
tar -xzf "$archive" -C "$workdir"
test ! -e "$HOME/.local/opt/nvim-0.12.4"
mkdir -p "$HOME/.local/opt"
mv "$workdir/nvim-linux-x86_64" "$HOME/.local/opt/nvim-0.12.4"
```

Antes de la extracción se validó automáticamente que las 2228 entradas eran
relativas, no contenían componentes `..` y comenzaban por el único directorio
`nvim-linux-x86_64/`.

No se modifica `/usr/local/bin/nvim`, `PATH`, la configuración activa ni se
crean enlaces. El runner selecciona por defecto el binario paralelo. También
puede indicarse de forma explícita:

```sh
NVIM_BIN="$HOME/.local/opt/nvim-0.12.4/bin/nvim" \
NVIM_XDG_ROOT="$PWD/.xdg/0.12.4" \
./scripts/arrancar.sh
```

## Comprobación

La migración inicial mantuvo raíces independientes:

| Versión | Binario | Estado aislado |
| --- | --- | --- |
| 0.11.4 | `/usr/local/bin/nvim` | `.xdg/0.11.4` |
| 0.12.4 | `~/.local/opt/nvim-0.12.4/bin/nvim` | `.xdg/0.12.4` |

La fase Tree-sitter adopta 0.12.4 como versión mínima y usa por defecto
`.xdg/0.12.4`. `./scripts/comprobar.sh` valida núcleo, plugins, parsers,
Markdown, atajos, EditorConfig, undo, swap y `checkhealth`.

## Resultado de compatibilidad

Antes de adoptar Tree-sitter externo, la matriz pasó con ambas versiones y los
mismos commits de Lazy y `fzf-lua`.
Los informes no contienen errores y comparten únicamente avisos por componentes
opcionales que no se han instalado: iconos y previsualizadores multimedia de
`fzf-lua`, y proveedores Node, Perl y Ruby.

Neovim 0.12.4 añade información de versión, `vim.pack`, herramientas externas y
consultas Treesitter al informe. Tanto 0.11.4 como 0.12.4 incluyen parsers para
Markdown; 0.12.4 activa además su resaltado Treesitter integrado por defecto.
Ese resultado es histórico: la configuración actual incorpora nvim-treesitter
y requiere 0.12.4.

## Reversión

Definir `NVIM_BIN=/usr/local/bin/nvim` sigue seleccionando el binario 0.11.4,
pero la configuración actual lo rechazará de forma explícita. Para volver a esa
versión también hay que restaurar una revisión del repositorio compatible. La
instalación paralela puede eliminarse posteriormente, con aprobación expresa,
solo cuando ya no sea la versión objetivo.

Tras cerrar sus sesiones y obtener aprobación para el borrado:

```sh
rm -rf -- "$HOME/.local/opt/nvim-0.12.4"
```
