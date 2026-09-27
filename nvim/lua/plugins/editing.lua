return {
  {
    "nvim-mini/mini.nvim",
    commit = "a995fe9cd4193fb492b5df69175a351a74b3d36b",
    event = "VeryLazy",
    config = function()
      require("mini.pairs").setup({
        modes = {
          insert = true,
          command = false,
          terminal = false,
        },
      })

      require("config.snippets").setup()

      local clue = require("mini.clue")
      clue.setup({
        window = { delay = 500 },
        triggers = {
          { mode = "n", keys = "<Leader>" },
          { mode = "x", keys = "<Leader>" },
          { mode = "n", keys = "[" },
          { mode = "n", keys = "]" },
          { mode = "n", keys = "g" },
          { mode = "x", keys = "g" },
          { mode = "i", keys = "<C-x>" },
          { mode = "n", keys = "<C-w>" },
          { mode = "n", keys = '"' },
          { mode = "n", keys = "'" },
          { mode = "n", keys = "z" },
        },
        clues = {
          clue.gen_clues.builtin_completion(),
          clue.gen_clues.g(),
          clue.gen_clues.square_brackets(),
          clue.gen_clues.windows(),
          clue.gen_clues.z(),
          { mode = "n", keys = "<Leader>f", desc = "+Busqueda" },
          { mode = "n", keys = "<Leader>g", desc = "+Git" },
          { mode = "n", keys = "<Leader>l", desc = "+Código y errores" },
          { mode = "n", keys = "<Leader>m", desc = "+Markdown" },
          { mode = "n", keys = "<Leader>u", desc = "+Aspecto y opciones" },
        },
      })
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    commit = "88c1453db4ba7dd24131086fe51fdf74e587d275",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      opts = {
        enable_close = false,
        enable_rename = false,
        enable_close_on_slash = false,
      },
      per_filetype = {
        html = { enable_close = true, enable_rename = true },
        javascriptreact = { enable_close = true, enable_rename = true },
        typescriptreact = { enable_close = true, enable_rename = true },
      },
    },
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
    end,
  },
}
