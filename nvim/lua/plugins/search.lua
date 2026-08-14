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
          cmd = "rg --files --hidden -g '!.git'",
        },
      }
    end,
  },
}
