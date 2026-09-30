local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Salir del modo insertar", silent = true })

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Guardar archivo" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Cerrar ventana" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Limpiar busqueda" })
map("n", "]b", function() require("config.tabline").cycle(1) end, { desc = "Archivo siguiente" })
map("n", "[b", function() require("config.tabline").cycle(-1) end, { desc = "Archivo anterior" })

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

-- Ortografía: Espacio o y el menú muestra las opciones.
local function spell_on()
  if not vim.wo.spell then
    vim.wo.spell = true
    vim.notify("Ortografía activada (" .. vim.o.spelllang .. ")")
  end
end

local function spell_fix()
  spell_on()
  local word = vim.fn.expand("<cword>")
  if word == "" or vim.fn.spellbadword(word)[1] == "" then
    local before = vim.api.nvim_win_get_cursor(0)
    vim.cmd("normal! ]s")
    if vim.deep_equal(before, vim.api.nvim_win_get_cursor(0)) then
      vim.notify("No hay faltas de ortografía")
      return
    end
    word = vim.fn.expand("<cword>")
  end
  local suggestions = vim.fn.spellsuggest(word, 9)
  if #suggestions == 0 then
    vim.notify("Sin sugerencias para «" .. word .. "». Espacio o a la añade como correcta.")
    return
  end
  vim.ui.select(suggestions, { prompt = "Corregir «" .. word .. "» por:" }, function(choice)
    if choice then
      vim.cmd("normal! ciw" .. choice)
      vim.cmd("stopinsert")
    end
  end)
end

map("n", "<leader>oc", spell_fix, { desc = "Corregir falta (con sugerencias)" })
map("n", "<leader>on", function() spell_on(); vim.cmd("normal! ]s") end, { desc = "Ir a la siguiente falta" })
map("n", "<leader>op", function() spell_on(); vim.cmd("normal! [s") end, { desc = "Ir a la falta anterior" })
map("n", "<leader>oa", function()
  vim.cmd("normal! zg")
  vim.notify("Añadida como correcta: " .. vim.fn.expand("<cword>"))
end, { desc = "Añadir palabra como correcta" })
map("n", "<leader>ot", function()
  vim.wo.spell = not vim.wo.spell
  vim.notify("Ortografía " .. (vim.wo.spell and "activada (" .. vim.o.spelllang .. ")" or "desactivada"))
end, { desc = "Activar o desactivar ortografía" })


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

map("n", "<leader>ld", function()
  vim.diagnostic.open_float({ scope = "buffer" })
end, {
  desc = "Mostrar diagnostico",
})

map("n", "gl", function()
  vim.diagnostic.open_float({ scope = "line" })
end, {
  desc = "Mostrar diagnosticos de esta linea",
})

-- Sin atajos que empiecen por Espacio e: así actúa al instante.
map("n", "<leader>e", function()
  require("config.navigation").explorer()
end, { desc = "Abrir explorador" })
