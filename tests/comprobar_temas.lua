local root = assert(vim.env.ENTORNO_NVIM_ROOT, "falta la raiz del repositorio")
local state_file = assert(vim.env.ENTORNO_NVIM_THEME_STATE, "falta el estado temporal de temas")
local theme = require("config.theme")

local function mapping(lhs)
  return vim.fn.maparg(lhs, "n", false, true)
end

local function highlight(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function assert_highlight(name)
  assert(next(highlight(name)) ~= nil, "highlight sin definicion: " .. name)
end

local function signature(name)
  local value = highlight(name)
  return table.concat({ value.fg or "", value.bg or "", value.sp or "", value.bold and "b" or "", value.italic and "i" or "" }, ":")
end

local function assert_semantic_variety(id)
  local treesitter_groups = {
    "@keyword",
    "@variable",
    "@variable.parameter",
    "@function",
    "@type",
    "@property",
    "@tag",
    "@tag.attribute",
    "@string",
    "@number",
    "@comment",
  }
  local distinct = {}
  for _, group in ipairs(treesitter_groups) do
    assert_highlight(group)
    distinct[signature(group)] = true
  end
  assert(vim.tbl_count(distinct) >= 6, id .. " no diferencia suficientemente los grupos Tree-sitter")

  -- Neovim 0.12 enlaza los tipos semanticos con sus capturas Tree-sitter.
  -- Los temas modernos pueden dejar un grupo LSP vacio deliberadamente para
  -- que Tree-sitter conserve la prioridad, especialmente en variables.
  local semantic_fallbacks = {
    ["@lsp.type.variable"] = "@variable",
    ["@lsp.type.parameter"] = "@variable.parameter",
    ["@lsp.type.function"] = "@function",
    ["@lsp.type.type"] = "@type",
    ["@lsp.type.interface"] = "@type",
    ["@lsp.type.property"] = "@property",
  }
  for group, fallback in pairs(semantic_fallbacks) do
    assert(vim.fn.hlexists(group) == 1, "grupo semantico inexistente: " .. group)
    local semantic = highlight(group)
    if next(semantic) == nil then
      assert_highlight(fallback)
    else
      distinct[signature(group)] = true
    end
  end

  for _, group in ipairs({
    "DiagnosticError",
    "DiagnosticWarn",
    "DiagnosticInfo",
    "DiagnosticHint",
    "DiagnosticSignError",
    "DiagnosticUnderlineError",
    "FzfLuaNormal",
    "FzfLuaBorder",
    "NvimTreeNormal",
    "NvimTreeFolderName",
    "NvimTreeRootFolder",
  }) do
    assert_highlight(group)
  end
end

assert(theme.default == "catppuccin", "el ID predeterminado no es catppuccin")
assert(theme.current == "catppuccin", "el arranque sin estado no usa catppuccin")
assert(vim.g.colors_name == "catppuccin-mocha", "el tema predeterminado no es Catppuccin Mocha")
assert(theme.state_path() == state_file, "el test no usa el estado temporal")

local theme_mapping = mapping(" ut")
assert(theme_mapping.desc == "Seleccionar tema visual", "leader+ut no tiene la descripcion esperada")
assert(type(theme_mapping.callback) == "function", "leader+ut no usa un callback")

assert(theme.read() == "catppuccin", "un estado inexistente no usa el fallback")
vim.fn.mkdir(vim.fs.dirname(state_file), "p")
vim.fn.writefile({}, state_file)
assert(theme.read() == "catppuccin", "un estado vacio no usa el fallback")
vim.fn.writefile({ "desconocido" }, state_file)
assert(theme.read() == "catppuccin", "un estado desconocido no usa el fallback")

require("lazy").load({ plugins = { "fzf-lua", "nvim-tree.lua" } })
local original_select = vim.ui.select
local selected_items
local selected_options
vim.ui.select = function(items, options, on_choice)
  selected_items = items
  selected_options = options
  on_choice(items[2])
end
theme_mapping.callback()
vim.ui.select = original_select

assert(type(selected_items) == "table" and #selected_items == 3, "leader+ut no llama vim.ui.select con tres temas")
local labels = {}
for _, item in ipairs(selected_items) do
  labels[#labels + 1] = selected_options.format_item(item)
end
assert(vim.deep_equal(labels, { "Catppuccin Mocha", "Tokyo Night", "Kanagawa Wave" }), "nombres del selector incorrectos")
assert(theme.current == "tokyo", "el selector no aplico Tokyo Night")
assert(vim.g.colors_name == "tokyonight-night", "el selector no uso la variante night")
assert(vim.fn.readfile(state_file)[1] == "tokyo", "el selector no persistio el ID tokyo")

local fixture = root .. "/tests/fixtures/treesitter/ejemplo.tsx"
vim.cmd("edit " .. vim.fn.fnameescape(fixture))
assert(vim.bo.filetype == "typescriptreact", "el fixture no se detecto como TSX")
assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "Tree-sitter no esta activo en el fixture TSX")
local parser = vim.treesitter.get_parser(0, "tsx")
assert(parser and #parser:parse(true) > 0, "el parser TSX no genero un arbol")

local captures = {}
for row = 0, vim.api.nvim_buf_line_count(0) - 1 do
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
  for column = 0, #line do
    for _, capture in ipairs(vim.treesitter.get_captures_at_pos(0, row, column)) do
      captures[capture.capture] = true
    end
  end
end
for _, capture in ipairs({ "keyword", "variable", "variable.parameter", "function", "type", "tag.attribute", "string", "number", "comment" }) do
  assert(captures[capture], "el fixture TSX no ejercita @" .. capture)
end
assert(captures.property or captures["variable.member"], "el fixture TSX no ejercita una propiedad")
assert(captures.tag or captures["tag.builtin"], "el fixture TSX no ejercita una etiqueta JSX")

local expected_schemes = {
  catppuccin = "catppuccin-mocha",
  tokyo = "tokyonight-night",
  -- kanagawa-wave es el alias de entrada; el plugin registra el nombre
  -- canonico del colorscheme aplicado como "kanagawa".
  kanagawa = "kanagawa",
}
for _, id in ipairs(theme.order) do
  assert(theme.apply(id) == id, "no se pudo aplicar " .. id)
  assert(vim.g.colors_name == expected_schemes[id], "colorscheme incorrecto para " .. id)
  assert_semantic_variety(id)
end

assert(theme.apply("invalido") == "catppuccin", "apply no protege frente a IDs desconocidos")
assert(vim.g.colors_name == "catppuccin-mocha", "apply no recupera Catppuccin ante un ID desconocido")
theme.apply("kanagawa", { persist = true })
assert(vim.fn.readfile(state_file)[1] == "kanagawa", "apply no persistio Kanagawa")
