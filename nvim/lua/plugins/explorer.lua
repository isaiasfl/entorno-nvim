return {
  {
    "nvim-tree/nvim-tree.lua",
    cmd = {
      "NvimTreeFocus",
      "NvimTreeOpen",
      "NvimTreeToggle",
    },
    keys = {
      {
        "<leader>ee",
        function()
          require("nvim-tree.api").tree.toggle({ focus = true })
        end,
        desc = "Abrir o cerrar el arbol de archivos",
      },
      {
        "<leader>ef",
        function()
          local path = vim.api.nvim_buf_get_name(0)
          if path == "" then
            vim.notify("El buffer actual no corresponde a un archivo", vim.log.levels.WARN)
            return
          end

          require("nvim-tree.api").tree.find_file({
            open = true,
            focus = true,
            update_root = false,
          })
        end,
        desc = "Enfocar el archivo actual en el arbol",
      },
    },
    opts = function()
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
      end

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
            show = {
              file = false,
              folder = false,
              folder_arrow = false,
              git = false,
              modified = false,
              hidden = false,
              diagnostics = false,
              bookmarks = false,
            },
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
    end,
  },
}
