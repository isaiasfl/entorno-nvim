return {
  {
    "nvim-treesitter/nvim-treesitter",
    commit = "4916d6592ede8c07973490d9322f187e07dfefac",
    lazy = false,
    opts = {
      install_dir = vim.fs.joinpath(require("config.paths").data(), "site"),
    },
  },
}
