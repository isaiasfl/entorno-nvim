local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Salir del modo insertar", silent = true })

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Guardar archivo" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Cerrar ventana" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Limpiar busqueda" })
map("n", "<leader>gg", function()
  require("config.git").open()
end, { desc = "Abrir lazygit" })
map({ "n", "x" }, "<leader>ac", function()
  local mode = vim.fn.mode()
  require("config.agent_context").send({ visual = mode == "v" or mode == "V" or mode == "\22" })
end, { desc = "Enviar contexto al agente" })
map("n", "<leader>ul", function()
  vim.wo.list = not vim.wo.list
end, { desc = "Alternar caracteres invisibles" })

map("n", "<C-h>", "<C-w>h", { desc = "Ventana izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Ventana inferior" })
map("n", "<C-k>", "<C-w>k", { desc = "Ventana superior" })
map("n", "<C-l>", "<C-w>l", { desc = "Ventana derecha" })

map("v", "<", "<gv", { desc = "Reducir sangria" })
map("v", ">", ">gv", { desc = "Aumentar sangria" })

map("n", "n", "nzzzv", { desc = "Siguiente resultado centrado" })
map("n", "N", "Nzzzv", { desc = "Resultado anterior centrado" })

map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Salir del modo terminal" })

map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Diagnostico siguiente" })

map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Diagnostico anterior" })

map("n", "<leader>e", vim.diagnostic.open_float, {
  desc = "Mostrar diagnostico",
})
