local root = vim.env.ENTORNO_NVIM_ROOT
local xdg_root = vim.env.ENTORNO_NVIM_XDG_ROOT
local install_dir = xdg_root .. "/data/nvim/site"
local fixture_dir = root .. "/tests/fixtures/treesitter"
local lazy_config = require("lazy.core.config")

local plugin = lazy_config.plugins["nvim-treesitter"]
assert(plugin, "nvim-treesitter no esta registrado")
assert(plugin.lazy == false, "nvim-treesitter no admite carga diferida")
assert(plugin.build == nil, "nvim-treesitter no debe ejecutar TSUpdate automaticamente")
assert(not lazy_config.plugins["nvim-treesitter-textobjects"], "no deben instalarse textobjects")

local cli = vim.env.ENTORNO_NVIM_TREE_SITTER_BIN
local expected_cli = vim.uv.fs_realpath(cli) or cli
local active_cli = vim.uv.fs_realpath(vim.fn.exepath("tree-sitter")) or vim.fn.exepath("tree-sitter")
assert(active_cli == expected_cli, "no se esta usando el tree-sitter-cli paralelo")
local cli_version = vim.system({ cli, "--version" }, { text = true }):wait()
assert(cli_version.code == 0, "tree-sitter-cli no se puede ejecutar")
assert(cli_version.stdout:find("tree%-sitter 0%.26%.11"), "version inesperada de tree-sitter-cli")

local external_languages = {
  "bash",
  "css",
  "html",
  "javascript",
  "json",
  "python",
  "tsx",
  "typescript",
}

local parser_files = vim.fn.glob(install_dir .. "/parser/*.so", false, true)
table.sort(parser_files)
assert(#parser_files == #external_languages, "deben existir exactamente ocho parsers externos")

for index, language in ipairs(external_languages) do
  assert(parser_files[index] == install_dir .. "/parser/" .. language .. ".so", "parser externo inesperado")
  assert(vim.treesitter.language.add(language), "no se puede cargar el parser " .. language)
  assert(vim.treesitter.query.get(language, "highlights"), "faltan consultas de resaltado para " .. language)
end

for _, language in ipairs({ "lua", "markdown", "markdown_inline" }) do
  local paths = vim.api.nvim_get_runtime_file("parser/" .. language .. ".so", true)
  assert(#paths > 0, "falta el parser nativo " .. language)
  assert(not paths[1]:find(install_dir, 1, true), language .. " no debe reemplazar el parser nativo")
end

local fixtures = {
  { file = "ejemplo.sh", filetype = "sh", language = "bash" },
  { file = "ejemplo.py", filetype = "python", language = "python" },
  { file = "ejemplo.js", filetype = "javascript", language = "javascript" },
  { file = "ejemplo.ts", filetype = "typescript", language = "typescript" },
  { file = "ejemplo.tsx", filetype = "typescriptreact", language = "tsx" },
  { file = "ejemplo.json", filetype = "json", language = "json" },
  { file = "ejemplo.html", filetype = "html", language = "html" },
  { file = "ejemplo.css", filetype = "css", language = "css" },
  { file = "ejemplo.md", filetype = "markdown", language = "markdown" },
}

local parsers = {}
for _, fixture in ipairs(fixtures) do
  vim.cmd("edit " .. vim.fn.fnameescape(fixture_dir .. "/" .. fixture.file))
  local bufnr = vim.api.nvim_get_current_buf()
  assert(vim.bo[bufnr].filetype == fixture.filetype, fixture.file .. ": filetype incorrecto")
  assert(vim.treesitter.highlighter.active[bufnr], fixture.file .. ": resaltado Treesitter inactivo")

  local parser = vim.treesitter.get_parser(bufnr, fixture.language)
  local trees = parser:parse(true)
  assert(trees[1] and not trees[1]:root():has_error(), fixture.file .. ": el arbol contiene errores")
  parsers[fixture.file] = parser

  assert(vim.wo.foldmethod == "manual", fixture.file .. ": no debe activar plegado Treesitter")
  assert(not vim.bo.indentexpr:find("nvim%-treesitter"), fixture.file .. ": no debe activar indentacion Treesitter")
end

local function child_languages(parser)
  local languages = {}

  local function visit(tree)
    for language, child in pairs(tree:children()) do
      languages[language] = true
      visit(child)
    end
  end

  visit(parser)
  return languages
end

local html_children = child_languages(parsers["ejemplo.html"])
assert(html_children.javascript, "HTML no inyecta JavaScript")
assert(html_children.css, "HTML no inyecta CSS")

local markdown_children = child_languages(parsers["ejemplo.md"])
assert(markdown_children.markdown_inline, "Markdown no inyecta markdown_inline")
assert(markdown_children.javascript, "Markdown no reconoce el bloque JavaScript")

local function contains_node(node, expected)
  if node:type() == expected then
    return true
  end

  for child in node:iter_children() do
    if contains_node(child, expected) then
      return true
    end
  end

  return false
end

local tsx_tree = parsers["ejemplo.tsx"]:parse(true)[1]
assert(contains_node(tsx_tree:root(), "jsx_element"), "TSX no reconoce el elemento React")
