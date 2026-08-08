return {
  {
    "nvim-mini/mini.nvim",
    commit = "a995fe9cd4193fb492b5df69175a351a74b3d36b",
    event = "InsertEnter",
    config = function()
      require("mini.pairs").setup({
        modes = {
          insert = true,
          command = false,
          terminal = false,
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
