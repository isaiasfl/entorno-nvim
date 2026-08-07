local root = vim.env.ENTORNO_NVIM_ROOT
local fixture = root .. "/tests/fixtures/lsp-tailwind-v4"
local lsp = require("config.lsp")

local function request(client, bufnr, method, params)
  local response = client:request_sync(method, params, 15000, bufnr)
  assert(response, method .. ": el servidor Tailwind no respondio")
  assert(not response.err, method .. ": " .. vim.inspect(response.err))
  return response.result
end

local function position_for(bufnr, needle)
  for line_number, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    local start = line:find(needle, 1, true)
    if start then
      return {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        position = { line = line_number - 1, character = start - 1 + #needle },
      }
    end
  end
  error("No se encontro " .. needle)
end

local function open_with_clients(relative_path, filetype, other_client)
  vim.cmd("edit " .. vim.fn.fnameescape(fixture .. "/" .. relative_path))
  local bufnr = vim.api.nvim_get_current_buf()
  assert(vim.bo[bufnr].filetype == filetype, relative_path .. ": filetype incorrecto")

  assert(vim.wait(20000, function()
    return #vim.lsp.get_clients({ bufnr = bufnr, name = "tailwindcss" }) == 1
      and #vim.lsp.get_clients({ bufnr = bufnr, name = other_client }) == 1
  end, 50), relative_path .. ": no se conectaron Tailwind y " .. other_client)

  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "tailwindcss" })[1]
  assert(client.root_dir == fixture, relative_path .. ": raiz Tailwind incorrecta")
  vim.wait(2000, function()
    return false
  end)
  return bufnr, client
end

local function completion_contains(client, bufnr, needle, expected)
  local received = {}
  for _ = 1, 5 do
    local params = position_for(bufnr, needle)
    params.context = { triggerKind = vim.lsp.protocol.CompletionTriggerKind.Invoked }
    local completion = request(client, bufnr, "textDocument/completion", params)
    local items = completion and (completion.items or completion) or {}
    for _, item in ipairs(items) do
      if #received < 20 then
        received[#received + 1] = item.label
      end
      if item.label == expected then
        return
      end
    end
    vim.wait(1000, function()
      return false
    end)
  end
  error(needle .. ": Tailwind no propuso " .. expected .. "; recibidos: " .. vim.inspect(received))
end

local function detected_root(path, filetype)
  local bufnr = vim.fn.bufnr(path)
  local created = bufnr == -1
  if created then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(bufnr, path)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.fn.readfile(path))
  end
  vim.bo[bufnr].filetype = filetype
  local result
  lsp.tailwind_root(bufnr, function(directory)
    result = directory
  end)
  if created then
    vim.api.nvim_buf_delete(bufnr, { force = true })
  end
  return result
end

vim.lsp.enable("tailwindcss", false)
assert(
  detected_root(fixture .. "/src/app.tsx", "typescriptreact") == fixture,
  "no se detecto package.json con dependencia tailwindcss"
)
local classic = root .. "/tests/fixtures/lsp-tailwind-classic"
assert(
  detected_root(classic .. "/index.html", "html") == classic,
  "no se detecto la configuracion Tailwind clasica"
)
local css_only = root .. "/tests/fixtures/lsp-tailwind-css"
assert(
  detected_root(css_only .. "/input.css", "css") == css_only,
  "no se detecto el import CSS de Tailwind v4"
)
local plain = root .. "/tests/fixtures/lsp-web"
assert(detected_root(plain .. "/index.html", "html") == nil, "Tailwind detecto un proyecto HTML normal")
vim.lsp.enable("tailwindcss")

local html_buf, html_client = open_with_clients("src/index.html", "html", "html")
assert(
  html_client.config.settings.tailwindCSS.experimental.configFile["src/input.css"] == "src/**",
  "before_init no preparo configFile: " .. vim.inspect(html_client.config.settings.tailwindCSS)
)
assert(
  html_client.settings.tailwindCSS.experimental.configFile["src/input.css"] == "src/**",
  "before_init no mantuvo settings compartidos: " .. vim.inspect(html_client.settings.tailwindCSS)
)
local hover_position = position_for(html_buf, "flex")
hover_position.position.character = hover_position.position.character - 1
local hover = request(html_client, html_buf, "textDocument/hover", hover_position)
assert(hover and hover.contents, "Tailwind no devolvio documentacion para flex: " .. vim.inspect(hover))
completion_contains(html_client, html_buf, "bg-r", "bg-red-500")
assert(html_client:supports_method("textDocument/documentColor"), "Tailwind no anuncio colores de documento")
local colors = request(html_client, html_buf, "textDocument/documentColor", {
  textDocument = { uri = vim.uri_from_bufnr(html_buf) },
})
assert(colors and #colors > 0, "Tailwind no devolvio colores")
assert(
  require("vim.lsp.document_color").is_enabled({ bufnr = html_buf }),
  "Neovim no activo colores LSP nativos"
)
assert(vim.wait(15000, function()
  return #vim.diagnostic.get(html_buf) > 0
end, 100), "Tailwind no publico el diagnostico de clases en conflicto")

local jsx_buf, jsx_client = open_with_clients("src/app.jsx", "javascriptreact", "ts_ls")
completion_contains(jsx_client, jsx_buf, "bg-r", "bg-red-500")

local tsx_buf, tsx_client = open_with_clients("src/app.tsx", "typescriptreact", "ts_ls")
completion_contains(tsx_client, tsx_buf, "bg-r", "bg-red-500")

local css_buf, css_client = open_with_clients("src/input.css", "css", "cssls")
assert(css_client:supports_method("textDocument/hover", css_buf), "Tailwind no ofrece hover en CSS")
