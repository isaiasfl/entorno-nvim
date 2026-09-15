local M = {}

local default_id = "catppuccin"

local themes = {
  catppuccin = {
    label = "Catppuccin Mocha",
    plugin = "catppuccin",
    colorscheme = "catppuccin-mocha",
  },
  tokyo = {
    label = "Tokyo Night",
    plugin = "tokyonight.nvim",
    colorscheme = "tokyonight-night",
  },
  kanagawa = {
    label = "Kanagawa Wave",
    plugin = "kanagawa.nvim",
    colorscheme = "kanagawa-wave",
  },
}

local order = { "catppuccin", "tokyo", "kanagawa" }

function M.state_path()
  local override = vim.env.ENTORNO_NVIM_THEME_STATE
  if override and override ~= "" then
    return override
  end

  local state_home = vim.env.XDG_STATE_HOME
  if not state_home or state_home == "" then
    state_home = vim.fs.dirname(vim.fn.stdpath("state"))
  end
  return vim.fs.joinpath(state_home, "entorno-nvim", "theme")
end

local function normalized_id(value)
  if type(value) ~= "string" then
    return default_id
  end
  local id = vim.trim(value)
  return themes[id] and id or default_id
end

function M.read()
  local ok, lines = pcall(vim.fn.readfile, M.state_path(), "", 1)
  if not ok or not lines[1] then
    return default_id
  end
  return normalized_id(lines[1])
end

function M.persist(id)
  id = normalized_id(id)
  local path = M.state_path()
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local ok, error_message = pcall(vim.fn.writefile, { id }, path)
  if not ok then
    vim.notify("No se pudo guardar el tema: " .. tostring(error_message), vim.log.levels.ERROR)
    return false
  end
  return true
end

function M.apply(id, options)
  options = options or {}
  id = normalized_id(id)
  local theme = themes[id]

  require("lazy").load({ plugins = { theme.plugin } })
  vim.cmd.colorscheme(theme.colorscheme)
  M.current = id

  if options.persist then
    M.persist(id)
  end
  return id
end

function M.select()
  local choices = {}
  for _, id in ipairs(order) do
    choices[#choices + 1] = { id = id, label = themes[id].label }
  end

  vim.ui.select(choices, {
    prompt = "Tema visual",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      M.apply(choice.id, { persist = true })
    end
  end)
end

function M.setup()
  if not require("config.lazy").available then
    vim.cmd.colorscheme("habamax")
    return
  end
  M.apply(M.read())
  vim.keymap.set("n", "<leader>ut", M.select, {
    desc = "Seleccionar tema visual",
    silent = true,
  })
end

M.default = default_id
M.themes = themes
M.order = order

return M
