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
  if vim.fn.pumvisible() == 1 then return "<C-y>" end
  local ft = vim.bo.filetype
  if (ft == "typescript" or ft == "typescriptreact" or ft == "javascript" or ft == "javascriptreact")
    and vim.api.nvim_get_current_line():match("^%s*/%*%*%s*$")
    and #vim.lsp.get_clients({ bufnr = 0, name = "ts_ls" }) > 0 then
    return "<Cmd>lua require('config.jsdoc').generate({ enter = true })<CR>"
  end
  return "<CR>"
end

function M.attach(client, bufnr)
  if not client:supports_method("textDocument/completion") then
    return
  end

  -- El completado nativo solo dispara con los caracteres anunciados por el
  -- servidor. Incluir letras permite sugerir nombres mientras se escriben.
  local provider = (client.server_capabilities or {}).completionProvider
  if type(provider) == "table" then
    local triggers = vim.deepcopy(provider.triggerCharacters or {})
    for char in ("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$"):gmatch(".") do
      if not vim.tbl_contains(triggers, char) then triggers[#triggers + 1] = char end
    end
    provider.triggerCharacters = triggers
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

  -- Leer el texto tras insertar las teclas previas: una expresion puede
  -- evaluarse antes de que el /** pendiente llegue al buffer.
  vim.keymap.set("i", "<CR>", function()
    local action = M.confirm()
    if action == "<CR>" or action == "<C-y>" then
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(action, true, false, true), "in", false)
    else
      require("config.jsdoc").generate({ enter = true })
    end
  end, {
    desc = "Aceptar completado o nueva linea",
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
