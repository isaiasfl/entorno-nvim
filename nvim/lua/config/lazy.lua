local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  if vim.fn.executable("git") ~= 1 then
    error("lazy.nvim requiere Git para su instalacion inicial")
  end

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
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  defaults = { lazy = true },
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  local_spec = false,
  checker = { enabled = false },
  change_detection = { notify = false },
  install = { colorscheme = { "habamax" } },
  pkg = { enabled = false },
  rocks = { enabled = false },
})
