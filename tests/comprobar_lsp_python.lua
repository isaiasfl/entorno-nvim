local root = vim.env.ENTORNO_NVIM_ROOT
local fixture = root .. "/tests/fixtures/lsp-python"
local main_path = fixture .. "/main.py"

local function request(client, bufnr, method, params)
  local response = client:request_sync(method, params, 10000, bufnr)
  assert(response, method .. ": Pyright no respondio")
  assert(not response.err, method .. ": " .. vim.inspect(response.err))
  return response.result
end

local function position_params(bufnr, line, character)
  return {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = line, character = character },
  }
end

vim.cmd("edit " .. vim.fn.fnameescape(main_path))
local bufnr = vim.api.nvim_get_current_buf()
assert(vim.bo[bufnr].filetype == "python", "el fixture de Python no tiene el filetype correcto")

assert(vim.wait(15000, function()
  return #vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" }) == 1
end, 50), "Pyright no se conecto al fixture")

local client = vim.lsp.get_clients({ bufnr = bufnr, name = "pyright" })[1]
assert(client.root_dir == fixture, "Pyright no uso pyrightconfig.json como raiz")
for _, method in ipairs({
  "textDocument/completion",
  "textDocument/hover",
  "textDocument/definition",
  "textDocument/references",
  "textDocument/rename",
}) do
  assert(client:supports_method(method), "Pyright no ofrece " .. method)
end

local clients = vim.lsp.get_clients({ bufnr = bufnr })
assert(#clients == 1 and clients[1].name == "pyright", "otro servidor LSP interfiere en el buffer Python")

local use = position_params(bufnr, 3, 16)
local definition = request(client, bufnr, "textDocument/definition", use)
local definition_item = definition and (definition[1] or definition)
local definition_uri = definition_item and (definition_item.uri or definition_item.targetUri)
assert(definition_uri and vim.uri_to_fname(definition_uri) == fixture .. "/helpers.py", "la definicion no apunta al modulo local")

local hover = request(client, bufnr, "textDocument/hover", use)
assert(hover and hover.contents, "Pyright no devolvio hover para average_score")

local references = request(client, bufnr, "textDocument/references", vim.tbl_extend("force", use, {
  context = { includeDeclaration = true },
}))
assert(references and #references >= 2, "Pyright no devolvio declaracion y uso")
local reference_files = {}
for _, reference in ipairs(references) do
  reference_files[vim.uri_to_fname(reference.uri)] = true
end
assert(reference_files[main_path] and reference_files[fixture .. "/helpers.py"], "las referencias no cubren ambos modulos")

local rename = request(client, bufnr, "textDocument/rename", vim.tbl_extend("force", use, {
  newName = "calculate_average",
}))
assert(rename and (rename.changes or rename.documentChanges), "Pyright no devolvio un WorkspaceEdit para rename")
local renamed_files = {}
for uri in pairs(rename.changes or {}) do
  renamed_files[vim.uri_to_fname(uri)] = true
end
for _, edit in ipairs(rename.documentChanges or {}) do
  if edit.textDocument and edit.textDocument.uri then
    renamed_files[vim.uri_to_fname(edit.textDocument.uri)] = true
  end
end
assert(renamed_files[main_path] and renamed_files[fixture .. "/helpers.py"], "rename no cubre ambos modulos")

assert(vim.wait(10000, function()
  local found_type_error = false
  local found_undefined = false
  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
    local message = diagnostic.message:lower()
    found_type_error = found_type_error or message:find("list%[float%]") ~= nil
    found_undefined = found_undefined or message:find("missing_student", 1, true) ~= nil
    assert(message:find('import "helpers" could not be resolved', 1, true) == nil, "Pyright no resolvio el modulo local")
  end
  return found_type_error and found_undefined
end, 50), "Pyright no publico los diagnosticos de tipo y variable indefinida")

vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "", "student." })
local completion = request(client, bufnr, "textDocument/completion", position_params(bufnr, 9, 8))
local items = completion and (completion.items or completion) or {}
local labels = {}
for _, item in ipairs(items) do
  labels[item.label] = true
end
assert(labels.name and labels.scores, "Pyright no completo los atributos de Student")

local completion_map = vim.fn.maparg("<C-Space>", "i", false, true)
assert(type(completion_map.callback) == "function", "Python no conserva el completado nativo de Neovim")
vim.bo[bufnr].modified = false
