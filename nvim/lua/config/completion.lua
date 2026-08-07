local M = {}

function M.attach(client, bufnr)
  if not client:supports_method("textDocument/completion") then
    return
  end

  vim.lsp.completion.enable(true, client.id, bufnr, {
    autotrigger = true,
  })
end

function M.setup()
  vim.keymap.set("i", "<C-Space>", vim.lsp.completion.get, {
    desc = "LSP: Solicitar completado",
    silent = true,
  })

  local group = vim.api.nvim_create_augroup("entorno_nvim_completion", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if client then
        M.attach(client, event.buf)
      end
    end,
  })
end

return M
