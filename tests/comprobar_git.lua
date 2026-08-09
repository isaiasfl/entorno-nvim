local git = require("config.git")

assert(vim.fn.executable("lazygit") == 1, "lazygit no esta disponible")

local mapping = vim.fn.maparg("<leader>gg", "n", false, true)
assert(mapping.desc == "Abrir lazygit", "leader+gg no tiene la descripcion esperada")
assert(type(mapping.callback) == "function", "leader+gg no abre lazygit mediante un callback")

local lazy_config = require("lazy.core.config")
for name in pairs(lazy_config.plugins) do
  assert(not name:lower():find("git", 1, true), "no debe instalarse un plugin Git: " .. name)
end

local previous_window = vim.api.nvim_get_current_win()
git.open({ "lazygit", "--version" })
assert(vim.bo.filetype == "lazygit", "lazygit no se abrio en un buffer terminal")
assert(vim.bo.buftype == "terminal", "lazygit no usa el terminal nativo")
assert(vim.fn.wait(5000, function()
  return vim.api.nvim_get_current_win() == previous_window
end, 20) == 0, "el terminal de lazygit no devolvio el foco a Neovim")
