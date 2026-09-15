local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Salir del modo insertar", silent = true })

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Guardar archivo" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Cerrar ventana" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Limpiar busqueda" })

map("n", "<leader>gg", function()
  require("config.git").open()
end, { desc = "Abrir lazygit" })

if require("config.profile").has("pdf") then
  map("n", "<leader>mp", function()
    require("config.markdown_pdf").export_current()
  end, { desc = "Generar PDF del Markdown actual" })

  map("n", "<leader>mv", function()
    require("config.markdown_pdf").export_current(nil, { preview = true })
  end, { desc = "Generar y visualizar PDF del Markdown actual" })
end

if require("config.profile").has("ai") then
  map({ "n", "x" }, "<leader>ac", function()
    local mode = vim.fn.mode()
    require("config.agent_context").send({
      visual = mode == "v" or mode == "V" or mode == "\22",
    })
  end, { desc = "Enviar contexto al agente" })
end

map("n", "<leader>ul", function()
  vim.wo.list = not vim.wo.list
end, { desc = "Alternar caracteres invisibles" })


-- Navegación entre ventanas Neovim
map("n", "<C-h>", "<C-w>h", { desc = "Ventana izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Ventana inferior" })
map("n", "<C-k>", "<C-w>k", { desc = "Ventana superior" })
map("n", "<C-l>", "<C-w>l", { desc = "Ventana derecha" })


-- Edición rápida

-- Duplicar línea
map("n", "<leader>d", "yyp", {
  desc = "Duplicar línea",
})


-- =========================
-- Mover líneas (Linux)
-- Alt + Shift + j/k
-- =========================

map("n", "<A-S-j>", "<cmd>m .+1<cr>==", {
  desc = "Mover línea abajo Linux",
})

map("n", "<A-S-k>", "<cmd>m .-2<cr>==", {
  desc = "Mover línea arriba Linux",
})

map("v", "<A-S-j>", ":m '>+1<cr>gv=gv", {
  desc = "Mover selección abajo Linux",
})

map("v", "<A-S-k>", ":m '<-2<cr>gv=gv", {
  desc = "Mover selección arriba Linux",
})


-- =========================
-- Mover líneas (macOS)
-- Command + Shift + flechas
-- =========================

map("n", "<D-S-Down>", "<cmd>m .+1<cr>==", {
  desc = "Mover línea abajo macOS",
})

map("n", "<D-S-Up>", "<cmd>m .-2<cr>==", {
  desc = "Mover línea arriba macOS",
})

map("v", "<D-S-Down>", ":m '>+1<cr>gv=gv", {
  desc = "Mover selección abajo macOS",
})

map("v", "<D-S-Up>", ":m '<-2<cr>gv=gv", {
  desc = "Mover selección arriba macOS",
})


-- Sangría manteniendo selección
map("v", "<", "<gv", {
  desc = "Reducir sangria",
})

map("v", ">", ">gv", {
  desc = "Aumentar sangria",
})


-- Búsqueda centrada
map("n", "n", "nzzzv", {
  desc = "Siguiente resultado centrado",
})

map("n", "N", "Nzzzv", {
  desc = "Resultado anterior centrado",
})


-- Terminal integrada
map("t", "<Esc><Esc>", [[<C-\><C-n>]], {
  desc = "Salir del modo terminal",
})


-- Diagnósticos LSP

map("n", "]d", function()
  vim.diagnostic.jump({
    count = 1,
    float = true,
  })
end, {
  desc = "Diagnostico siguiente",
})

map("n", "[d", function()
  vim.diagnostic.jump({
    count = -1,
    float = true,
  })
end, {
  desc = "Diagnostico anterior",
})

map("n", "<leader>ld", vim.diagnostic.open_float, {
  desc = "Mostrar diagnostico",
})

-- Sin nowait: mantener tambien las secuencias historicas ee y ef.
map("n", "<leader>e", function()
  require("config.navigation").explorer()
end, { desc = "Abrir explorador" })
