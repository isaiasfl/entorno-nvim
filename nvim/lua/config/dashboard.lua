local M = {}

local namespace = vim.api.nvim_create_namespace("ifl_dashboard")
local window_options = {}

local logo = {
  " ___ _____ _     ",
  "|_ _|  ___| |    ",
  " | || |_  | |    ",
  " | ||  _| | |___ ",
  "|___|_|   |_____|",
}

local actions = {
  { key = "f", label = "Buscar archivos" },
  { key = "g", label = "Buscar texto" },
  { key = "r", label = "Archivos recientes" },
  { key = "n", label = "Nuevo archivo" },
  { key = "c", label = "Abrir configuración" },
  { key = "q", label = "Salir" },
}

local function is_dashboard(buffer)
  return vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].filetype == "ifl_dashboard"
end

local function center(line, width)
  local padding = math.max(0, math.floor((width - vim.fn.strdisplaywidth(line)) / 2))
  return string.rep(" ", padding) .. line
end

local function remember_and_hide_window_ui(window)
  if not window_options[window] then
    window_options[window] = {}
    for _, option in ipairs({ "number", "relativenumber", "cursorline", "signcolumn", "colorcolumn", "foldcolumn" }) do
      window_options[window][option] = vim.wo[window][option]
    end
  end

  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].cursorline = false
  vim.wo[window].signcolumn = "no"
  vim.wo[window].colorcolumn = ""
  vim.wo[window].foldcolumn = "0"
end

local function restore_window_ui(window)
  local saved = window_options[window]
  if not saved or not vim.api.nvim_win_is_valid(window) then
    return
  end

  for option, value in pairs(saved) do
    vim.wo[window][option] = value
  end
  window_options[window] = nil
end

local function render(buffer, window)
  if not is_dashboard(buffer) or not vim.api.nvim_win_is_valid(window) then
    return
  end

  remember_and_hide_window_ui(window)

  local content = {}
  vim.list_extend(content, logo)
  table.insert(content, "")
  table.insert(content, "Neovim de Isaías")
  table.insert(content, "")
  for _, action in ipairs(actions) do
    table.insert(content, string.format("[%s]  %s", action.key, action.label))
  end
  table.insert(content, "")
  table.insert(content, ":IFL para volver a esta pantalla")

  local height = vim.api.nvim_win_get_height(window)
  local width = vim.api.nvim_win_get_width(window)
  local top_padding = math.max(1, math.floor((height - #content) / 2) - 1)
  local lines = {}
  for _ = 1, top_padding do
    table.insert(lines, "")
  end
  for _, line in ipairs(content) do
    table.insert(lines, center(line, width))
  end

  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)

  local logo_start = top_padding
  for index = logo_start, logo_start + #logo - 1 do
    vim.api.nvim_buf_add_highlight(buffer, namespace, "IFLLogo", index, 0, -1)
  end

  local title_line = logo_start + #logo + 1
  vim.api.nvim_buf_add_highlight(buffer, namespace, "IFLTitle", title_line, 0, -1)
  local actions_start = title_line + 2
  for index = actions_start, actions_start + #actions - 1 do
    vim.api.nvim_buf_add_highlight(buffer, namespace, "IFLAction", index, 0, -1)
  end
  vim.api.nvim_buf_add_highlight(buffer, namespace, "IFLFooter", #lines - 1, 0, -1)

  vim.bo[buffer].modifiable = false
  pcall(vim.api.nvim_win_set_cursor, window, { actions_start + 1, 0 })
end

local function load_fzf(method)
  require("lazy").load({ plugins = { "fzf-lua" } })
  require("fzf-lua")[method]()
end

local function set_actions(buffer)
  local options = { buffer = buffer, silent = true, nowait = true }

  vim.keymap.set("n", "f", function()
    load_fzf("files")
  end, vim.tbl_extend("force", options, { desc = "IFL: buscar archivos" }))
  vim.keymap.set("n", "g", function()
    load_fzf("live_grep")
  end, vim.tbl_extend("force", options, { desc = "IFL: buscar texto" }))
  vim.keymap.set("n", "r", function()
    load_fzf("oldfiles")
  end, vim.tbl_extend("force", options, { desc = "IFL: archivos recientes" }))
  vim.keymap.set("n", "n", "<cmd>enew<cr>", vim.tbl_extend("force", options, { desc = "IFL: nuevo archivo" }))
  vim.keymap.set("n", "c", function()
    local init = vim.fs.joinpath(require("config.paths").repository(), "nvim", "init.lua")
    vim.cmd.edit(vim.fn.fnameescape(init))
  end, vim.tbl_extend("force", options, { desc = "IFL: abrir configuración" }))
  vim.keymap.set("n", "q", "<cmd>quit<cr>", vim.tbl_extend("force", options, { desc = "IFL: salir" }))
end

function M.open()
  local current = vim.api.nvim_get_current_buf()
  if is_dashboard(current) then
    render(current, vim.api.nvim_get_current_win())
    return
  end

  local buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buffer, "ifl://inicio")
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].buftype = "nofile"
  vim.bo[buffer].filetype = "ifl_dashboard"
  vim.bo[buffer].swapfile = false
  vim.api.nvim_win_set_buf(0, buffer)
  set_actions(buffer)
  render(buffer, vim.api.nvim_get_current_win())
end

local function should_open_at_startup()
  if #vim.api.nvim_list_uis() == 0 or vim.fn.argc() > 0 or vim.v.stdyin == 1 then
    return false
  end

  local buffer = vim.api.nvim_get_current_buf()
  return vim.bo[buffer].buftype == ""
    and not vim.bo[buffer].modified
    and vim.api.nvim_buf_get_name(buffer) == ""
    and vim.api.nvim_buf_line_count(buffer) == 1
    and vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1] == ""
end

local function define_highlights()
  vim.api.nvim_set_hl(0, "IFLLogo", { link = "Title" })
  vim.api.nvim_set_hl(0, "IFLTitle", { link = "Special" })
  vim.api.nvim_set_hl(0, "IFLAction", { link = "Normal" })
  vim.api.nvim_set_hl(0, "IFLFooter", { link = "Comment" })
end

function M.setup()
  define_highlights()
  local group = vim.api.nvim_create_augroup("entorno_nvim_dashboard", { clear = true })

  vim.api.nvim_create_user_command("IFL", M.open, { desc = "Abrir el dashboard IFL" })
  vim.api.nvim_create_autocmd("VimEnter", {
    group = group,
    callback = function()
      if should_open_at_startup() then
        M.open()
      end
    end,
  })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      for _, window in ipairs(vim.api.nvim_list_wins()) do
        local buffer = vim.api.nvim_win_get_buf(window)
        if is_dashboard(buffer) then
          render(buffer, window)
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufLeave", {
    group = group,
    callback = function(event)
      if is_dashboard(event.buf) then
        restore_window_ui(vim.api.nvim_get_current_win())
      end
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = define_highlights,
  })
end

return M
