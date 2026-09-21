local root = vim.env.ENTORNO_NVIM_ROOT
local lazy_config = require("lazy.core.config")

local plugin = lazy_config.plugins["nvim-lspconfig"]
assert(plugin, "nvim-lspconfig no esta registrado")
assert(plugin.commit == "f6738ef65dabade340b473d4ff2a1ad3352c10e7", "commit de nvim-lspconfig incorrecto")
assert(plugin.lazy == false, "el catalogo LSP debe estar disponible al iniciar")
assert(plugin.build == nil, "nvim-lspconfig no debe ejecutar builds")
assert(plugin.dependencies == nil, "nvim-lspconfig no debe introducir dependencias")

assert(not lazy_config.plugins["mason.nvim"], "Mason no debe estar instalado")
assert(not lazy_config.plugins["nvim-cmp"], "nvim-cmp no debe estar instalado")
assert(not lazy_config.plugins["cmp-nvim-lsp"], "cmp-nvim-lsp no debe estar instalado")

assert(package.loaded["config.lsp"], "config.lsp no se cargo")
assert(package.loaded["config.completion"], "config.completion no se cargo")
assert(package.loaded["lspconfig"] == nil, "no debe cargarse la API antigua de lspconfig")

local diagnostic_config = vim.diagnostic.config()
assert(type(diagnostic_config.virtual_text) == "table", "los mensajes de diagnostico deben ser visibles")
assert(diagnostic_config.virtual_text.prefix == "●", "el diagnostico visible usa un prefijo inesperado")
assert(diagnostic_config.underline == true, "los diagnosticos deben subrayar el problema")
assert(diagnostic_config.signs == true, "los diagnosticos deben conservar signos en el margen")
assert(diagnostic_config.update_in_insert == false, "los diagnosticos no deben cambiar mientras se escribe")

for _, name in ipairs({ "ts_ls", "html", "cssls", "jsonls", "tailwindcss", "lua_ls", "pyright", "bashls", "basedpyright" }) do
  assert(type(vim.lsp.config[name]) == "table", "falta la configuracion de catalogo " .. name)
  local should_be_enabled = vim.tbl_contains({ "ts_ls", "html", "cssls", "jsonls", "tailwindcss", "lua_ls", "pyright" }, name)
  assert(vim.lsp.is_enabled(name) == should_be_enabled, "estado de activacion incorrecto para " .. name)
end

local python_bin = vim.env.ENTORNO_NVIM_LSP_PYTHON_BIN
local pyright_config = vim.lsp.config.pyright
assert(pyright_config.cmd[1] == vim.fs.joinpath(python_bin, "pyright-langserver"), "Pyright no usa el ejecutable aislado")
assert(pyright_config.cmd[2] == "--stdio", "Pyright no usa el transporte stdio")
assert(pyright_config.settings.python.analysis.typeCheckingMode == "basic", "Pyright debe usar tipado basico")
assert(pyright_config.settings.python.analysis.diagnosticMode == "openFilesOnly", "Pyright debe analizar archivos abiertos")

local luals_bin = vim.env.ENTORNO_NVIM_LUALS_BIN
local lua_config = vim.lsp.config.lua_ls
assert(lua_config.cmd[1] == luals_bin, "lua_ls no usa el ejecutable aislado")
assert(lua_config.cmd[2]:match("^%-%-logpath="), "lua_ls no aisla sus logs")
assert(lua_config.settings.Lua.runtime.version == "LuaJIT", "lua_ls no usa el runtime LuaJIT de Neovim")
assert(vim.tbl_contains(lua_config.settings.Lua.diagnostics.globals, "vim"), "lua_ls no reconoce el global vim")
assert(
  vim.tbl_contains(lua_config.settings.Lua.workspace.library, vim.env.VIMRUNTIME),
  "lua_ls no conoce el runtime de Neovim"
)
assert(lua_config.settings.Lua.workspace.checkThirdParty == "Disable", "lua_ls no desactivo la deteccion de addons")
assert(lua_config.settings.Lua.workspace.useGitIgnore == true, "lua_ls no respeta .gitignore")

local lsp = require("config.lsp")
local web_bin = vim.env.ENTORNO_NVIM_LSP_WEB_BIN
assert(type(web_bin) == "string" and web_bin ~= "", "falta la ruta de servidores web")
for name, server in pairs(lsp.web_servers) do
  local config = vim.lsp.config[name]
  assert(config.cmd[1] == vim.fs.joinpath(web_bin, server.executable), name .. ": ejecutable incorrecto")
  assert(config.cmd[2] == "--stdio", name .. ": falta el transporte stdio")
end
for _, section in ipairs({ "html", "css", "javascript" }) do
  assert(type(vim.lsp.config.html.settings[section]) == "table", "HTML debe responder la seccion " .. section)
end

local function mapping(mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true)
end

local function global_mapping(mode, lhs)
  for _, item in ipairs(vim.api.nvim_get_keymap(mode)) do
    if item.lhs == lhs then
      return item
    end
  end

  return {}
end

for lhs, description in pairs({
  gra = "vim.lsp.buf.code_action()",
  gri = "vim.lsp.buf.implementation()",
  grn = "vim.lsp.buf.rename()",
  grr = "vim.lsp.buf.references()",
  grt = "vim.lsp.buf.type_definition()",
  grx = "vim.lsp.codelens.run()",
  gO = "vim.lsp.buf.document_symbol()",
}) do
  assert(global_mapping("n", lhs).desc == description, lhs .. " debe conservar el mapa nativo")
end
assert(global_mapping("i", "<C-S>").desc == "vim.lsp.buf.signature_help()", "Ctrl-S debe conservar el mapa nativo")

local bufnr = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(bufnr)
require("config.lsp").attach(bufnr)

for lhs, description in pairs({
  gd = "LSP: Ir a la definicion",
  gD = "LSP: Ir a la declaracion",
  [" lf"] = "LSP: Formatear buffer",
}) do
  local item = mapping("n", lhs)
  assert(item.desc == description, lhs .. " no tiene la descripcion LSP esperada")
  assert(item.buffer == 1, lhs .. " debe ser local al buffer LSP")
  assert(item.silent == 1, lhs .. " debe ser silencioso")
end

local completeopt = vim.opt.completeopt:get()
for _, value in ipairs({ "menu", "menuone", "noselect", "popup" }) do
  assert(vim.tbl_contains(completeopt, value), "completeopt no contiene " .. value)
end

local completion_map = mapping("i", "<C-Space>")
assert(completion_map.desc == "LSP: Solicitar completado", "Ctrl-Space no solicita completado LSP")
assert(type(completion_map.callback) == "function", "Ctrl-Space debe usar la API de completado nativa")

local completion = require("config.completion")
local original_completion_enable = vim.lsp.completion.enable
local received
vim.lsp.completion.enable = function(...)
  received = { ... }
end

completion.attach({
  id = 42,
  supports_method = function(_, method)
    return method == "textDocument/completion"
  end,
}, bufnr)

vim.lsp.completion.enable = original_completion_enable
assert(received, "no se habilito el completado para un cliente compatible")
assert(received[1] == true and received[2] == 42 and received[3] == bufnr, "argumentos de completado incorrectos")
assert(received[4].autotrigger == true, "el completado debe usar los disparadores del servidor")

local original_config = vim.lsp.config
local original_enable = vim.lsp.enable
local configured
local enabled
vim.lsp.config = function(name, config)
  configured = { name, config }
end
vim.lsp.enable = function(name)
  enabled = name
end
lsp.enable("servidor_prueba", { cmd = { "false" } })
vim.lsp.config = original_config
vim.lsp.enable = original_enable
assert(configured[1] == "servidor_prueba", "config.lsp no usa vim.lsp.config")
assert(configured[2].cmd[1] == "false", "config.lsp no conserva los ajustes propios")
assert(enabled == "servidor_prueba", "config.lsp no usa vim.lsp.enable")

for _, group in ipairs({ "entorno_nvim_lsp", "entorno_nvim_completion" }) do
  local autocmds = vim.api.nvim_get_autocmds({ event = "LspAttach", group = group })
  assert(#autocmds == 1, "debe existir un unico LspAttach para " .. group)
end

local sources = {
  root .. "/nvim/init.lua",
  root .. "/nvim/lua/config/lsp.lua",
  root .. "/nvim/lua/config/completion.lua",
  root .. "/nvim/lua/plugins/lsp.lua",
}
for _, path in ipairs(sources) do
  local content = table.concat(vim.fn.readfile(path), "\n")
  assert(not content:find('require%("lspconfig"%)'), path .. ": usa la API antigua de lspconfig")
end
