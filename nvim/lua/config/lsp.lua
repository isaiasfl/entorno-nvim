local M = {}

local function typescript_root(bufnr, on_dir)
  local lockfiles = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
  local project_root = vim.fs.root(bufnr, { lockfiles, { "package.json" }, { ".git" } })
  local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
  local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })

  if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
    return
  end
  if deno_root and (not project_root or #deno_root >= #project_root) then
    return
  end

  on_dir(project_root or vim.fn.getcwd())
end

M.web_servers = {
  ts_ls = {
    executable = "typescript-language-server",
    args = { "--stdio" },
    config = { root_dir = typescript_root },
  },
  html = {
    executable = "vscode-html-language-server",
    args = { "--stdio" },
    config = { settings = { html = {}, css = {}, javascript = {} } },
  },
  cssls = { executable = "vscode-css-language-server", args = { "--stdio" } },
  jsonls = { executable = "vscode-json-language-server", args = { "--stdio" } },
}

local function map(bufnr, lhs, callback, description)
  vim.keymap.set("n", lhs, callback, {
    buffer = bufnr,
    desc = description,
    silent = true,
  })
end

function M.attach(bufnr)
  map(bufnr, "gd", vim.lsp.buf.definition, "LSP: Ir a la definicion")
  map(bufnr, "gD", vim.lsp.buf.declaration, "LSP: Ir a la declaracion")
  map(bufnr, "<leader>lf", function()
    vim.lsp.buf.format({ bufnr = bufnr })
  end, "LSP: Formatear buffer")
end

function M.enable(name, config)
  vim.lsp.config(name, config or {})
  vim.lsp.enable(name)
end

local function enable_web_servers()
  local bin_dir = vim.env.ENTORNO_NVIM_LSP_WEB_BIN
  if not bin_dir or bin_dir == "" then
    error("Falta ENTORNO_NVIM_LSP_WEB_BIN; usa scripts/arrancar.sh")
  end

  for name, server in pairs(M.web_servers) do
    local executable = vim.fs.joinpath(bin_dir, server.executable)
    if vim.fn.executable(executable) ~= 1 then
      error("Servidor LSP no ejecutable: " .. executable)
    end

    local config = vim.tbl_deep_extend("force", vim.deepcopy(server.config or {}), {
      cmd = vim.list_extend({ executable }, vim.deepcopy(server.args)),
    })
    M.enable(name, config)
  end
end

function M.setup()
  vim.diagnostic.config({ update_in_insert = true })

  local group = vim.api.nvim_create_augroup("entorno_nvim_lsp", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      M.attach(event.buf)
    end,
  })

  enable_web_servers()
end

return M
