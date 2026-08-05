return {
  {
    "ibhagwan/fzf-lua",
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
    opts = {
      defaults = {
        file_icons = false,
        git_icons = false,
      },
      files = {
        cmd = "rg --files --hidden -g '!.git'",
      },
    },
  },
}
