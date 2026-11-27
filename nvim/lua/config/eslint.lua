-- Diagnósticos ESLint nativos para proyectos JS/TS/React que incluyan
-- configuración y dependencia local de ESLint (por ejemplo, Vite + React + TS).
-- En proyectos sin ESLint permanece inactivo y sin avisos.
local M = {}

M.namespace = vim.api.nvim_create_namespace("entorno_eslint")
M.filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local config_names = {
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
  ".eslintrc",
  ".eslintrc.json",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yml",
  ".eslintrc.yaml",
}

local pending = {}

local function available(bufnr)
  return vim.api.nvim_buf_is_valid(bufnr)
    and vim.api.nvim_buf_is_loaded(bufnr)
    and M.filetypes[vim.bo[bufnr].filetype] == true
    and vim.bo[bufnr].buftype == ""
    and vim.api.nvim_buf_get_name(bufnr) ~= ""
end

local function cancel(bufnr)
  local old = pending[bufnr]
  pending[bufnr] = nil
  if old and old.process then
    pcall(function() old.process:kill(15) end)
  end
end

function M.find_project(path)
  local dir = vim.fs.dirname(path)
  local config = vim.fs.find(config_names, { path = dir, upward = true })[1]
  if not config then return nil, nil end
  local root = vim.fs.dirname(config)
  local bin = vim.fs.find("node_modules/.bin/eslint", { path = dir, upward = true })[1]
  if not bin or vim.fn.executable(bin) ~= 1 then return nil, nil end
  return root, bin
end

local function to_diagnostics(items)
  local diagnostics = {}
  local file_result = type(items) == "table" and items[1] or nil
  local messages = file_result and file_result.messages or nil
  if type(messages) ~= "table" then return diagnostics end

  for _, msg in ipairs(messages) do
    if type(msg) == "table" and type(msg.message) == "string" then
      local lnum = math.max((tonumber(msg.line) or 1) - 1, 0)
      local col = math.max((tonumber(msg.column) or 1) - 1, 0)
      local end_lnum = msg.endLine and math.max(tonumber(msg.endLine) - 1, lnum) or lnum
      local end_col = msg.endColumn and math.max(tonumber(msg.endColumn) - 1, col) or col
      diagnostics[#diagnostics + 1] = {
        lnum = lnum,
        col = col,
        end_lnum = end_lnum,
        end_col = end_col,
        message = msg.message,
        code = type(msg.ruleId) == "string" and msg.ruleId or nil,
        source = "eslint",
        severity = msg.severity == 2 and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
      }
    end
  end
  return diagnostics
end

function M.lint(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  cancel(bufnr)
  if not available(bufnr) then
    vim.diagnostic.reset(M.namespace, bufnr)
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local root, bin = M.find_project(path)
  if not root or not bin then
    vim.diagnostic.reset(M.namespace, bufnr)
    return
  end

  local state = {}
  pending[bufnr] = state
  vim.defer_fn(function()
    if pending[bufnr] ~= state or not available(bufnr) then return end
    local tick = vim.api.nvim_buf_get_changedtick(bufnr)
    local text = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
    state.process = vim.system(
      { bin, "--stdin", "--stdin-filename", path, "--format", "json" },
      { stdin = text, cwd = root, text = true, timeout = 8000 },
      vim.schedule_wrap(function(result)
        if pending[bufnr] ~= state or not available(bufnr)
          or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick then
          return
        end
        pending[bufnr] = nil
        -- ESLint devuelve 0 (limpio) o 1 (hay avisos/errores con JSON en stdout).
        if result.code ~= 0 and result.code ~= 1 then
          vim.diagnostic.reset(M.namespace, bufnr)
          return
        end
        local ok, decoded = pcall(vim.json.decode, result.stdout or "")
        if not ok or type(decoded) ~= "table" then
          vim.diagnostic.reset(M.namespace, bufnr)
          return
        end
        vim.diagnostic.set(M.namespace, bufnr, to_diagnostics(decoded))
      end)
    )
  end, 500)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("entorno_eslint", { clear = true })
  vim.api.nvim_create_autocmd({ "FileType", "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = group,
    callback = function(event)
      if M.filetypes[vim.bo[event.buf].filetype] or pending[event.buf] or event.event == "FileType" then
        M.lint(event.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = group,
    callback = function(event) cancel(event.buf) end,
  })
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if available(bufnr) then M.lint(bufnr) end
  end
end

return M
