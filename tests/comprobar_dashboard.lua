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
assert(vim.wo.fillchars:find("eob: ", 1, true), "el dashboard debe ocultar las marcas de fin de buffer")
assert(vim.wo.statusline == " ", "el dashboard debe dejar limpia la línea de estado")

local text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), "\n")
local version = vim.version()
for _, expected in ipairs({
  "██╗  ███████╗  ██╗",
  "Neovim de Isaías",
  string.format("v%d.%d.%d", version.major, version.minor, version.patch),
  "Buscar archivos",
  "Explorador",
  "Buffers",
  "Archivos recientes",
  "Lazygit",
  ":IFL para volver",
}) do
  assert(text:find(expected, 1, true), "falta contenido del dashboard: " .. expected)
end

local mappings = {}
for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buffer, "n")) do
  mappings[mapping.lhs] = mapping
end

for key, description in pairs({
  f = "IFL: buscar archivos",
  g = "IFL: buscar texto",
  e = "IFL: explorador",
  b = "IFL: buffers",
  r = "IFL: archivos recientes",
  l = "IFL: lazygit",
  n = "IFL: nuevo archivo",
  c = "IFL: abrir configuración",
  q = "IFL: salir",
}) do
  assert(mappings[key], "falta la acción " .. key)
  assert(mappings[key].desc == description, "descripción incorrecta para " .. key)
end

for group, link in pairs({
  IFLLogo = "Title",
  IFLSubtitle = "Special",
  IFLKey = "Keyword",
  IFLDescription = "Normal",
  IFLSecondary = "Comment",
}) do
  assert(vim.api.nvim_get_hl(0, { name = group, link = true }).link == link, group .. " no enlaza con " .. link)
end

local sizes = {
  { columns = 52, lines = 24 },
  { columns = 80, lines = 24 },
  { columns = 140, lines = 40 },
}
for _, size in ipairs(sizes) do
  vim.o.columns = size.columns
  vim.o.lines = size.lines
  vim.api.nvim_exec_autocmds("VimResized", {})

  local window_width = vim.api.nvim_win_get_width(0)
  local rendered = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local key_column
  local description_column
  for _, key in ipairs({ "f", "g", "e", "b", "r", "l", "n", "c", "q" }) do
    for _, line in ipairs(rendered) do
      local key_start = line:find("[" .. key .. "]", 1, true)
      if key_start then
        local current_description = key_start + 5
        key_column = key_column or key_start
        description_column = description_column or current_description
        assert(key_start == key_column, "las teclas del menú no comparten columna a ancho " .. window_width)
        assert(current_description == description_column, "las descripciones no comparten columna")
        break
      end
    end
  end

  local longest = "[r]  Archivos recientes"
  local expected_column = math.max(1, math.floor((window_width - vim.fn.strdisplaywidth(longest)) / 2) + 1)
  assert(key_column == expected_column, "el menú no está centrado a ancho " .. window_width)
  for _, line in ipairs(rendered) do
    assert(vim.fn.strdisplaywidth(line) <= window_width, "una línea excede el ancho " .. window_width)
  end
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
