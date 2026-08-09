local M = {}

local function repository_root()
  local configured = vim.env.ENTORNO_NVIM_ROOT
  if configured and configured ~= "" then
    return configured
  end

  local config = vim.uv.fs_realpath(vim.fn.stdpath("config")) or vim.fn.stdpath("config")
  return vim.fs.dirname(config)
end

function M.repository()
  return repository_root()
end

function M.data()
  if vim.env.ENTORNO_NVIM_ROOT and vim.env.ENTORNO_NVIM_ROOT ~= "" then
    return vim.fn.stdpath("data")
  end
  return vim.fs.joinpath(vim.fn.stdpath("data"), "entorno-nvim")
end

function M.web_lsp_bin()
  return vim.env.ENTORNO_NVIM_LSP_WEB_BIN
    or vim.fs.joinpath(repository_root(), "tools", "lsp-web", "node_modules", ".bin")
end

function M.luals_bin()
  return vim.env.ENTORNO_NVIM_LUALS_BIN
    or vim.fs.joinpath(vim.env.HOME, ".local", "opt", "lua-language-server-3.19.0", "bin", "lua-language-server")
end

function M.tree_sitter_bin()
  return vim.env.ENTORNO_NVIM_TREE_SITTER_BIN
    or vim.fs.joinpath(vim.env.HOME, ".local", "opt", "tree-sitter-cli-0.26.11", "bin", "tree-sitter")
end

function M.setup_tool_path()
  local executable = M.tree_sitter_bin()
  if vim.fn.executable(executable) == 1 and vim.fn.exepath("tree-sitter") ~= executable then
    vim.env.PATH = vim.fs.dirname(executable) .. ":" .. vim.env.PATH
  end
end

function M.luals_log_dir()
  local isolated = vim.env.ENTORNO_NVIM_XDG_ROOT
  if isolated and isolated ~= "" then
    return vim.fs.joinpath(isolated, "state", "nvim", "luals")
  end
  return vim.fs.joinpath(vim.fn.stdpath("state"), "luals")
end

return M
