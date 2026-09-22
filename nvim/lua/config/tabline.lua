local M = {}

local function file_buffers()
  local buffers = {}
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buffer].buflisted
      and vim.bo[buffer].buftype == ""
      and vim.api.nvim_buf_get_name(buffer) ~= "" then
      buffers[#buffers + 1] = buffer
    end
  end
  return buffers
end

function M.render()
  local parts = {}
  local current = vim.api.nvim_get_current_buf()

  for _, buffer in ipairs(file_buffers()) do
    local name = vim.api.nvim_buf_get_name(buffer)
    local label = vim.fn.fnamemodify(name, ":t")
    label = label:gsub("%%", "%%%%")
    local highlight = buffer == current and "%#TabLineSel#" or "%#TabLine#"
    local modified = vim.bo[buffer].modified and " [+]" or ""
    parts[#parts + 1] = highlight .. "%" .. buffer .. "@v:lua.EntornoSwitchBuffer@ "
      .. buffer .. " " .. label .. modified .. " %T"
  end

  return table.concat(parts) .. "%#TabLineFill#%="
end

function M.cycle(direction)
  local buffers = file_buffers()
  if #buffers == 0 then return end

  local current = vim.api.nvim_get_current_buf()
  for index, buffer in ipairs(buffers) do
    if buffer == current then
      vim.api.nvim_set_current_buf(buffers[(index - 1 + direction) % #buffers + 1])
      return
    end
  end
  vim.api.nvim_set_current_buf(buffers[direction > 0 and 1 or #buffers])
end

function M.switch_buffer(buffer, _, button)
  if button == "l" and vim.api.nvim_buf_is_valid(buffer) then
    vim.api.nvim_set_current_buf(buffer)
  end
end

function M.setup()
  _G.EntornoSwitchBuffer = M.switch_buffer
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require'config.tabline'.render()"
end

return M
