local M = {}
local active_previews = {}

local function notify(message, level)
  vim.notify(message, level, { title = "Markdown → PDF" })
end

local function script_path()
  return vim.fs.joinpath(require("config.paths").repository(), "scripts", "markdown-pdf.sh")
end

local function viewer_path()
  return vim.fs.joinpath(require("config.paths").repository(), "scripts", "abrir-pdf.sh")
end

local function generated_path(input, output)
  if output and output ~= "" then
    return vim.fn.fnamemodify(output, ":p")
  end
  return vim.fn.fnamemodify(input, ":r") .. ".pdf"
end

local function preview(pdf)
  if active_previews[pdf] then
    notify("PDF actualizado; el proceso del visor continúa abierto", vim.log.levels.INFO)
    return
  end

  local viewer = viewer_path()
  if vim.fn.executable(viewer) ~= 1 then
    notify("no se encuentra el lanzador del visor: " .. viewer, vim.log.levels.ERROR)
    return
  end

  active_previews[pdf] = true
  vim.system({ viewer, pdf }, { text = true, env = require("config.process").desktop_env() }, function(result)
    active_previews[pdf] = nil
    if result.code ~= 0 then
      vim.schedule(function()
        local message = vim.trim(result.stderr)
        notify(message ~= "" and message or "no se pudo abrir el PDF", vim.log.levels.ERROR)
      end)
    end
  end)
end

function M.export_current(output, options)
  options = options or {}
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
  local pdf = generated_path(input, output)
  if output and output ~= "" then
    table.insert(command, pdf)
  end

  notify("generando el PDF…", vim.log.levels.INFO)
  vim.system(command, { text = true }, function(result)
    vim.schedule(function()
      if result.code == 0 then
        notify(vim.trim(result.stdout), vim.log.levels.INFO)
        if options.preview then
          preview(pdf)
        end
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
