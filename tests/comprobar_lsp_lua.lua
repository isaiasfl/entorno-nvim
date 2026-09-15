local root = vim.env.ENTORNO_NVIM_ROOT
local path = root .. "/tests/fixtures/lsp-lua/main.lua"

local function request(client, bufnr, method, params)
  local response = client:request_sync(method, params, 10000, bufnr)
  assert(response, method .. ": LuaLS no respondio")
  assert(not response.err, method .. ": " .. vim.inspect(response.err))
  return response.result
end

local function position_params(bufnr, line, character)
  return {
    textDocument = { uri = vim.uri_from_bufnr(bufnr) },
    position = { line = line, character = character },
  }
end

vim.cmd("edit " .. vim.fn.fnameescape(path))
local bufnr = vim.api.nvim_get_current_buf()
assert(vim.bo[bufnr].filetype == "lua", "el fixture de Lua no tiene el filetype correcto")

assert(vim.wait(15000, function()
  return #vim.lsp.get_clients({ bufnr = bufnr, name = "lua_ls" }) == 1
end, 50), "lua_ls no se conecto al fixture")

local client = vim.lsp.get_clients({ bufnr = bufnr, name = "lua_ls" })[1]
assert(client.root_dir == root, "lua_ls no limito la raiz al repositorio")
assert(client:supports_method("textDocument/completion"), "LuaLS no ofrece completado")
assert(client:supports_method("textDocument/hover"), "LuaLS no ofrece hover")
assert(client:supports_method("textDocument/definition"), "LuaLS no ofrece definiciones")
assert(client:supports_method("textDocument/references"), "LuaLS no ofrece referencias")
assert(client:supports_method("textDocument/rename"), "LuaLS no ofrece rename")

local use = position_params(bufnr, 4, 20)
local definition = request(client, bufnr, "textDocument/definition", use)
assert(definition and definition[1], "LuaLS no devolvio la definicion local")
assert((definition[1].range or definition[1].targetSelectionRange).start.line == 0, "la definicion Lua no apunta a la funcion")

local hover = request(client, bufnr, "textDocument/hover", position_params(bufnr, 1, 13))
assert(hover and hover.contents, "LuaLS no devolvio hover para vim.trim")

local references = request(client, bufnr, "textDocument/references", vim.tbl_extend("force", use, {
  context = { includeDeclaration = true },
}))
assert(references and #references >= 2, "LuaLS no devolvio las referencias de la funcion")

local rename = request(client, bufnr, "textDocument/rename", vim.tbl_extend("force", use, {
  newName = "limpiar",
}))
assert(rename and (rename.changes or rename.documentChanges), "LuaLS no devolvio un WorkspaceEdit para rename")

assert(vim.wait(10000, function()
  local found_unknown = false
  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr)) do
    assert(not (diagnostic.code == "undefined-global" and diagnostic.message:match("vim")), "vim se marco como global desconocido")
    if diagnostic.code == "undefined-global" and diagnostic.message:match("global_inexistente") then
      found_unknown = true
    end
  end
  return found_unknown
end, 50), "LuaLS no publico el diagnostico de global desconocido")

vim.api.nvim_win_set_cursor(0, { 5, 20 })
vim.cmd("normal gd")
assert(vim.wait(10000, function()
  return vim.api.nvim_get_current_buf() == bufnr and vim.api.nvim_win_get_cursor(0)[1] == 1
end, 50), "gd no navego a la definicion Lua")

vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "", "vim.a" })
local completion = request(client, bufnr, "textDocument/completion", position_params(bufnr, 11, 5))
local items = completion and (completion.items or completion) or {}
local found_api = false
for _, item in ipairs(items) do
  if item.label == "api" then
    found_api = true
    break
  end
end
assert(found_api, "LuaLS no completo vim.api")

vim.bo[bufnr].modified = false
