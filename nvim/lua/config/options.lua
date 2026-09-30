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
opt.wrap = true
opt.linebreak = true
opt.foldmethod = "indent"
opt.foldlevel = 99
opt.foldlevelstart = 99

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
    -- Get-Clipboard devuelve finales \r\n de Windows: sin quitarlos, cada
    -- pegado (p, yyp, Espacio t d...) deja ^M. Receta de :help clipboard-wsl.
    local paste = 'powershell.exe -NoLogo -NoProfile -c '
      .. '[Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
    vim.g.clipboard = {
      name = "WSL-clip",
      copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
      paste = { ["+"] = paste, ["*"] = paste },
      cache_enabled = false,
    }
  end
end

opt.timeoutlen = 700
opt.updatetime = 250

opt.undofile = true
opt.undodir = vim.fn.stdpath("state") .. "/undo//"
opt.directory = vim.fn.stdpath("state") .. "/swap//"

-- Ortografía en español e inglés. El diccionario español lo instala
-- scripts/instalar-ortografia.sh; si falta, solo inglés y sin descargas.
local spell_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "spell")
if #vim.api.nvim_get_runtime_file("spell/es.utf-8.spl", false) > 0 then
  opt.spelllang = { "es", "en" }
else
  opt.spelllang = { "en" }
end
opt.spellfile = vim.fs.joinpath(spell_dir, "propias.utf-8.add")
opt.spelloptions = { "camel", "noplainbuffer" }
opt.spellsuggest = { "best", 9 }

-- Línea de estado: archivo, errores y avisos en palabras, posición.
function _G.entorno_diagnosticos()
  if not package.loaded["vim.diagnostic"] then
    return ""
  end
  local count = vim.diagnostic.count(0)
  local severity = vim.diagnostic.severity
  local parts = {}
  local labels = {
    { severity.ERROR, "Errores", "DiagnosticError" },
    { severity.WARN, "Avisos", "DiagnosticWarn" },
    { severity.INFO, "Info", "DiagnosticInfo" },
  }
  for _, item in ipairs(labels) do
    local n = count[item[1]] or 0
    if n > 0 then
      parts[#parts + 1] = "%#" .. item[3] .. "#" .. item[2] .. ": " .. n .. "%*"
    end
  end
  return table.concat(parts, "  ")
end
opt.statusline = "%<%f %h%w%m%r%=%{%v:lua.entorno_diagnosticos()%}   %l,%c  %P "

opt.list = false
opt.listchars = {
  tab = "> ",
  trail = "-",
  extends = ">",
  precedes = "<",
  nbsp = "+",
}
