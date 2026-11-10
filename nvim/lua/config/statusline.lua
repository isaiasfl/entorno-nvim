local M = {}
local branches = {}
local icons = vim.env.ENTORNO_ICONOS ~= "0"

local function branch()
  local name = vim.api.nvim_buf_get_name(0)
  local dir = vim.bo.buftype == "" and name ~= "" and vim.fs.dirname(name) or vim.fn.getcwd()
  local cached = branches[dir]
  if not cached or (not cached.pending and vim.uv.now() - cached.time > 10000) then
    cached = cached or { value = "" }
    branches[dir] = cached
    cached.pending, cached.time = true, vim.uv.now()
    vim.system({ "git", "-C", dir, "rev-parse", "--abbrev-ref", "HEAD" }, { text = true }, function(result)
      vim.schedule(function()
        cached.value = result.code == 0 and vim.trim(result.stdout or ""):gsub("[\r\n]", "") or ""
        cached.pending = false
        vim.cmd.redrawstatus()
      end)
    end)
  end
  return cached.value
end

local function colors()
  local palette = {
    Base = { fg = "#c5d1ca", bg = "#24352f" },
    Normal = { fg = "#152620", bg = "#b6c58b", bold = true },
    Insert = { fg = "#152620", bg = "#8fc4c5", bold = true },
    Visual = { fg = "#152620", bg = "#c4acd4", bold = true },
    Replace = { fg = "#152620", bg = "#e4a09a", bold = true },
    Position = { fg = "#152620", bg = "#8fc4c5", bold = true },
    Muted = { fg = "#9aafa4", bg = "#24352f" },
    Error = { fg = "#edaaa3", bg = "#24352f", bold = true },
    Warn = { fg = "#dfca8e", bg = "#24352f" },
  }
  for name, value in pairs(palette) do
    vim.api.nvim_set_hl(0, "EntornoStatus" .. name, value)
  end
  for _, name in ipairs({ "Normal", "Insert", "Visual", "Replace" }) do
    vim.api.nvim_set_hl(0, "EntornoStatus" .. name .. "Arrow", { fg = palette[name].bg, bg = palette.Base.bg })
  end
  vim.api.nvim_set_hl(0, "EntornoStatusPositionArrow", { fg = palette.Position.bg, bg = palette.Base.bg })
  vim.api.nvim_set_hl(0, "EntornoStatusFile", { fg = "#e0e8df", bg = palette.Base.bg, bold = true })
end

function M.render()
  local win = tonumber(vim.g.statusline_winid) or vim.api.nvim_get_current_win()
  local active = win == vim.api.nvim_get_current_win()
  local width = vim.o.laststatus == 3 and vim.o.columns or vim.api.nvim_win_get_width(win)
  if not active then
    return "%#EntornoStatusMuted# %<%f %m%r%= %l:%c "
  end
  local mode = vim.api.nvim_get_mode().mode
  local label, group = "NORMAL", "Normal"
  if mode:match("^i") then
    label, group = "INSERTAR", "Insert"
  elseif mode:match("^[vV]") or mode == "\22" or mode:match("^[sS]") or mode == "\19" then
    label, group = "VISUAL", "Visual"
  elseif mode:match("^R") then
    label, group = "REEMPLAZAR", "Replace"
  elseif mode:match("^c") then
    label, group = "COMANDO", "Insert"
  elseif mode:match("^t") then
    label, group = "TERMINAL", "Insert"
  end
  local parts = {
    "%#EntornoStatus" .. group .. "# " .. label .. " ",
    "%#EntornoStatus" .. group .. "Arrow#" .. (icons and "" or ">"),
  }
  local git = vim.fn.executable("git") == 1 and branch() or ""
  if width >= 85 and git ~= "" then
    git = vim.fn.strcharpart(git, 0, 24):gsub("%%", "%%%%")
    parts[#parts + 1] = "%#EntornoStatusMuted# " .. (icons and " " or "git:") .. git .. " "
  end
  local file_icons = { markdown = "󰍔", lua = "", python = "", javascript = "", typescript = "", html = "", css = "", sh = "" }
  local icon = icons and ((file_icons[vim.bo.filetype] or "") .. " ") or ""
  parts[#parts + 1] = "%#EntornoStatusFile# " .. icon .. "%<" .. (width < 80 and "%t" or "%f")
  parts[#parts + 1] = "%#EntornoStatusWarn#%m%#EntornoStatusMuted# %r%h%w%="
  local count = vim.diagnostic.count(0)
  for _, item in ipairs({ { vim.diagnostic.severity.ERROR, "Error", "E" }, { vim.diagnostic.severity.WARN, "Warn", "A" } }) do
    if (count[item[1]] or 0) > 0 then
      parts[#parts + 1] = "%#EntornoStatus" .. item[2] .. "# " .. item[3] .. ":" .. count[item[1]] .. " "
    end
  end
  if width >= 100 then
    -- El tipo de archivo es texto externo al formato: escapar los porcentajes.
    parts[#parts + 1] = "%#EntornoStatusMuted# " .. vim.bo.filetype:gsub("%%", "%%%%") .. "  %P "
  end
  parts[#parts + 1] = "%#EntornoStatusPositionArrow#" .. (icons and "" or "<")
  parts[#parts + 1] = "%#EntornoStatusPosition# %l:%c %*"
  return table.concat(parts)
end

function M.setup()
  colors()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("entorno_statusline", { clear = true }),
    callback = colors,
  })
  vim.o.laststatus = 3
  vim.o.statusline = "%!v:lua.require'config.statusline'.render()"
end

return M
