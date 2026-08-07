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

for _, name in ipairs({ "ts_ls", "html", "cssls", "jsonls", "tailwindcss", "lua_ls", "bashls", "basedpyright" }) do
  assert(type(vim.lsp.config[name]) == "table", "falta la configuracion de catalogo " .. name)
  assert(not vim.lsp.is_enabled(name), "no debe habilitarse todavia " .. name)
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

local lsp = require("config.lsp")
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
