return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
    opts = {
      -- Tree-sitter, semantic tokens y diagnosticos forman parte del nucleo
      -- de highlights de Catppuccin actual; fzf y nvim-tree si son toggles.
      flavour = "mocha",
      background = {
        dark = "mocha",
        light = "latte",
      },
      default_integrations = false,
      integrations = {
        fzf = true,
        nvimtree = true,
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = {
      style = "night",
    },
  },
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {
      theme = "wave",
      overrides = function()
        return {
          FzfLuaNormal = { link = "NormalFloat" },
          FzfLuaBorder = { link = "FloatBorder" },
        }
      end,
    },
  },
  { "ellisonleao/gruvbox.nvim", lazy = true, opts = {} },
  { "rose-pine/neovim", name = "rose-pine", lazy = true, opts = {} },
  { "neanias/everforest-nvim", main = "everforest", lazy = true, opts = { background = "hard" } },
  { "EdenEast/nightfox.nvim", lazy = true, opts = {} },
  { "projekt0n/github-nvim-theme", main = "github-theme", lazy = true, opts = {} },
  { "navarasu/onedark.nvim", lazy = true, opts = {} },
  { "Mofiqul/vscode.nvim", lazy = true, opts = { style = "dark" } },
}
