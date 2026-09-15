local M = {}

local function project_root()
  return vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
end

function M.open(command)
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("lazygit no esta disponible", vim.log.levels.ERROR)
    return
  end

  local cwd = project_root()
  local previous_window = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_create_buf(false, true)
  local width = math.max(1, math.floor(vim.o.columns * 0.9))
  local height = math.max(1, math.floor(vim.o.lines * 0.9))
  local window = vim.api.nvim_open_win(buffer, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
  })

  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].filetype = "lazygit"

  local job = vim.fn.jobstart(command or { "lazygit" }, {
    cwd = cwd,
    env = require("config.process").desktop_env(),
    term = true,
    on_exit = vim.schedule_wrap(function()
      if vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_win_close(window, true)
      end
      if vim.api.nvim_win_is_valid(previous_window) then
        vim.api.nvim_set_current_win(previous_window)
      end
    end),
  })

  if job <= 0 then
    vim.api.nvim_win_close(window, true)
    vim.notify("No se pudo iniciar lazygit", vim.log.levels.ERROR)
    return
  end

  vim.cmd.startinsert()
end

return M
