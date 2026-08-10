local dashboard = require("config.dashboard")

assert(package.loaded["config.dashboard"], "config.dashboard no se cargo")
assert(vim.fn.exists(":IFL") == 2, "falta el comando IFL")

local lazy_config = require("lazy.core.config")
for name in pairs(lazy_config.plugins) do
  local lower = name:lower()
  assert(not lower:find("dashboard", 1, true), "no debe instalarse un plugin dashboard: " .. name)
  assert(not lower:find("alpha", 1, true), "no debe instalarse alpha-nvim: " .. name)
  assert(not lower:find("starter", 1, true), "no debe instalarse un plugin starter: " .. name)
end

dashboard.open()

local buffer = vim.api.nvim_get_current_buf()
dashboard.open()
assert(vim.api.nvim_get_current_buf() == buffer, "abrir IFL dos veces debe reutilizar el dashboard actual")
assert(vim.bo[buffer].filetype == "ifl_dashboard", "el dashboard tiene un filetype incorrecto")
assert(vim.bo[buffer].buftype == "nofile", "el dashboard debe ser un buffer nofile")
assert(not vim.bo[buffer].buflisted, "el dashboard no debe aparecer en la lista de buffers")
assert(not vim.bo[buffer].modifiable, "el dashboard debe ser de solo lectura")
assert(not vim.bo[buffer].swapfile, "el dashboard no debe crear swap")
assert(not vim.wo.number and not vim.wo.relativenumber, "el dashboard no debe mostrar números")
assert(vim.wo.signcolumn == "no", "el dashboard no debe mostrar signcolumn")

local text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
for _, expected in ipairs({ "|_ _|  ___| |", "Neovim de Isaías", "Buscar archivos", "Archivos recientes", ":IFL" }) do
  assert(text:find(expected, 1, true), "falta contenido del dashboard: " .. expected)
end

local mappings = {}
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, "n")) do
  mappings[mapping.lhs] = mapping
end

for key, description in pairs({
  f = "IFL: buscar archivos",
  g = "IFL: buscar texto",
  r = "IFL: archivos recientes",
  n = "IFL: nuevo archivo",
  c = "IFL: abrir configuración",
  q = "IFL: salir",
}) do
  assert(mappings[key], "falta la acción " .. key)
  assert(mappings[key].desc == description, "descripción incorrecta para " .. key)
end

vim.cmd.enew()
assert(vim.wo.number and vim.wo.relativenumber, "al salir del dashboard deben restaurarse los números")

local modified_buffer = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(modified_buffer, 0, -1, false, { "cambio sin guardar" })
vim.bo[modified_buffer].modified = true
local opened, open_error = pcall(dashboard.open)
assert(opened, "IFL no debe fallar al ocultar un buffer modificado: " .. tostring(open_error))
assert(vim.bo[modified_buffer].modified, "IFL no debe descartar cambios sin guardar")
vim.api.nvim_win_set_buf(0, modified_buffer)
vim.bo[modified_buffer].modified = false
