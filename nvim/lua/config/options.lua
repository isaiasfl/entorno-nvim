local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 5
opt.sidescrolloff = 8

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split"

opt.splitbelow = true
opt.splitright = true
opt.wrap = false
opt.linebreak = true

opt.mouse = "a"
opt.confirm = true
opt.completeopt = { "menu", "menuone", "noselect", "popup" }
opt.termguicolors = true

opt.timeoutlen = 700
opt.updatetime = 250

opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo//"
opt.directory = vim.fn.stdpath("state") .. "/swap//"

opt.list = false
opt.listchars = {
  tab = "> ",
  trail = "-",
  extends = ">",
  precedes = "<",
  nbsp = "+",
}
