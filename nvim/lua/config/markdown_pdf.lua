local M = {}

local function notify(message, level)
  vim.notify(message, level, { title = "Markdown → PDF" })
end

local function script_path()
  return vim.fs.joinpath(require("config.paths").repository(), "scripts", "markdown-pdf.sh")
end

function M.export_current(output)
  local buffer = vim.api.nvim_get_current_buf()
  local input = vim.api.nvim_buf_get_name(buffer)

  if input == "" then
    notify("el buffer actual no tiene archivo", vim.log.levels.ERROR)
    return
  end
  if vim.bo[buffer].filetype ~= "markdown" then
    notify("el archivo actual no es Markdown", vim.log.levels.ERROR)
    return
  end

  local script = script_path()
  if vim.fn.executable(script) ~= 1 then
    notify("no se encuentra el exportador: " .. script, vim.log.levels.ERROR)
    return
  end

  if vim.bo[buffer].modified then
    vim.cmd.write()
  end

  local command = { script, input }
  if output and output ~= "" then
    table.insert(command, vim.fn.fnamemodify(output, ":p"))
  end

  notify("generando el PDF…", vim.log.levels.INFO)
  vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        notify(vim.trim(result.stdout), vim.log.levels.INFO)
      else
        local message = vim.trim(result.stderr)
        notify(message ~= "" and message or "falló la generación del PDF", vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("MarkdownPdf", function(arguments)
    M.export_current(arguments.args)
  end, {
    desc = "Generar el PDF del Markdown actual",
    nargs = "?",
    complete = "file",
  })
end

return M
