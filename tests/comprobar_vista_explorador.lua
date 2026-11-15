local preview = require("config.explorer_preview")
local tree = vim.api.nvim_get_current_buf()
local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local textfile = dir .. "/prueba.txt"
local imagefile = dir .. "/imagen con espacios.png"
vim.fn.writefile({ "primera línea", "segunda línea" }, textfile)
vim.fn.writefile({ "imagen simulada" }, imagefile)
local function node(path) return { type = "file", absolute_path = path } end
local function count() return #vim.api.nvim_list_wins() end
local initial = count()
preview.toggle(node(textfile), tree)
assert(count() == initial + 1, "no se abrió la vista de texto")
assert(vim.api.nvim_get_current_buf() == tree, "el foco salió del árbol")
local win = vim.api.nvim_list_wins()[2]
assert(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, 1, false)[1] == "primera línea")
preview.toggle(node(textfile), tree)
assert(count() == initial, "no se cerró la vista")

local oldpath = vim.env.PATH
vim.env.PATH = dir
preview.toggle(node(imagefile), tree)
assert(count() == initial, "sin chafa no debe abrirse una ventana")
vim.fn.writefile({ "#!/bin/sh", "printf 'imagen simulada\\n'" }, dir .. "/chafa")
vim.fn.setfperm(dir .. "/chafa", "rwx------")
preview.toggle(node(imagefile), tree)
assert(count() == initial + 1, "no se abrió la vista de imagen")
preview.toggle(node(imagefile), tree)
assert(count() == initial, "no se cerró la vista de imagen")
vim.env.PATH = oldpath
vim.fn.delete(dir, "rf")
print("Vista previa del explorador: correcta")
