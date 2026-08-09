local M = {}

local max_bytes = 32768

local function notify_error(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "Contexto de agente" })
end

local function is_sensitive(path)
  local normalized = path:gsub("\\", "/"):lower()
  local basename = vim.fs.basename(normalized)

  if basename == ".env" or basename:match("^%.env%.") then
    return true
  end

  local sensitive_names = {
    [".netrc"] = true,
    [".npmrc"] = true,
    [".pypirc"] = true,
    ["credentials"] = true,
    ["credentials.json"] = true,
    ["id_dsa"] = true,
    ["id_ecdsa"] = true,
    ["id_ed25519"] = true,
    ["id_rsa"] = true,
  }
  if sensitive_names[basename] then
    return true
  end

  for component in normalized:gmatch("[^/]+") do
    if component == ".ssh"
      or component == ".gnupg"
      or component == ".password-store"
      or component == "keyrings"
    then
      return true
    end
  end

  return false
end

local function ordered_positions(first, last)
  if first[2] < last[2] or (first[2] == last[2] and first[3] <= last[3]) then
    return first, last
  end
  return last, first
end

local function capture_context(visual)
  local buffer = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(buffer)
  if path == "" then
    return nil, "el buffer actual no tiene archivo"
  end
  if is_sensitive(path) then
    return nil, "se ha bloqueado el envio de un archivo potencialmente sensible"
  end

  local project = vim.fs.root(buffer, { ".git" }) or vim.fs.dirname(path)
  local relative = vim.fs.relpath(project, path) or path
  local context = {
    project = project,
    file = relative,
  }

  if visual then
    local selection_type = vim.fn.mode()
    local first, last = ordered_positions(vim.fn.getpos("v"), vim.fn.getpos("."))
    context.range = {
      start = { line = first[2], column = first[3] },
      ["end"] = { line = last[2], column = last[3] },
      selection_type = selection_type,
    }
    context.selection = table.concat(vim.fn.getregion(first, last, { type = selection_type }), "\n")
  else
    local cursor = vim.api.nvim_win_get_cursor(0)
    context.position = { line = cursor[1], column = cursor[2] + 1 }
  end

  return context
end

local function write_private_payload(payload)
  local directory = vim.fs.joinpath(vim.fn.stdpath("run"), "agent-context")
  vim.fn.mkdir(directory, "p")
  vim.uv.fs_chmod(directory, 448)

  local path = vim.fs.joinpath(directory, string.format("context-%d-%d.json", vim.fn.getpid(), vim.uv.hrtime()))
  local file, open_error = vim.uv.fs_open(path, "wx", 384)
  if not file then
    return nil, open_error
  end

  local written, write_error = vim.uv.fs_write(file, payload, 0)
  vim.uv.fs_close(file)
  if not written or written ~= #payload then
    vim.uv.fs_unlink(path)
    return nil, write_error or "escritura incompleta"
  end

  return path
end

local function transport_path()
  local configured = vim.env.ENTORNO_NVIM_AGENT_TRANSPORT
  if configured and configured ~= "" then
    return configured
  end

  local root = require("config.paths").repository()
  return vim.fs.joinpath(root, "scripts", "enviar-contexto-agente.sh")
end

function M.send(options)
  options = options or {}
  local context, capture_error = capture_context(options.visual == true)
  if not context then
    notify_error(capture_error)
    return
  end

  vim.ui.input({ prompt = "Agente: " }, function(prompt)
    if prompt == nil then
      return
    end

    context.prompt = prompt
    local payload = "Contexto para agente (JSON): " .. vim.json.encode(context)
    if #payload > max_bytes then
      notify_error(string.format("el contexto supera el limite de %d bytes", max_bytes))
      return
    end

    local path, write_error = write_private_payload(payload)
    if not path then
      notify_error("no se pudo crear el contexto temporal: " .. tostring(write_error))
      return
    end

    local transport = transport_path()
    if not transport or vim.fn.executable(transport) ~= 1 then
      notify_error("no se encontro el transporte; el contexto se conserva en " .. path)
      return
    end

    vim.system({ transport, path }, { text = true }, function(result)
      vim.schedule(function()
        if result.code == 0 then
          vim.notify(vim.trim(result.stdout), vim.log.levels.INFO, { title = "Contexto de agente" })
        else
          local message = vim.trim(result.stderr)
          notify_error((message ~= "" and message or "fallo el transporte") .. "; contexto: " .. path)
        end
      end)
    end)
  end)
end

return M
