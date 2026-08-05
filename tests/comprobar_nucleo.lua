local root = vim.env.ENTORNO_NVIM_ROOT

local function mapping(mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true)
end

assert(vim.fn.stdpath("config") == root .. "/nvim", "configuracion XDG incorrecta")
assert(package.loaded["config.options"], "config.options no se cargo")
assert(package.loaded["config.keymaps"], "config.keymaps no se cargo")
assert(package.loaded["config.autocmds"], "config.autocmds no se cargo")

assert(vim.wo.number and vim.wo.relativenumber, "numeracion de lineas incorrecta")
assert(vim.wo.cursorline, "cursorline debe estar activo")
assert(vim.wo.signcolumn == "yes", "signcolumn debe estar siempre visible")
assert(vim.wo.scrolloff == 5, "scrolloff incorrecto")
assert(vim.o.ignorecase and vim.o.smartcase, "busqueda sensible a mayusculas incorrecta")
assert(vim.o.splitbelow and vim.o.splitright, "direccion de splits incorrecta")
assert(vim.o.mouse == "a", "mouse debe estar activo")
assert(vim.o.confirm, "confirm debe estar activo")
assert(vim.o.termguicolors, "termguicolors debe estar activo")

assert(mapping("n", " w").rhs:lower():find("write", 1, true), "leader+w incorrecto")
assert(mapping("n", " q").rhs:lower():find("quit", 1, true), "leader+q incorrecto")
assert(not vim.tbl_isempty(mapping("n", "<C-h>")), "Ctrl+h no esta mapeado")
assert(not vim.tbl_isempty(mapping("n", "<C-j>")), "Ctrl+j no esta mapeado")
assert(not vim.tbl_isempty(mapping("n", "<C-k>")), "Ctrl+k no esta mapeado")
assert(not vim.tbl_isempty(mapping("n", "<C-l>")), "Ctrl+l no esta mapeado")
assert(mapping("n", "n").rhs == "nzzzv", "n no centra resultados")
assert(mapping("n", "N").rhs == "Nzzzv", "N no centra resultados")

local jk = mapping("i", "jk")
assert(jk.rhs == "<Esc>", "jk no equivale a Esc")
assert(jk.silent == 1, "jk no es silencioso")
assert(jk.desc == "Salir del modo insertar", "descripcion de jk incorrecta")
assert(vim.tbl_isempty(mapping("i", "kj")), "kj no debe estar mapeado")
assert(vim.tbl_isempty(mapping("i", "<Esc>")), "Esc no debe estar remapeado en insertar")
assert(vim.tbl_isempty(mapping("n", "<Esc>")), "Esc no debe estar remapeado en normal")

assert(vim.tbl_isempty(mapping("n", "j")), "j no debe estar remapeado")
assert(vim.tbl_isempty(mapping("n", "k")), "k no debe estar remapeado")
assert(vim.tbl_isempty(mapping("x", "j")), "j visual no debe estar remapeado")
assert(vim.tbl_isempty(mapping("x", "k")), "k visual no debe estar remapeado")

local clear_search = mapping("n", " h")
assert(clear_search.rhs:lower():find("nohlsearch", 1, true), "leader+h no limpia la busqueda")

local toggle_list = mapping("n", " ul")
assert(toggle_list.desc == "Alternar caracteres invisibles", "leader+ul no esta configurado")
assert(type(toggle_list.callback) == "function", "leader+ul no tiene callback")
assert(not vim.wo.list, "list debe estar desactivado por defecto")
toggle_list.callback()
assert(vim.wo.list, "leader+ul no activa list")
toggle_list.callback()
assert(not vim.wo.list, "leader+ul no desactiva list")

local listchars = vim.opt.listchars:get()
assert(listchars.tab == "> ", "listchars.tab incorrecto")
assert(listchars.trail == "-", "listchars.trail incorrecto")
assert(listchars.extends == ">", "listchars.extends incorrecto")
assert(listchars.precedes == "<", "listchars.precedes incorrecto")
assert(listchars.nbsp == "+", "listchars.nbsp incorrecto")

local state_root = root .. "/.xdg/state/nvim"
assert(vim.o.undodir:find(state_root .. "/undo", 1, true) == 1, "undodir no esta aislado")
assert(vim.o.directory:find(state_root .. "/swap", 1, true) == 1, "swap no esta aislado")

vim.cmd("enew")
vim.cmd("setfiletype python")
assert(vim.bo.expandtab, "Python debe usar espacios")
assert(vim.bo.shiftwidth == 4, "Python debe usar shiftwidth=4")
assert(vim.bo.softtabstop == 4, "Python debe usar softtabstop=4")
assert(vim.bo.tabstop == 4, "Python debe usar tabstop=4")

local editorconfig_fixture = root .. "/tests/fixtures/editorconfig/ejemplo.py"
vim.cmd("edit " .. vim.fn.fnameescape(editorconfig_fixture))
assert(vim.bo.expandtab, "EditorConfig debe conservar espacios")
assert(vim.bo.shiftwidth == 3, "EditorConfig debe prevalecer en shiftwidth")
assert(vim.bo.softtabstop == -1 or vim.bo.softtabstop == 3, "EditorConfig debe prevalecer en softtabstop")
assert(vim.bo.tabstop == 3, "EditorConfig debe prevalecer en tabstop")

vim.cmd("enew")
vim.cmd("setfiletype markdown")
assert(vim.wo.wrap, "Markdown debe activar wrap")
assert(vim.wo.linebreak, "Markdown debe activar linebreak")

for _, filetype in ipairs({ "gitcommit", "text" }) do
  vim.cmd("enew")
  vim.cmd("setfiletype " .. filetype)
  assert(vim.wo.wrap, filetype .. " debe activar wrap")
  assert(vim.wo.linebreak, filetype .. " debe activar linebreak")
end

for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimResized" })) do
  assert(autocmd.group_name ~= "entorno_nvim_equalize_splits", "VimResized no debe igualar splits")
end
