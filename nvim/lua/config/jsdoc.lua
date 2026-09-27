local M = {}

local function snippet_body(text)
  text = text:gsub("\\", "\\\\"):gsub("%$", "\\$")
  local index = 0
  local lines = vim.split(text:gsub("\n$", ""), "\n", { plain = true })
  for i, line in ipairs(lines) do
    if line:match("^%s*%*%s*$") or line:match("@param%s") or line:match("@returns?%s*$") then
      index = index + 1
      local description = index == 1 and "Descripción de la función" or "Descripción"
      lines[i] = line .. " ${" .. index .. ":" .. description .. "}"
    end
  end
  return table.concat(lines, "\n")
end

function M.generate(snippet)
  local buf = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local prefix_row = snippet and row or nil
  if snippet then row = row + 1 end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  while lines[row + 1] and lines[row + 1]:match("^%s*$") do row = row + 1 end
  local line = lines[row + 1]
  local client = vim.lsp.get_clients({ bufnr = buf, name = "ts_ls" })[1]
  if not client or not line then
    vim.notify("Documentación: abra un archivo JS/TS con su servidor activo.", vim.log.levels.WARN)
    return
  end
  local indent = line:match("^%s*")
  -- Un /** abierto oculta la funcion al analizador de TypeScript.
  local opener = snippet and snippet.enter and lines[prefix_row + 1] or nil
  if opener then
    vim.api.nvim_buf_set_lines(buf, prefix_row, prefix_row + 1, false, { indent })
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local function fallback()
    if opener then
      vim.api.nvim_buf_set_lines(buf, prefix_row, prefix_row + 1, false, { opener })
      vim.api.nvim_win_set_cursor(0, cursor)
      if vim.fn.mode():sub(1, 1) == "i" then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
      end
    end
  end
  client:request("workspace/executeCommand", {
    command = "typescript.tsserverRequest",
    arguments = {
      "docCommentTemplate",
      { file = vim.uri_from_bufnr(buf), line = row + 1, offset = #indent + 1 },
      { expectsResult = true },
    },
  }, function(err, response)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(buf) or vim.api.nvim_get_current_buf() ~= buf
        or vim.api.nvim_buf_get_changedtick(buf) ~= tick then return end
      local template = response and response.body
      if err or not template or not template.newText then
        fallback()
        vim.notify("Sitúe el cursor en la línea de una función sin documentación; "
          .. "docfn debe estar justo encima de ella.", vim.log.levels.WARN)
        return
      end
      local target = prefix_row or row
      local finish = prefix_row and prefix_row + 1 or target
      vim.api.nvim_buf_set_lines(buf, target, finish, false, { indent })
      vim.api.nvim_win_set_cursor(0, { target + 1, #indent })
      require("mini.snippets").default_insert({ body = snippet_body(template.newText) }, {
        empty_tabstop = "", empty_tabstop_final = "",
      })
    end)
  end, buf)
end

return M
