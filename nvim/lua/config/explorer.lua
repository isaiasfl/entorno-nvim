-- Opciones del explorador nvim-tree.
--
-- Vive fuera de plugins/ porque :EntornoIconos debe poder reaplicarlas sin
-- reiniciar el editor: nvim-tree admite llamar a setup() otra vez.
local M = {}

local function on_attach(bufnr)
  local api = require("nvim-tree.api")

  api.config.mappings.default_on_attach(bufnr)

  local function map(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, {
      buffer = bufnr,
      desc = desc,
      noremap = true,
      nowait = true,
      silent = true,
    })
  end

  map("<C-h>", "<C-w>h", "Ventana izquierda")
  map("<C-j>", "<C-w>j", "Ventana inferior")
  map("<C-k>", "<C-w>k", "Ventana superior")
  map("<C-l>", "<C-w>l", "Ventana derecha")
  map("p", function()
    require("config.explorer_preview").toggle(api.tree.get_node_under_cursor(), bufnr)
  end, "Alternar vista previa")
end

-- Sin Nerd Font los glifos del arbol se ven como cuadros, asi que se sustituyen
-- por ASCII. Se conservan las flechas de carpeta porque marcan la jerarquia.
local function glyphs(sin_iconos)
  if not sin_iconos then
    return {}
  end

  return {
    default = "",
    symlink = "",
    bookmark = "",
    modified = "*",
    hidden = "",
    folder = {
      arrow_closed = ">",
      arrow_open = "v",
      default = "",
      open = "",
      empty = "",
      empty_open = "",
      symlink = "",
      symlink_open = "",
    },
  }
end

function M.opts()
  local iconos = require("config.iconos").activos()

  return {
    on_attach = on_attach,
    disable_netrw = true,
    hijack_netrw = true,
    sync_root_with_cwd = false,
    respect_buf_cwd = false,
    hijack_directories = {
      enable = false,
      auto_open = false,
    },
    update_focused_file = {
      enable = false,
      update_root = {
        enable = false,
      },
    },
    git = {
      enable = false,
    },
    diagnostics = {
      enable = false,
    },
    modified = {
      enable = false,
    },
    renderer = {
      decorators = {},
      icons = {
        web_devicons = {
          file = {
            enable = iconos,
            color = iconos,
          },
          folder = {
            enable = false,
            color = false,
          },
        },
        padding = {
          icon = iconos and " " or "",
          folder_arrow = " ",
        },
        show = {
          file = iconos,
          folder = iconos,
          folder_arrow = true,
          git = false,
          modified = false,
          hidden = false,
          diagnostics = false,
          bookmarks = false,
        },
        glyphs = glyphs(not iconos),
      },
    },
    view = {
      signcolumn = "no",
    },
    filters = {
      enable = false,
    },
    ui = {
      confirm = {
        remove = true,
        trash = true,
        default_yes = false,
      },
    },
  }
end

--- Reaplica las opciones si nvim-tree ya esta cargado. Si no lo esta, el
--- plugin tomara la configuracion nueva la primera vez que se abra.
function M.aplicar()
  if package.loaded["nvim-tree"] == nil then
    return
  end

  local api = require("nvim-tree.api")
  local visible = api.tree.is_visible()

  require("nvim-tree").setup(M.opts())

  -- setup() rehace la vista: si el arbol estaba abierto se vuelve a abrir.
  if visible then
    pcall(api.tree.open)
  end
  pcall(api.tree.reload)
end

return M
