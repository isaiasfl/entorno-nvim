local M = {}

function M.navigate(direction)
  if vim.fn.pumvisible() == 1 then
    return direction == 1 and "<C-n>" or "<C-p>"
  end

  if vim.snippet.active({ direction = direction }) then
    return ("<Cmd>lua vim.snippet.jump(%d)<CR>"):format(direction)
  end

  return direction == 1 and "<Tab>" or "<S-Tab>"
end

function M.confirm()
  return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>"
end

function M.attach(client, bufnr)
  if not client:supports_method("textDocument/completion") then
    return
  end

  vim.lsp.completion.enable(true, client.id, bufnr, {
    autotrigger = true,
  })
end

function M.setup()
  vim.keymap.set({ "i", "s" }, "<Tab>", function()
    return M.navigate(1)
  end, {
    desc = "Completado siguiente o Tab",
    expr = true,
    silent = true,
  })

  vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
    return M.navigate(-1)
  end, {
    desc = "Completado anterior o Shift-Tab",
    expr = true,
    silent = true,
  })

  vim.keymap.set("i", "<CR>", M.confirm, {
    desc = "Aceptar completado o nueva linea",
    expr = true,
    silent = true,
  })

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
