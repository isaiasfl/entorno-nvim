return {
  {
    "ibhagwan/fzf-lua",
    event = "VeryLazy",
    cmd = "FzfLua",
    keys = {
      {
        "<leader>ff",
        function()
          require("fzf-lua").files()
        end,
        desc = "Buscar archivos",
      },
      {
        "<leader>fg",
        function()
          require("fzf-lua").live_grep()
        end,
        desc = "Buscar texto en el proyecto",
      },
      {
        "<leader>fb",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "Ver buffers abiertos",
      },
      {
        "<leader>fd",
        function()
          require("fzf-lua").diagnostics_workspace()
        end,
        desc = "Errores de todo el proyecto",
      },
      {
        "<leader>fr",
        function()
          require("fzf-lua").oldfiles()
        end,
        desc = "Archivos recientes",
      },
      {
        "<leader>fw",
        function()
          require("fzf-lua").grep_cword()
        end,
        desc = "Buscar la palabra del cursor en el proyecto",
      },
      {
        "<leader>f.",
        function()
          require("fzf-lua").resume()
        end,
        desc = "Repetir la última búsqueda",
      },
    },
    opts = function()
      local actions = require("fzf-lua.actions")

      return {
        ui_select = {},
        defaults = {
          file_icons = false,
          git_icons = false,
        },
        keymap = {
          fzf = {
            true,
            ["ctrl-j"] = "down",
            ["ctrl-k"] = "up",
            ["down"] = "down",
            ["up"] = "up",
            ["esc"] = "abort",
          },
        },
        actions = {
          files = {
            true,
            ["enter"] = actions.file_edit_or_qf,
          },
        },
        files = {
          cmd = "rg --files --hidden"
            .. " -g '!**/.git/**'"
            .. " -g '!**/node_modules/**'"
            .. " -g '!**/.next/**'"
            .. " -g '!**/dist/**'"
            .. " -g '!**/build/**'"
            .. " -g '!**/coverage/**'"
            .. " -g '!**/.cache/**'",
        },
        previewers = {
          builtin = {
            extensions = {
              avif = { "chafa", "{file}" },
              gif = { "chafa", "{file}" },
              jpeg = { "chafa", "{file}" },
              jpg = { "chafa", "{file}" },
              png = { "chafa", "{file}" },
              svg = { "chafa", "{file}" },
              webp = { "chafa", "{file}" },
            },
          },
        },
      }
    end,
  },
}
