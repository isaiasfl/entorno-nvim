local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Guardar archivo" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Cerrar ventana" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Limpiar busqueda" })

map("n", "<C-h>", "<C-w>h", { desc = "Ventana izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Ventana inferior" })
map("n", "<C-k>", "<C-w>k", { desc = "Ventana superior" })
map("n", "<C-l>", "<C-w>l", { desc = "Ventana derecha" })

map("v", "<", "<gv", { desc = "Reducir sangria" })
map("v", ">", ">gv", { desc = "Aumentar sangria" })

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", {
  desc = "Bajar por linea visible",
  expr = true,
  silent = true,
})
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", {
  desc = "Subir por linea visible",
  expr = true,
  silent = true,
})

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
