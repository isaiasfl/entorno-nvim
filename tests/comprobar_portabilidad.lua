local root = assert(vim.env.ENTORNO_NVIM_ROOT)
local xdg = assert(vim.env.ENTORNO_NVIM_XDG_ROOT)
local profile = require("config.profile")
assert(vim.v.errmsg == "", vim.v.errmsg)
assert(vim.fn.stdpath("config") == root .. "/nvim", "se cargo otra configuracion")
assert(vim.fn.stdpath("state") == xdg .. "/state/" .. profile.name .. "/nvim")
assert(vim.env.XDG_RUNTIME_DIR == vim.env.ENTORNO_TEST_DESKTOP_RUNTIME, "se sustituyo el runtime del escritorio")
assert(vim.v.servername:find(xdg .. "/runtime/", 1, true) == 1, "socket fuera del entorno")
assert(not require("config.lazy").available, "la prueba debe partir sin plugins")
assert(package.loaded.lazy == nil, "se cargo Lazy sin preparacion")
assert(vim.fn.isdirectory(xdg .. "/data/nvim/lazy") == 0, "el arranque intento instalar plugins")
assert(profile.missing.LSP, "falta diagnostico de capacidades reducidas")
assert(vim.fn.exists(":EntornoInfo") == 2)
assert(vim.fn.exists(":MarkdownPdf") == (profile.name == "profesor" and 2 or 0))
assert((vim.fn.maparg(" ac", "n") ~= "") == (vim.env.ENTORNO_IA == "1"), "IA habilitada sin solicitud")
assert(vim.diagnostic.is_enabled() == profile.has("diagnostics"))
local desktop = require("config.process").desktop_env()
assert(desktop.XDG_CONFIG_HOME == vim.env.ENTORNO_TEST_DESKTOP_CONFIG, "visores/Git perdieron su configuracion")

-- Edicion real sin plugins, parsers externos ni servidores. Nunca abrir datos
-- personales: los archivos y el undo de esta prueba son nuevos y temporales.
for _, file in ipairs({ "prueba.html", "prueba.tsx", "prueba.sh", "prueba.py", "prueba.md" }) do
  vim.cmd.enew()
  local path = xdg .. "/" .. file
  vim.api.nvim_buf_set_name(0, path)
  vim.cmd("filetype detect")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "prueba de edicion" })
  vim.cmd("silent write")
  assert(vim.fn.filereadable(path) == 1, "no se pudo guardar " .. file)
  assert(vim.fn.undofile(path):find(xdg .. "/state/" .. profile.name .. "/", 1, true) == 1)
end

-- El dashboard debe seguir ofreciendo navegacion nativa, sin require('lazy').
require("config.dashboard").open()
vim.api.nvim_feedkeys("e", "xt", false)
assert(vim.bo.filetype == "netrw", "e desde inicio no abre el explorador: " .. vim.bo.filetype .. " " .. vim.v.errmsg)
for _, keys in ipairs({ " e", " ee" }) do
  require("config.dashboard").open()
  vim.api.nvim_feedkeys(keys, "xt", false)
  assert(vim.bo.filetype == "netrw", keys .. " desde inicio no abre el explorador")
  vim.api.nvim_feedkeys(keys, "xt", false)
  assert(vim.bo.filetype == "ifl_dashboard", keys .. " no cierra el explorador")
end
vim.cmd.edit(vim.fn.fnameescape(xdg .. "/prueba.html"))
local edited = vim.api.nvim_get_current_buf()
vim.api.nvim_feedkeys(" e", "xt", false)
assert(vim.bo.filetype == "netrw")
vim.api.nvim_feedkeys(" e", "xt", false)
assert(vim.api.nvim_get_current_buf() == edited, "el explorador no devuelve el archivo")
-- netrw puede dejar E31 al limpiar mapas inexistentes con silent!; comprobar
-- el resultado visible arriba y no atribuir ese mensaje a la apertura siguiente.
vim.v.errmsg = ""
require("config.dashboard").open()
assert(vim.bo.filetype == "ifl_dashboard")
local original_input = vim.ui.input
vim.ui.input = function(_, callback) callback(xdg .. "/prueba.html") end
require("config.navigation").pick("files")
vim.ui.input = original_input
assert(vim.api.nvim_buf_get_name(0) == xdg .. "/prueba.html")
assert(vim.v.errmsg == "", vim.v.errmsg)
print("Perfil " .. profile.name .. ": edicion, aislamiento e integraciones correctos")
