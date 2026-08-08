local lazy_config = require("lazy.core.config")
local root = vim.env.ENTORNO_NVIM_ROOT
local completion = require("config.completion")

local function mapping(mode, lhs)
  return vim.fn.maparg(lhs, mode, false, true)
end

for lhs, description in pairs({
  ["<Tab>"] = "Completado siguiente o Tab",
  ["<S-Tab>"] = "Completado anterior o Shift-Tab",
}) do
  for _, mode in ipairs({ "i", "s" }) do
    local item = mapping(mode, lhs)
    assert(item.desc == description, lhs .. ": descripcion incorrecta en modo " .. mode)
    assert(item.expr == 1 and item.silent == 1, lhs .. ": debe ser expresivo y silencioso")
  end
end

local enter = mapping("i", "<CR>")
assert(enter.desc == "Aceptar completado o nueva linea", "Enter no confirma el completado")
assert(enter.expr == 1 and enter.silent == 1, "Enter debe ser expresivo y silencioso")
assert(next(mapping("i", "<C-n>")) == nil, "Ctrl+n debe conservar su comportamiento nativo")
assert(next(mapping("i", "<C-p>")) == nil, "Ctrl+p debe conservar su comportamiento nativo")

local original_pumvisible = vim.fn.pumvisible
local original_snippet_active = vim.snippet.active
vim.fn.pumvisible = function()
  return 1
end
assert(completion.navigate(1) == "<C-n>", "Tab no avanza por el menu")
assert(completion.navigate(-1) == "<C-p>", "Shift-Tab no retrocede por el menu")
assert(completion.confirm() == "<C-y>", "Enter no acepta la seleccion")

vim.fn.pumvisible = function()
  return 0
end
vim.snippet.active = function(opts)
  return opts.direction == 1
end
assert(completion.navigate(1):find("vim.snippet.jump%(1%)"), "Tab no conserva snippets nativos")
assert(completion.navigate(-1) == "<S-Tab>", "Shift-Tab no conserva su comportamiento normal")
assert(completion.confirm() == "<CR>", "Enter no conserva la nueva linea")
vim.fn.pumvisible = original_pumvisible
vim.snippet.active = original_snippet_active

local plugin = lazy_config.plugins["nvim-ts-autotag"]
assert(plugin, "nvim-ts-autotag no esta registrado")
assert(plugin.commit == "88c1453db4ba7dd24131086fe51fdf74e587d275", "commit de nvim-ts-autotag incorrecto")
assert(plugin.dependencies == nil, "nvim-ts-autotag no debe introducir dependencias")
assert(plugin.build == nil, "nvim-ts-autotag no debe ejecutar builds")

require("lazy").load({ plugins = { "nvim-ts-autotag" } })
local setup = require("nvim-ts-autotag.config.plugin")
for _, filetype in ipairs({ "html", "javascriptreact", "typescriptreact" }) do
  local opts = setup.get_opts(filetype)
  assert(opts.enable_close and opts.enable_rename, filetype .. ": faltan cierre o renombrado")
  assert(not opts.enable_close_on_slash, filetype .. ": el cierre con barra debe estar desactivado")
end
assert(not setup.get_opts("css").enable_close, "autotag no debe activarse en CSS")

local function edit(filetype, before, keys, expected)
  local bufnr = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { before })
  vim.bo[bufnr].filetype = filetype
  assert(vim.treesitter.language.add(vim.treesitter.language.get_lang(filetype)), filetype .. ": falta el parser")
  require("nvim-ts-autotag.internal").attach(bufnr)
  vim.api.nvim_win_set_cursor(0, { 1, math.max(#before - 1, 0) })
  vim.fn.feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt")
  vim.wait(20)
  local actual = vim.api.nvim_get_current_line()
  assert(actual == expected, filetype .. ": esperado " .. expected .. ", obtenido " .. actual)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

edit("html", "<div", "A><Esc>", "<div></div>")
edit("html", '<section class="principal"', "A><Esc>", '<section class="principal"></section>')
edit("html", "<div><section", "A><Esc>", "<div><section></section>")
edit("html", "<input", "A><Esc>", "<input>")
edit("javascriptreact", "<Card", "A><Esc>", "<Card></Card>")
edit("typescriptreact", "<Panel", "A><Esc>", "<Panel></Panel>")
edit("typescriptreact", "<Panel /", "A><Esc>", "<Panel />")
edit("typescriptreact", "<div className=", 'A"<Right>><Esc>', '<div className=""></div>')
edit("html", "<div></div>", "0fdciwsection<Esc>", "<section></section>")
edit("typescriptreact", "<Card></Card>", "$hciwPanel<Esc>", "<Panel></Panel>")
assert(package.loaded["mini.pairs"], "mini.pairs debe convivir con autotag")

local lockfile = vim.json.decode(table.concat(vim.fn.readfile(root .. "/nvim/lazy-lock.json"), "\n"))
assert(lockfile["nvim-ts-autotag"], "nvim-ts-autotag no esta fijado en lazy-lock.json")
assert(lockfile["nvim-ts-autotag"].commit == plugin.commit, "lazy-lock.json no fija nvim-ts-autotag")
