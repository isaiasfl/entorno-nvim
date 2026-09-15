local data_path = require("config.paths").data()
local lazypath = vim.fs.joinpath(data_path, "lazy", "lazy.nvim")
local lockfile = vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json")
local installing = vim.env.ENTORNO_INSTALL_PLUGINS == "1"

if not installing then
  local lock = vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
  for name in pairs(lock) do
    if not vim.uv.fs_stat(vim.fs.joinpath(data_path, "lazy", name)) then
      require("config.profile").unavailable("Plugins", "ejecute scripts/instalar-plugins.sh; editor nativo disponible")
      return { available = false }
    end
  end
end

local function locked_lazy_commit()
  local ok, lock = pcall(vim.json.decode, table.concat(vim.fn.readfile(lockfile), "\n"))
  if not ok or type(lock) ~= "table" or type(lock["lazy.nvim"]) ~= "table" then
    error("No se pudo leer la revision fijada de lazy.nvim")
  end
  return lock["lazy.nvim"].commit
end

if not vim.uv.fs_stat(lazypath) then
  if vim.fn.executable("git") ~= 1 then
    error("lazy.nvim requiere Git para su instalacion inicial")
  end

  vim.fn.mkdir(vim.fs.dirname(lazypath), "p")
  local clone = vim.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }, { text = true }):wait()

  if clone.code ~= 0 then
    error("No se pudo instalar lazy.nvim:\n" .. (clone.stderr or "error desconocido"))
  end

  local checkout = vim.system({
    "git",
    "-C",
    lazypath,
    "switch",
    "--detach",
    locked_lazy_commit(),
  }, { text = true }):wait()
  if checkout.code ~= 0 then
    error("No se pudo fijar lazy.nvim:\n" .. (checkout.stderr or "error desconocido"))
  end
end

vim.opt.rtp:prepend(lazypath)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { lazy = true },
  lockfile = lockfile,
  root = vim.fs.joinpath(data_path, "lazy"),
  local_spec = false,
  checker = { enabled = false },
  change_detection = { notify = false },
  install = { missing = installing, colorscheme = { "habamax" } },
  pkg = { enabled = false },
  rocks = { enabled = false },
})

return { available = true }
