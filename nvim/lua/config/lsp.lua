local M = {}

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

function M.setup()
  local group = vim.api.nvim_create_augroup("entorno_nvim_lsp", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      M.attach(event.buf)
    end,
  })
end

return M
