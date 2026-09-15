local M = {}

local namespace = vim.api.nvim_create_namespace("ifl_dashboard")
local window_options = {}

local logo = {
  "██╗  ███████╗  ██╗     ",
  "██║  ██╔════╝  ██║     ",
  "██║  █████╗    ██║     ",
  "██║  ██╔══╝    ██║     ",
  "██║  ██║       ███████╗",
  "╚═╝  ╚═╝       ╚══════╝",
}

local actions = {
  { key = "f", label = "Buscar archivos" },
  { key = "g", label = "Buscar texto" },
  { key = "e", label = "Explorador" },
  { key = "b", label = "Buffers" },
  { key = "r", label = "Archivos recientes" },
  { key = "l", label = "Lazygit" },
  { key = "n", label = "Nuevo archivo" },
  { key = "c", label = "Configuración" },
  { key = "q", label = "Salir" },
}

local function is_dashboard(buffer)
  return vim.api.nvim_buf_is_valid(buffer) and vim.bo[buffer].filetype == "ifl_dashboard"
end

local function left_padding(content_width, window_width)
  return string.rep(" ", math.max(0, math.floor((window_width - content_width) / 2)))
end

local function shortened(text, maximum_width)
  if vim.fn.strdisplaywidth(text) <= maximum_width then
    return text
  end

  local suffix_width = math.max(1, maximum_width - 3)
  local suffix = text
  while vim.fn.strdisplaywidth(suffix) > suffix_width do
    suffix = vim.fn.strcharpart(suffix, 1)
  end
  return "..." .. suffix
end

local function remember_and_hide_window_ui(window)
  if not window_options[window] then
    window_options[window] = {}
    for _, option in ipairs({
      "number",
      "relativenumber",
      "cursorline",
      "signcolumn",
      "colorcolumn",
      "foldcolumn",
      "fillchars",
      "statusline",
    }) do
      window_options[window][option] = vim.wo[window][option]
    end
  end

  vim.wo[window].number = false
  vim.wo[window].relativenumber = false
  vim.wo[window].cursorline = false
  vim.wo[window].signcolumn = "no"
  vim.wo[window].colorcolumn = ""
  vim.wo[window].foldcolumn = "0"
  vim.wo[window].fillchars = "eob: "
  vim.wo[window].statusline = " "
end

local function restore_window_ui(window)
  local saved = window_options[window]
  if not saved then
    return
  end

  if vim.api.nvim_win_is_valid(window) then
    for option, value in pairs(saved) do
      vim.wo[window][option] = value
    end
  end
  window_options[window] = nil
end

local function render(buffer, window)
  if not is_dashboard(buffer) or not vim.api.nvim_win_is_valid(window) then
    return
  end

  remember_and_hide_window_ui(window)

  local height = vim.api.nvim_win_get_height(window)
  local width = vim.api.nvim_win_get_width(window)
  local lines = {}
  local highlights = {}

  local function add_line(text, content_width, group)
    local padding = left_padding(content_width or vim.fn.strdisplaywidth(text), width)
    table.insert(lines, padding .. text)
    if group then
      table.insert(highlights, { line = #lines - 1, group = group, start = #padding, finish = -1 })
    end
  end

  local function add_blank()
    table.insert(lines, "")
  end

  local logo_width = 0
  for _, line in ipairs(logo) do
    logo_width = math.max(logo_width, vim.fn.strdisplaywidth(line))
  end

  local menu_width = 0
  for _, action in ipairs(actions) do
    menu_width = math.max(menu_width, vim.fn.strdisplaywidth(string.format("[%s]  %s", action.key, action.label)))
  end

  for _, line in ipairs(logo) do
    add_line(line, logo_width, "IFLLogo")
  end
  add_blank()
  add_line("Neovim de Isaías", nil, "IFLSubtitle")
  local version = vim.version()
  add_line(string.format("v%d.%d.%d", version.major, version.minor, version.patch), nil, "IFLSecondary")
  add_line("Perfil " .. require("config.profile").name .. " | :EntornoInfo", nil, "IFLSecondary")
  add_blank()

  local first_action_line = #lines
  for _, action in ipairs(actions) do
    local text = string.format("[%s]  %s", action.key, action.label)
    local padding = left_padding(menu_width, width)
    table.insert(lines, padding .. text)
    table.insert(highlights, { line = #lines - 1, group = "IFLKey", start = #padding, finish = #padding + 3 })
    table.insert(highlights, { line = #lines - 1, group = "IFLDescription", start = #padding + 5, finish = -1 })
  end
  add_blank()

  local directory = shortened(vim.fn.fnamemodify(vim.fn.getcwd(), ":~"), math.max(10, width - 4))
  add_line(directory, nil, "IFLSecondary")
  if height >= 25 then
    add_blank()
  end
  add_line(":IFL para volver", nil, "IFLSecondary")

  local top_padding = math.max(0, math.floor((height - #lines) / 2))
  if top_padding > 0 then
    local padding_lines = {}
    for _ = 1, top_padding do
      table.insert(padding_lines, "")
    end
    vim.list_extend(padding_lines, lines)
    lines = padding_lines
    for _, highlight in ipairs(highlights) do
      highlight.line = highlight.line + top_padding
    end
    first_action_line = first_action_line + top_padding
  end

  vim.bo[buffer].modifiable = true
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buffer, namespace, 0, -1)
  for _, highlight in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(
      buffer,
      namespace,
      highlight.group,
      highlight.line,
      highlight.start,
      highlight.finish
    )
  end

  vim.bo[buffer].modifiable = false
  pcall(vim.api.nvim_win_set_cursor, window, { first_action_line + 1, 0 })
end

local function load_fzf(method)
  require("config.navigation").pick(method)
end

local function set_actions(buffer)
  local options = { buffer = buffer, silent = true, nowait = true }

  vim.keymap.set("n", "f", function()
    load_fzf("files")
  end, vim.tbl_extend("force", options, { desc = "IFL: buscar archivos" }))
  vim.keymap.set("n", "g", function()
    load_fzf("live_grep")
  end, vim.tbl_extend("force", options, { desc = "IFL: buscar texto" }))
  vim.keymap.set("n", "e", function()
    require("config.navigation").explorer()
  end, vim.tbl_extend("force", options, { desc = "IFL: explorador" }))
  vim.keymap.set("n", "b", function()
    load_fzf("buffers")
  end, vim.tbl_extend("force", options, { desc = "IFL: buffers" }))
  vim.keymap.set("n", "r", function()
    load_fzf("oldfiles")
  end, vim.tbl_extend("force", options, { desc = "IFL: archivos recientes" }))
  vim.keymap.set("n", "l", function()
    require("config.git").open()
  end, vim.tbl_extend("force", options, { desc = "IFL: lazygit" }))
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
  vim.api.nvim_set_hl(0, "IFLSubtitle", { link = "Special" })
  vim.api.nvim_set_hl(0, "IFLKey", { link = "Keyword" })
  vim.api.nvim_set_hl(0, "IFLDescription", { link = "Normal" })
  vim.api.nvim_set_hl(0, "IFLSecondary", { link = "Comment" })
end

local function rerender_dashboards()
  for _, window in ipairs(vim.api.nvim_list_wins()) do
    local buffer = vim.api.nvim_win_get_buf(window)
    if is_dashboard(buffer) then
      render(buffer, window)
    end
  end
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
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
    group = group,
    callback = rerender_dashboards,
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
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    callback = function(event)
      local window = tonumber(event.match)
      if window then
        window_options[window] = nil
      end
    end,
  })
end

return M
