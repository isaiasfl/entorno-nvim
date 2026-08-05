if vim.fn.has("nvim-0.11") ~= 1 then
  error("Esta configuracion requiere Neovim 0.11 o posterior")
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
