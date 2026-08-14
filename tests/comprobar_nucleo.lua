local root = vim.env.ENTORNO_NVIM_ROOT
local xdg_root = vim.env.ENTORNO_NVIM_XDG_ROOT
local paths = require("config.paths")

assert(paths.repository() == root, "la raiz aislada del repositorio es incorrecta")
assert(paths.data() == vim.fn.stdpath("data"), "los datos aislados no deben cambiar de ubicacion")
assert(vim.fn.exepath("tree-sitter") == paths.tree_sitter_bin(), "Neovim no prioriza el tree-sitter-cli fijado")

assert(type(xdg_root) == "string" and xdg_root ~= "", "falta la raiz XDG de prueba")

if vim.env.ENTORNO_NVIM_EXPECTED_VERSION and vim.env.ENTORNO_NVIM_EXPECTED_VERSION ~= "" then
  local version = vim.version()
  local actual = string.format("%d.%d.%d", version.major, version.minor, version.patch)
  assert(actual == vim.env.ENTORNO_NVIM_EXPECTED_VERSION, "version inesperada de Neovim: " .. actual)
end

local function mapping(mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true)
end

assert(vim.fn.stdpath("config") == root .. "/nvim", "configuracion XDG incorrecta")
assert(vim.fn.stdpath("run") == xdg_root .. "/runtime", "runtime XDG incorrecto")
assert(vim.fn.getfperm(vim.fn.stdpath("run")) == "rwx------", "runtime XDG requiere permisos 0700")
assert(package.loaded["config.options"], "config.options no se cargo")
assert(package.loaded["config.keymaps"], "config.keymaps no se cargo")
assert(package.loaded["config.autocmds"], "config.autocmds no se cargo")
assert(package.loaded["config.lazy"], "config.lazy no se cargo")
assert(package.loaded["config.theme"], "config.theme no se cargo")
assert(package.loaded["config.lsp"], "config.lsp no se cargo")
assert(package.loaded["config.completion"], "config.completion no se cargo")
assert(package.loaded["config.markdown_pdf"], "config.markdown_pdf no se cargo")
assert(package.loaded["config.dashboard"], "config.dashboard no se cargo")
assert(vim.fn.exists(":IFL") == 2, "falta el comando IFL")
assert(vim.g.loaded_netrw == 1, "netrw debe estar desactivado")
assert(vim.g.loaded_netrwPlugin == 1, "el plugin de netrw debe estar desactivado")

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
assert(mapping("n", "<C-h>").rhs == "<C-w>h", "Ctrl+h no cambia a la ventana izquierda")
assert(mapping("n", "<C-j>").rhs == "<C-w>j", "Ctrl+j no cambia a la ventana inferior")
assert(mapping("n", "<C-k>").rhs == "<C-w>k", "Ctrl+k no cambia a la ventana superior")
assert(mapping("n", "<C-l>").rhs == "<C-w>l", "Ctrl+l no cambia a la ventana derecha")
assert(mapping("n", "n").rhs == "nzzzv", "n no centra resultados")
assert(mapping("n", "N").rhs == "Nzzzv", "N no centra resultados")

local markdown_pdf = mapping("n", " mp")
assert(markdown_pdf.desc == "Generar PDF del Markdown actual", "leader+mp no esta configurado")
assert(type(markdown_pdf.callback) == "function", "leader+mp no usa el exportador nativo")
assert(vim.fn.exists(":MarkdownPdf") == 2, "falta el comando MarkdownPdf")

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

local theme_picker = mapping("n", " ut")
assert(theme_picker.desc == "Seleccionar tema visual", "leader+ut no esta configurado")
assert(type(theme_picker.callback) == "function", "leader+ut no usa vim.ui.select mediante callback")

local listchars = vim.opt.listchars:get()
assert(listchars.tab == "> ", "listchars.tab incorrecto")
assert(listchars.trail == "-", "listchars.trail incorrecto")
assert(listchars.extends == ">", "listchars.extends incorrecto")
assert(listchars.precedes == "<", "listchars.precedes incorrecto")
assert(listchars.nbsp == "+", "listchars.nbsp incorrecto")

local state_root = xdg_root .. "/state/nvim"
assert(vim.o.undofile, "undo persistente debe estar activo")
assert(vim.o.swapfile, "swap debe estar activo")
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
local markdown_buffer = vim.api.nvim_get_current_buf()
local parser_ok, markdown_parser = pcall(vim.treesitter.get_parser, markdown_buffer, "markdown")
assert(parser_ok and markdown_parser, "parser Markdown integrado no disponible")
if vim.fn.has("nvim-0.12") == 1 then
  assert(vim.treesitter.highlighter.active[markdown_buffer], "Neovim 0.12 debe activar Treesitter para Markdown")
end

for _, filetype in ipairs({ "gitcommit", "text" }) do
  vim.cmd("enew")
  vim.cmd("setfiletype " .. filetype)
  assert(vim.wo.wrap, filetype .. " debe activar wrap")
  assert(vim.wo.linebreak, filetype .. " debe activar linebreak")
end

for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = "VimResized" })) do
  assert(autocmd.group_name ~= "entorno_nvim_equalize_splits", "VimResized no debe igualar splits")
end

local lazy_config = require("lazy.core.config")
assert(lazy_config.plugins["fzf-lua"], "fzf-lua no esta registrado")
assert(lazy_config.plugins["catppuccin"], "catppuccin no esta registrado")
assert(lazy_config.plugins["tokyonight.nvim"], "tokyonight.nvim no esta registrado")
assert(lazy_config.plugins["kanagawa.nvim"], "kanagawa.nvim no esta registrado")
local search_spec = require("plugins.search")[1]
assert(search_spec.event == "VeryLazy", "fzf-lua debe registrarse durante VeryLazy")
assert(lazy_config.plugins["nvim-tree.lua"], "nvim-tree.lua no esta registrado")
local devicons_plugin = assert(lazy_config.plugins["nvim-web-devicons"], "nvim-web-devicons no esta registrado")
assert(devicons_plugin.commit == "2ae6958df7ced50baac5035cec0c15799eedfbf7", "nvim-web-devicons no fija la revision esperada")
assert(vim.fn.executable("fzf") == 1, "fzf no esta disponible")
assert(vim.fn.executable("rg") == 1, "ripgrep no esta disponible")

for lhs, description in pairs({
  [" ff"] = "Buscar archivos",
  [" fg"] = "Buscar texto en el proyecto",
  [" fb"] = "Ver buffers abiertos",
}) do
  local picker = mapping("n", lhs)
  assert(picker.desc == description, lhs .. " no tiene la descripcion esperada")
  assert(type(picker.callback) == "function", lhs .. " no carga fzf-lua")
end

require("lazy").load({ plugins = { "fzf-lua" } })
assert(package.loaded["fzf-lua"], "fzf-lua no se pudo cargar")
local ui_select = require("fzf-lua.providers.ui_select")
assert(ui_select.is_registered(), "fzf-lua no reemplazo vim.ui.select")
assert(vim.ui.select == ui_select.ui_select, "vim.ui.select no usa el selector de fzf-lua")
assert(type(vim.g.fzf_lua_server) == "string", "fzf-lua no inicio su servidor local")
assert(vim.g.fzf_lua_server:find(vim.fn.stdpath("run"), 1, true) == 1, "servidor fzf-lua fuera del runtime XDG")

local config = require("fzf-lua.config")
local fzf_config = config.setup_opts
local expected_files_command = "rg --files --hidden"
  .. " -g '!**/.git/**'"
  .. " -g '!**/node_modules/**'"
  .. " -g '!**/.next/**'"
  .. " -g '!**/dist/**'"
  .. " -g '!**/build/**'"
  .. " -g '!**/coverage/**'"
  .. " -g '!**/.cache/**'"
assert(fzf_config.files.cmd == expected_files_command, "comando de archivos fzf-lua incorrecto")
assert(fzf_config.defaults.file_icons == false, "los iconos de archivo deben estar desactivados")
assert(fzf_config.defaults.git_icons == false, "los iconos de Git deben estar desactivados")

local image_extensions = assert(fzf_config.previewers.builtin.extensions, "falta la previsualizacion de imagenes")
for _, extension in ipairs({ "avif", "gif", "jpeg", "jpg", "png", "svg", "webp" }) do
  assert(
    vim.deep_equal(image_extensions[extension], { "chafa", "{file}" }),
    "previsualizador incorrecto para ." .. extension
  )
end

local expected_keymaps = {
  ["ctrl-j"] = "down",
  ["ctrl-k"] = "up",
  ["down"] = "down",
  ["up"] = "up",
  ["esc"] = "abort",
}
local expected_binds = { "ctrl-j:down", "ctrl-k:up", "down:down", "up:up", "esc:abort" }
local actions = require("fzf-lua.actions")
local core = require("fzf-lua.core")

assert(fzf_config.actions.files.enter == actions.file_edit_or_qf, "Enter no declara la accion de apertura")

for _, provider in ipairs({ "files", "grep", "buffers" }) do
  local opts = config.normalize_opts({}, provider)
  for key, action in pairs(expected_keymaps) do
    assert(opts.keymap.fzf[key] == action, provider .. ": " .. key .. " no ejecuta " .. action)
  end

  local fzf_binds = table.concat(core.create_fzf_binds(opts), ",")
  for _, bind in ipairs(expected_binds) do
    assert(fzf_binds:find(bind, 1, true), provider .. ": falta el enlace efectivo " .. bind)
  end

  assert(config.get_action_helpstr(opts.actions.enter) == "file-edit-or-qf", provider .. ": Enter no abre la seleccion")
  local _, action_binds = actions.expect(opts.actions, opts)
  assert(type(action_binds) == "table", provider .. ": no genero enlaces para sus acciones")
  assert(table.concat(action_binds, ","):find("enter:print(enter)+accept", 1, true), provider .. ": Enter no acepta")
end

assert(vim.tbl_isempty(mapping("t", "<C-j>")), "Ctrl+j de fzf-lua no debe ser un mapa terminal global")
assert(vim.tbl_isempty(mapping("t", "<C-k>")), "Ctrl+k de fzf-lua no debe ser un mapa terminal global")

for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  assert(vim.bo[bufnr].filetype ~= "NvimTree", "nvim-tree no debe abrirse automaticamente")
end

for lhs, description in pairs({
  [" ee"] = "Abrir o cerrar el arbol de archivos",
  [" ef"] = "Enfocar el archivo actual en el arbol",
}) do
  local tree_mapping = mapping("n", lhs)
  assert(tree_mapping.desc == description, lhs .. " no tiene la descripcion esperada")
  assert(type(tree_mapping.callback) == "function", lhs .. " no carga nvim-tree")
end

require("lazy").load({ plugins = { "nvim-tree.lua" } })
local explorer_spec = require("plugins.explorer")[1]
local tree_actions = {}
for _, key in ipairs(explorer_spec.keys) do
  tree_actions[key[1]] = key[2]
end

local revealed_file = root .. "/README.md"
vim.cmd("edit " .. vim.fn.fnameescape(revealed_file))
tree_actions["<leader>ef"]()
assert(package.loaded["nvim-tree"], "nvim-tree no se pudo cargar")
assert(vim.bo.filetype == "NvimTree", "leader+ef no enfoco el arbol")

local tree_api = require("nvim-tree.api")
local revealed_node = tree_api.tree.get_node_under_cursor()
assert(revealed_node and revealed_node.absolute_path == revealed_file, "leader+ef no revelo el archivo actual")
tree_api.tree.close()

local tree_config = require("nvim-tree.config").g
assert(tree_config.disable_netrw, "nvim-tree debe desactivar netrw")
assert(not tree_config.hijack_directories.enable, "nvim-tree no debe capturar directorios al abrirlos")
assert(not tree_config.hijack_directories.auto_open, "nvim-tree no debe abrirse con directorios")
assert(not tree_config.update_focused_file.enable, "nvim-tree no debe seguir el buffer enfocado")
assert(not tree_config.update_focused_file.update_root.enable, "nvim-tree no debe cambiar su raiz automaticamente")
assert(not tree_config.git.enable, "la integracion Git de nvim-tree debe estar desactivada")
assert(not tree_config.diagnostics.enable, "los diagnosticos de nvim-tree deben estar desactivados")
assert(not tree_config.modified.enable, "los indicadores de modificacion deben estar desactivados")
assert(not tree_config.filters.enable, "nvim-tree no debe aplicar filtros")
assert(vim.tbl_isempty(tree_config.renderer.decorators), "nvim-tree no debe usar decoradores")
for _, name in ipairs({ "file", "folder", "folder_arrow" }) do
  assert(tree_config.renderer.icons.show[name], "el icono " .. name .. " debe estar activado")
end
for _, name in ipairs({ "git", "modified", "hidden", "diagnostics", "bookmarks" }) do
  assert(not tree_config.renderer.icons.show[name], "el icono " .. name .. " debe estar desactivado")
end
assert(tree_config.renderer.icons.web_devicons.file.enable, "nvim-tree no usa devicons para archivos")
assert(tree_config.renderer.icons.web_devicons.file.color, "los iconos de archivo no conservan sus colores")
assert(not tree_config.renderer.icons.web_devicons.folder.enable, "las carpetas deben usar los iconos sobrios de nvim-tree")
assert(tree_config.renderer.highlight_git == "none", "Git no debe colorear nombres completos")
assert(tree_config.renderer.highlight_opened_files == "none", "los archivos abiertos no deben colorear el nombre completo")

local devicons = require("nvim-web-devicons")
for _, filename in ipairs({
  "init.lua",
  "app.js",
  "types.ts",
  "component.tsx",
  "main.py",
  "README.md",
  "data.json",
  "index.html",
  "style.css",
  ".gitignore",
  "script.sh",
}) do
  local icon, highlight = devicons.get_icon(filename, nil, { default = true })
  assert(type(icon) == "string" and icon ~= "", "falta icono para " .. filename)
  assert(type(highlight) == "string" and highlight:match("^DevIcon"), "falta color de icono para " .. filename)
end
local plain_icon, plain_highlight = devicons.get_icon("LICENSE", nil, { default = true })
assert(type(plain_icon) == "string" and plain_icon ~= "", "falta fallback para archivos sin extension")
assert(type(plain_highlight) == "string", "el fallback sin extension no tiene highlight")

-- El wrapper de nvim-tree debe degradar a su glifo generico si require falla.
local loaded_devicons = package.loaded["nvim-web-devicons"]
local loaded_component = package.loaded["nvim-tree.renderer.components.devicons"]
local preload_devicons = package.preload["nvim-web-devicons"]
package.loaded["nvim-web-devicons"] = nil
package.loaded["nvim-tree.renderer.components.devicons"] = nil
package.preload["nvim-web-devicons"] = function()
  error("fallo simulado de devicons")
end
local fallback_component = require("nvim-tree.renderer.components.devicons")
local fallback_ok, fallback_icon = pcall(fallback_component.get_icon, "init.lua", "lua", { default = true })
assert(fallback_ok and fallback_icon == nil, "nvim-tree no degrada limpiamente sin devicons")
package.preload["nvim-web-devicons"] = preload_devicons
package.loaded["nvim-web-devicons"] = loaded_devicons
package.loaded["nvim-tree.renderer.components.devicons"] = loaded_component
assert(tree_config.ui.confirm.remove, "borrar debe pedir confirmacion")
assert(tree_config.ui.confirm.trash, "enviar a la papelera debe pedir confirmacion")
assert(not tree_config.ui.confirm.default_yes, "la confirmacion no debe aceptar por defecto")

tree_actions["<leader>ee"]()
assert(vim.bo.filetype == "NvimTree", "nvim-tree no abrio su buffer")

for lhs, rhs in pairs({
  ["<C-h>"] = "<C-w>h",
  ["<C-j>"] = "<C-w>j",
  ["<C-k>"] = "<C-w>k",
  ["<C-l>"] = "<C-w>l",
}) do
  local tree_window_mapping = mapping("n", lhs)
  assert(tree_window_mapping.rhs == rhs, lhs .. " no cambia de ventana dentro de nvim-tree")
  assert(tree_window_mapping.buffer == 1, lhs .. " debe ser local al buffer de nvim-tree")
end

for lhs, description in pairs({
  ["<CR>"] = "nvim-tree: Open",
  ["g?"] = "nvim-tree: Help",
  ["a"] = "nvim-tree: Create File Or Directory",
  ["r"] = "nvim-tree: Rename",
  ["d"] = "nvim-tree: Delete",
}) do
  local tree_action = mapping("n", lhs)
  assert(type(tree_action.callback) == "function", lhs .. " no tiene una accion en nvim-tree")
  assert(tree_action.desc == description, lhs .. " no tiene la descripcion efectiva esperada")
  assert(tree_action.buffer == 1, lhs .. " debe ser local al buffer de nvim-tree")
end

tree_actions["<leader>ee"]()
for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  assert(vim.bo[bufnr].filetype ~= "NvimTree" or not vim.api.nvim_buf_is_loaded(bufnr), "leader+ee no cerro nvim-tree")
end
assert(mapping("n", "<C-j>").rhs == "<C-w>j", "Ctrl+j global cambio fuera de nvim-tree")
assert(mapping("n", "<C-k>").rhs == "<C-w>k", "Ctrl+k global cambio fuera de nvim-tree")

local lockfile = vim.json.decode(table.concat(vim.fn.readfile(root .. "/nvim/lazy-lock.json"), "\n"))
assert(lockfile["nvim-tree.lua"], "nvim-tree.lua no esta fijado en el lockfile")
assert(lockfile["nvim-web-devicons"], "nvim-web-devicons no aparece en el lockfile")
assert(lockfile["nvim-web-devicons"].commit == devicons_plugin.commit, "lockfile y spec de devicons no coinciden")

dofile(root .. "/tests/comprobar_lsp.lua")
dofile(root .. "/tests/comprobar_lsp_lua.lua")
dofile(root .. "/tests/comprobar_lsp_python.lua")
dofile(root .. "/tests/comprobar_treesitter.lua")
dofile(root .. "/tests/comprobar_lsp_web.lua")
dofile(root .. "/tests/comprobar_tailwind.lua")
dofile(root .. "/tests/comprobar_pares.lua")
dofile(root .. "/tests/comprobar_edicion.lua")
dofile(root .. "/tests/comprobar_git.lua")
dofile(root .. "/tests/comprobar_agent_context.lua")
