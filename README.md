# Entorno Neovim de Isaías

Configuración de Neovim construida desde cero, modular y portable. El objetivo
es disponer de un entorno comprensible para programación y edición de Markdown,
sin depender de una distribución prefabricada.

## Estado

El proyecto contiene un núcleo nativo de Neovim y una capa mínima de plugins:
`lazy.nvim` gestiona dependencias, `fzf-lua` proporciona búsqueda y
`nvim-tree.lua` permite recorrer el proyecto como árbol. Se ejecuta en un
entorno XDG aislado dentro del repositorio y no modifica ni enlaza
`~/.config/nvim`.

El entorno principal es Debian 13. La configuración se comprueba en paralelo
con Neovim 0.11.4 y 0.12.4 sin cambiar el binario global. Se buscará
compatibilidad razonable con CachyOS y macOS.

## Documentación

- [Decisiones e inventario](docs/decisiones.md)
- [Entorno aislado](docs/entorno-aislado.md)
- [Neovim 0.12.4 en paralelo](docs/neovim-0.12.md)
- [Plugins, búsqueda y exploración](docs/plugins.md)
- [Flujo de Markdown y PDF](docs/markdown-pdf.md)
- [Restauración](docs/restauracion.md)
- [Contexto original](CONTEXTO_INICIAL.md)

## Ejecución

Abrir Neovim con la configuración del repositorio:

```sh
./scripts/arrancar.sh
```

También se puede abrir un archivo o pasar cualquier argumento normal de
Neovim:

```sh
./scripts/arrancar.sh README.md
```

Ejecutar las comprobaciones headless:

```sh
./scripts/comprobar.sh
```

Los detalles de las rutas utilizadas y del aislamiento están en
[docs/entorno-aislado.md](docs/entorno-aislado.md).
