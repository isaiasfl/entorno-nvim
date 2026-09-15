if vim.fn.has("nvim-0.12") ~= 1 then
  error("Esta configuracion requiere Neovim 0.12 o posterior")
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.profile").setup()
require("config.paths").setup_tool_path()
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
if not require("config.lazy").available then
  require("config.navigation").setup()
end
require("config.theme").setup()
require("config.lsp").setup()
require("config.completion").setup()
if require("config.profile").has("pdf") then
  require("config.markdown_pdf").setup()
end
require("config.dashboard").setup()
