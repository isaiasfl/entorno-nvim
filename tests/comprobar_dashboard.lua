local dashboard = require("config.dashboard")

assert(package.loaded["config.dashboard"], "config.dashboard no se cargo")
assert(vim.fn.exists(":IFL") == 2, "falta el comando IFL")

local resize_events = {}
for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ group = "entorno_nvim_dashboard" })) do
  resize_events[autocmd.event] = true
end
assert(resize_events.VimResized, "el dashboard no atiende VimResized")
assert(resize_events.WinResized, "el dashboard no atiende WinResized")
assert(resize_events.WinClosed, "el dashboard no limpia el estado de ventanas cerradas")

local lazy_config = require("lazy.core.config")
for name in pairs(lazy_config.plugins) do
  local lower = name:lower()
  assert(not lower:find("dashboard", 1, true), "no debe instalarse un plugin dashboard: " .. name)
  assert(not lower:find("alpha", 1, true), "no debe instalarse alpha-nvim: " .. name)
  assert(not lower:find("starter", 1, true), "no debe instalarse un plugin starter: " .. name)
end

vim.o.columns = 120
vim.o.lines = 40
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
for _, expected in ipairs({
  "███╗   ███████████╗   ███╗",
  "Neovim de Isaías",
  "Buscar archivos",
  "Explorador",
  "Buffers",
  "Archivos recientes",
  "Lazygit",
  "Volver al inicio: :IFL",
  "Ayuda y atajos",
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
  ["?"] = "IFL: ayuda y atajos",
}) do
  assert(mappings[key], "falta la acción " .. key)
  assert(mappings[key].desc == description, "descripción incorrecta para " .. key)
end

for group, link in pairs({
  IFLDescription = "Normal",
}) do
  assert(vim.api.nvim_get_hl(0, { name = group, link = true }).link == link, group .. " no enlaza con " .. link)
end

local before_edit_keys = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
vim.v.errmsg = ""
for _, key in ipairs({ "i", "a", "o", "x", "d", "p", "u", "R" }) do
  vim.api.nvim_feedkeys(key, "xt", false)
end
assert(vim.v.errmsg == "", "las teclas de edición provocan un error: " .. vim.v.errmsg)
assert(vim.deep_equal(before_edit_keys, vim.api.nvim_buf_get_lines(buffer, 0, -1, false)), "el menú se modificó")
assert(not vim.bo[buffer].modifiable, "la bienvenida debe seguir siendo de solo lectura")
local secondary = vim.api.nvim_get_hl(0, { name = "IFLSecondary", link = false })
assert(secondary.fg == 0xa5b8ad and not secondary.italic, "el pie no usa el contraste previsto")

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
  for _, key in ipairs({ "f", "g", "e", "b", "r", "l", "n", "c", "q" }) do
    for _, line in ipairs(rendered) do
      local key_start = line:find("[" .. key .. "]", 1, true)
      if key_start then
        local column = vim.fn.strdisplaywidth(line:sub(1, key_start - 1))
        key_column = key_column or column
        assert(column == key_column, "las teclas del menú no comparten columna a ancho " .. window_width)
        break
      end
    end
  end

  assert(key_column, "faltan teclas visibles")
  assert(#rendered <= vim.api.nvim_win_get_height(0), "el menú excede la altura disponible")
  for _, line in ipairs(rendered) do
    assert(vim.fn.strdisplaywidth(line) <= window_width, "una línea excede el ancho " .. window_width)
  end
end

vim.cmd("vertical resize 46")
vim.api.nvim_exec_autocmds("WinResized", {})
local resized_width = vim.api.nvim_win_get_width(0)
local resized_lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
for _, line in ipairs(resized_lines) do
  assert(vim.fn.strdisplaywidth(line) <= resized_width, "WinResized dejó una línea fuera de la ventana")
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
