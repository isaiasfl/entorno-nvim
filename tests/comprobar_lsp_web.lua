local root = vim.env.ENTORNO_NVIM_ROOT
local fixture = root .. "/tests/fixtures/lsp-web"

local function open_with_client(relative_path, filetype, client_name)
  vim.cmd("edit " .. vim.fn.fnameescape(fixture .. "/" .. relative_path))
  local bufnr = vim.api.nvim_get_current_buf()
  assert(vim.bo[bufnr].filetype == filetype, relative_path .. ": filetype incorrecto")

  local attached = vim.wait(15000, function()
    return #vim.lsp.get_clients({ bufnr = bufnr, name = client_name }) == 1
  end, 50)
  assert(attached, relative_path .. ": " .. client_name .. " no se conecto")

  local client = vim.lsp.get_clients({ bufnr = bufnr, name = client_name })[1]
  assert(client:supports_method("textDocument/completion"), client_name .. " no ofrece completado")
  assert(client.capabilities.textDocument.completion.completionItem.snippetSupport, "faltan snippets nativos")
  local completion_provider = client.server_capabilities.completionProvider
  assert(completion_provider and #completion_provider.triggerCharacters > 0, client_name .. " no anuncia autotrigger")
  return bufnr, client
end

local function request(client, bufnr, method, params)
  local response = client:request_sync(method, params, 10000, bufnr)
  assert(response, method .. ": el servidor no respondio")
  assert(not response.err, method .. ": " .. vim.inspect(response.err))
  return response.result
end

local function position_params(bufnr, line, character)
  return {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = line, character = character },
  }
end

for _, case in ipairs({
  { "src/main.js", "javascript" },
  { "src/main.ts", "typescript" },
  { "src/component.jsx", "javascriptreact" },
  { "src/component.tsx", "typescriptreact" },
}) do
  open_with_client(case[1], case[2], "ts_ls")
end

local ts_buf, ts_client = open_with_client("src/main.ts", "typescript", "ts_ls")
assert(ts_client.root_dir == fixture, "ts_ls no uso el package.json del proyecto como raiz")
local symbol = position_params(ts_buf, 0, 10)
local definition = request(ts_client, ts_buf, "textDocument/definition", symbol)
assert(definition and definition[1], "TypeScript no devolvio la definicion")
local definition_uri = definition[1].uri or definition[1].targetUri
assert(
  definition_uri and vim.uri_to_fname(definition_uri):match("/src/main%.ts$"),
  "la definicion no apunta al import de main.ts: " .. vim.inspect(definition)
)

local hover = request(ts_client, ts_buf, "textDocument/hover", symbol)
assert(hover and hover.contents, "TypeScript no devolvio hover")

vim.api.nvim_win_set_cursor(0, { 3, 22 })
vim.cmd("normal gd")
assert(vim.wait(10000, function()
  local file = vim.api.nvim_buf_get_name(0)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local import_alias = file:match("/src/main%.ts$") and cursor[1] == 1
  local source_definition = file:match("/src/math%.ts$") and cursor[1] == 2
  return import_alias or source_definition
end, 50), "gd no navego a la definicion real: " .. vim.inspect({
  file = vim.api.nvim_buf_get_name(0),
  cursor = vim.api.nvim_win_get_cursor(0),
  map = vim.fn.maparg("gd", "n", false, true),
}))

local math_buf, math_client = open_with_client("src/math.ts", "typescript", "ts_ls")
local declaration = position_params(math_buf, 1, 16)
local references = request(math_client, math_buf, "textDocument/references", vim.tbl_extend("force", declaration, {
  context = { includeDeclaration = true },
}))
assert(references and #references >= 2, "TypeScript no devolvio referencias")

local rename = request(math_client, math_buf, "textDocument/rename", vim.tbl_extend("force", declaration, {
  newName = "sumar",
}))
assert(rename and (rename.changes or rename.documentChanges), "rename no devolvio un WorkspaceEdit")

local diagnostic_buf = open_with_client("src/diagnostic.ts", "typescript", "ts_ls")
assert(vim.wait(10000, function()
  return #vim.diagnostic.get(diagnostic_buf, { severity = vim.diagnostic.severity.ERROR }) > 0
end, 50), "TypeScript no publico el diagnostico esperado")

local import_buf, import_client = open_with_client("src/auto-import.ts", "typescript", "ts_ls")
local completion = request(import_client, import_buf, "textDocument/completion", position_params(import_buf, 0, 2))
local items = completion.items or completion
local auto_import
for _, item in ipairs(items or {}) do
  if item.label == "add" then
    auto_import = item
    break
  end
end
assert(auto_import, "TypeScript no propuso el simbolo exportado para auto-import")
if not auto_import.additionalTextEdits and import_client:supports_method("completionItem/resolve") then
  auto_import = request(import_client, import_buf, "completionItem/resolve", auto_import)
end
assert(auto_import.additionalTextEdits and #auto_import.additionalTextEdits > 0, "el completado no incluyo el import automatico")

local html_buf, html_client = open_with_client("index.html", "html", "html")
assert(html_client.server_capabilities.hoverProvider, "HTML no ofrece hover")
vim.api.nvim_buf_set_lines(html_buf, 9, 10, false, { "    <di" })
local html_completion = request(html_client, html_buf, "textDocument/completion", position_params(html_buf, 9, 7))
local html_items = html_completion.items or html_completion
local div_completion
for _, item in ipairs(html_items or {}) do
  if item.label == "div" then
    div_completion = item
    break
  end
end
assert(div_completion, "HTML no devolvio el completado de etiqueta esperado")
assert(type(vim.snippet.expand) == "function", "Neovim no dispone de expansion nativa de snippets")

local embedded = vim.lsp.config.html.init_options.embeddedLanguages
assert(embedded.javascript and embedded.css, "HTML debe conservar JavaScript y CSS embebidos")
vim.bo[html_buf].modified = false

local css_buf, css_client = open_with_client("styles.css", "css", "cssls")
local css_completion = request(css_client, css_buf, "textDocument/completion", position_params(css_buf, 5, 10))
assert(css_completion and #(css_completion.items or css_completion) > 0, "CSS no devolvio completado")

open_with_client("data.json", "json", "jsonls")
local invalid_json_buf = open_with_client("invalid.json", "json", "jsonls")
assert(vim.wait(10000, function()
  return #vim.diagnostic.get(invalid_json_buf) > 0
end, 50), "JSON no publico el diagnostico esperado")

local completion_map = vim.fn.maparg("<C-Space>", "i", false, true)
assert(type(completion_map.callback) == "function", "Ctrl-Space no conserva el completado nativo")
local lsp_source = table.concat(vim.fn.readfile(root .. "/nvim/lua/config/lsp.lua"), "\n")
assert(not lsp_source:find("BufWritePre", 1, true), "no debe configurarse format-on-save")
assert(#vim.lsp.get_clients({ name = "tailwindcss" }) == 0, "Tailwind no debe iniciarse")
