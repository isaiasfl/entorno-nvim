if vim.fn.has("nvim-0.12") ~= 1 then
  error("Esta configuracion requiere Neovim 0.12 o posterior")
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- nvim-tree es el unico explorador de directorios de esta configuracion.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
