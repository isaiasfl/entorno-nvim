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
}
