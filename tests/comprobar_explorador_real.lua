assert(require("config.lazy").available, "Faltan plugins: no aceptar Netrw como sustituto")
require("config.dashboard").open()
local function press(keys)
  vim.api.nvim_feedkeys(keys, "xt", false)
end
for _, keys in ipairs({ " e", " ee", "e" }) do
  require("config.dashboard").open()
  local windows = #vim.api.nvim_list_wins()
  press(keys)
  assert(vim.bo.filetype == "NvimTree", "No se abrio NvimTree con " .. keys)
  assert(#vim.api.nvim_list_wins() == windows + 1, "No hay panel lateral")
  assert(vim.api.nvim_win_get_width(0) < vim.o.columns, "El arbol ocupa toda la pantalla")
  press(" e")
  assert(not require("nvim-tree.api").tree.is_visible(), "Space e no cierra el arbol")
  assert(#vim.api.nvim_list_wins() == windows, "No se recupero el editor")
end
-- La version fijada limpia FileExplorer con silent! aunque netrw este
-- deshabilitado. Ese E216 benigno queda en errmsg; no aceptar otros errores.
assert(vim.v.errmsg == "" or vim.v.errmsg == "E216: No such group or event: FileExplorer *", vim.v.errmsg)
print("NvimTree real: panel lateral y abrir/cerrar con Space e correctos")
