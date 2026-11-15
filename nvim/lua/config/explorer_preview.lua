local M = {}
local preview_win
local preview_tree

local images = { avif = true, gif = true, jpeg = true, jpg = true, png = true, svg = true, webp = true }

local function close()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
  end
  preview_win, preview_tree = nil, nil
end

function M.toggle(node, tree_buf)
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    close()
    return
  end
  if not node or node.type ~= "file" then
    vim.notify("Seleccione un archivo para previsualizarlo", vim.log.levels.INFO)
    return
  end
  local path = node.absolute_path
  local extension = vim.fn.fnamemodify(path, ":e"):lower()
  local is_image = images[extension]
  if is_image and vim.fn.executable("chafa") ~= 1 then
    vim.notify("Para previsualizar imágenes hace falta chafa; consulte docs/plugins.md", vim.log.levels.WARN)
    return
  end
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" or stat.size > 1024 * 1024 * 10 then
    vim.notify("Archivo inaccesible o mayor de 10 MB", vim.log.levels.WARN)
    return
  end

  local tree_win = vim.api.nvim_get_current_win()
  vim.cmd("rightbelow vsplit")
  preview_win = vim.api.nvim_get_current_win()
  preview_tree = tree_buf
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(preview_win, buf)
  vim.bo[buf].bufhidden = "wipe"
  vim.wo[preview_win].number = false
  vim.wo[preview_win].relativenumber = false
  vim.wo[preview_win].signcolumn = "no"
  if is_image then
    local size = math.max(1, vim.api.nvim_win_get_width(preview_win) - 2) .. "x" .. math.max(1, vim.api.nvim_win_get_height(preview_win) - 2)
    vim.fn.termopen({ "chafa", "--format=symbols", "--animate=off", "--size=" .. size, "--", path })
  else
    local ok, lines = pcall(vim.fn.readfile, path, "", 500)
    if not ok or table.concat(lines):find("\0", 1, true) then
      lines = { "No se puede previsualizar este archivo como texto." }
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].filetype = vim.filetype.match({ filename = path }) or ""
  end
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = tree_buf,
    once = true,
    callback = function()
      if preview_tree == tree_buf then close() end
    end,
  })
  if vim.api.nvim_win_is_valid(tree_win) then vim.api.nvim_set_current_win(tree_win) end
end

return M
