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
}
