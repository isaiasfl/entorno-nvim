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
opt.clipboard = "unnamedplus"

-- WSL2 sin WSLg no expone X11 ni Wayland. Si hay interoperabilidad con
-- Windows se usa su portapapeles; si no, se mantiene el registro interno.
if vim.fn.has("wsl") == 1 then
  if vim.fn.executable("win32yank.exe") == 1 then
    vim.g.clipboard = {
      name = "win32yank",
      copy = { ["+"] = { "win32yank.exe", "-i", "--crlf" }, ["*"] = { "win32yank.exe", "-i", "--crlf" } },
      paste = { ["+"] = { "win32yank.exe", "-o", "--lf" }, ["*"] = { "win32yank.exe", "-o", "--lf" } },
      cache_enabled = true,
    }
  elseif vim.fn.executable("clip.exe") == 1 and vim.fn.executable("powershell.exe") == 1 then
    local powershell = { "powershell.exe", "-NoProfile", "-Command", "Get-Clipboard" }
    vim.g.clipboard = {
      name = "WSL-clip",
      copy = { ["+"] = { "clip.exe" }, ["*"] = { "clip.exe" } },
      paste = { ["+"] = vim.deepcopy(powershell), ["*"] = vim.deepcopy(powershell) },
      cache_enabled = false,
    }
  end
end

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
