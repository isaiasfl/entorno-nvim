local lazy_config = require("lazy.core.config")
local plugin = lazy_config.plugins["mini.nvim"]
local root = vim.fn.fnamemodify(vim.env.MYVIMRC, ":h:h")
local lockfile = vim.json.decode(table.concat(vim.fn.readfile(root .. "/nvim/lazy-lock.json"), "\n"))

assert(plugin, "mini.nvim no esta registrado")
assert(plugin.commit == "a995fe9cd4193fb492b5df69175a351a74b3d36b", "commit de mini.nvim incorrecto")
assert(lockfile["mini.nvim"].commit == plugin.commit, "lazy-lock.json no fija el commit configurado")
assert(plugin.event == "InsertEnter", "mini.pairs debe cargarse al entrar en insertar")
assert(plugin.dependencies == nil, "mini.nvim no debe introducir dependencias")
assert(plugin.build == nil, "mini.nvim no debe ejecutar builds")

require("lazy").load({ plugins = { "mini.nvim" } })
assert(package.loaded["mini.pairs"], "mini.pairs no se pudo cargar")

for name in pairs(package.loaded) do
  if name:match("^mini%.") then
    assert(name == "mini.pairs", "se cargo un modulo mini no solicitado: " .. name)
  end
end

local expected = {
  ["("] = "()",
  ["["] = "[]",
  ["{"] = "{}",
  ['"'] = '""',
  ["'"] = "''",
  ["`"] = "``",
}

for opening, pair in pairs(expected) do
  local bufnr = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(bufnr)
  local keys = vim.api.nvim_replace_termcodes("i" .. opening .. "<Esc>", true, false, true)
  vim.fn.feedkeys(keys, "xt")
  assert(vim.api.nvim_get_current_line() == pair, opening .. " no inserto " .. pair)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

assert(vim.diagnostic.config().update_in_insert == false, "los diagnosticos no deben cambiar mientras se escribe")
