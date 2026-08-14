local root = vim.env.ENTORNO_NVIM_ROOT
local socket = "entorno-nvim-context-" .. vim.fn.getpid()
local runtime_context = vim.fs.joinpath(vim.fn.stdpath("run"), "agent-context")
local original = {
  allowed = vim.env.ENTORNO_AGENT_ALLOWED_COMMANDS,
  input = vim.ui.input,
  max_bytes = vim.env.ENTORNO_AGENT_CONTEXT_MAX_BYTES,
  notify = vim.notify,
  override_marker = vim.env.ENTORNO_OVERRIDE_MARKER,
  socket = vim.env.ENTORNO_TMUX_SOCKET,
  tmux = vim.env.TMUX,
  tmux_pane = vim.env.TMUX_PANE,
  transport = vim.env.ENTORNO_NVIM_AGENT_TRANSPORT,
}

local function tmux(arguments)
  local command = { "tmux", "-L", socket }
  vim.list_extend(command, arguments)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout)
end

local function wait_for(pattern, pane)
  return vim.wait(10000, function()
    local content = tmux({ "capture-pane", "-p", "-J", "-S", "-", "-t", pane })
    return content:find(pattern, 1, true) ~= nil
  end, 20)
end

local function wait_for_process(process, pane)
  return vim.wait(10000, function()
    return tmux({ "display-message", "-p", "-t", pane, "#{pane_current_command}" }) == process
  end, 20)
end

local function context_files()
  if not vim.uv.fs_stat(runtime_context) then
    return {}
  end
  return vim.fn.glob(vim.fs.joinpath(runtime_context, "context-*.json"), false, true)
end

local function clear_context_files()
  for _, path in ipairs(context_files()) do
    vim.uv.fs_unlink(path)
  end
end

local function set_prompt(prompt)
  vim.ui.input = function(_, callback)
    callback(prompt)
  end
end

local function run()
  local agent_context = require("config.agent_context")
  local normal_mapping = vim.fn.maparg("<leader>ac", "n", false, true)
  local visual_mapping = vim.fn.maparg("<leader>ac", "x", false, true)
  assert(normal_mapping.desc == "Enviar contexto al agente", "leader+ac normal no esta configurado")
  assert(visual_mapping.desc == "Enviar contexto al agente", "leader+ac visual no esta configurado")
  assert(type(normal_mapping.callback) == "function", "leader+ac normal no usa callback")
  assert(type(visual_mapping.callback) == "function", "leader+ac visual no usa callback")
  assert(vim.tbl_isempty(vim.fn.maparg("ac", "n", false, true)), "ac no debe ser un mapping global")

  clear_context_files()
  tmux({ "-f", root .. "/tmux/tmux.conf", "new-session", "-d", "-x", "240", "-y", "60", "-s", "context", "-c", root })
  local editor_pane = tmux({ "display-message", "-p", "-t", "context:1.1", "#{pane_id}" })
  local agent_pane = tmux({
    "split-window",
    "-h",
    "-t",
    editor_pane,
    "-c",
    root,
    "-P",
    "-F",
    "#{pane_id}",
    "cat",
  })
  tmux({ "set-option", "-p", "-t", agent_pane, "@entorno_role", "agent" })
  tmux({ "set-option", "-p", "-t", agent_pane, "@entorno_agent_command", "codex" })
  tmux({ "set-option", "-p", "-t", agent_pane, "@entorno_agent_process", "cat" })

  vim.env.TMUX = "test"
  vim.env.TMUX_PANE = editor_pane
  vim.env.ENTORNO_TMUX_SOCKET = socket
  vim.env.ENTORNO_AGENT_CONTEXT_MAX_BYTES = nil

  if not wait_for_process("cat", agent_pane) then
    local process = tmux({ "display-message", "-p", "-t", agent_pane, "#{pane_current_command}" })
    local output = tmux({ "capture-pane", "-p", "-t", agent_pane })
    error("el agente permitido de prueba no arranco (" .. process .. "): " .. output)
  end

  local notifications = {}
  vim.notify = function(message, level)
    notifications[#notifications + 1] = { message = message, level = level }
  end

  local fixture = root .. "/tests/fixtures/agent-context/ejemplo.lua"
  vim.cmd("edit " .. vim.fn.fnameescape(fixture))
  vim.api.nvim_win_set_cursor(0, { 2, 6 })

  local sentinel_subshell = vim.fs.joinpath(vim.fn.stdpath("run"), "contexto-no-ejecutado-subshell")
  local sentinel_backtick = vim.fs.joinpath(vim.fn.stdpath("run"), "contexto-no-ejecutado-backtick")
  vim.uv.fs_unlink(sentinel_subshell)
  vim.uv.fs_unlink(sentinel_backtick)
  local special_prompt = string.format(
    "NORMAL $(touch %s) `touch %s` \"comillas\"\nsalto Unicode á🚀",
    sentinel_subshell,
    sentinel_backtick
  )
  set_prompt(special_prompt)
  agent_context.send({ visual = false })
  assert(wait_for('"prompt":"NORMAL $(touch', agent_pane), "el contexto normal no llego al agente")
  assert(not vim.uv.fs_stat(sentinel_subshell), "el contexto ejecuto una sustitucion de comando")
  assert(not vim.uv.fs_stat(sentinel_backtick), "el contexto ejecuto backticks")
  local normal_capture = tmux({ "capture-pane", "-p", "-J", "-S", "-", "-t", agent_pane })
  assert(normal_capture:find('\\n' .. "salto Unicode á🚀", 1, true), "el salto o Unicode no llego codificado")
  assert(normal_capture:find('"project":"' .. root .. '"', 1, true), "falta el proyecto")
  assert(normal_capture:find('"file":"tests/fixtures/agent-context/ejemplo.lua"', 1, true), "falta el archivo")
  assert(normal_capture:find('"position":', 1, true), "falta la posicion")
  assert(not normal_capture:find('"selection":', 1, true), "el modo normal incluyo contenido")
  assert(#context_files() == 0, "quedo un temporal tras enviar contexto normal")
  assert(vim.fn.getfperm(runtime_context) == "rwx------", "el directorio de contexto no tiene permisos 0700")
  tmux({ "send-keys", "-t", agent_pane, "Enter" })

  vim.api.nvim_win_set_cursor(0, { 1, 6 })
  vim.cmd("normal! vj$")
  set_prompt("VISUAL_CARACTER")
  agent_context.send({ visual = true })
  assert(wait_for('"prompt":"VISUAL_CARACTER"', agent_pane), "no llego la seleccion por caracteres")
  local character_capture = tmux({ "capture-pane", "-p", "-J", "-S", "-", "-t", agent_pane })
  assert(character_capture:find('"range":', 1, true), "falta el rango visual")
  assert(character_capture:find('"selection":', 1, true), "falta la seleccion visual")
  tmux({ "send-keys", "-t", agent_pane, "Enter" })
  vim.cmd("normal! \27")

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal! Vj")
  set_prompt("VISUAL_LINEAS")
  agent_context.send({ visual = true })
  assert(wait_for('"prompt":"VISUAL_LINEAS"', agent_pane), "no llego la seleccion por lineas")
  local line_capture = tmux({ "capture-pane", "-p", "-J", "-S", "-", "-t", agent_pane })
  assert(line_capture:find('local saludo = \\"hola\\"\\nlocal destino', 1, true), "seleccion por lineas incorrecta")
  tmux({ "send-keys", "-t", agent_pane, "Enter" })
  vim.cmd("normal! \27")

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.cmd("normal! \22jjlll")
  set_prompt("VISUAL_BLOQUE")
  agent_context.send({ visual = true })
  assert(wait_for('"prompt":"VISUAL_BLOQUE"', agent_pane), "no llego la seleccion en bloque")
  local block_capture = tmux({ "capture-pane", "-p", "-J", "-S", "-", "-t", agent_pane })
  assert(block_capture:find('loca\\nloca\\nprin', 1, true), "seleccion en bloque incorrecta")
  vim.cmd("normal! \27")
  assert(#context_files() == 0, "quedo un temporal tras las selecciones visuales")

  notifications = {}
  vim.env.ENTORNO_AGENT_CONTEXT_MAX_BYTES = "80"
  set_prompt(string.rep("x", 200))
  agent_context.send({ visual = false })
  assert(vim.wait(1000, function()
    return vim.iter(notifications):any(function(item)
      return item.message:find("limite de 80 bytes", 1, true) ~= nil
    end)
  end, 20), "Lua no respeto el override de tamano")
  assert(#context_files() == 0, "el payload demasiado grande creo un temporal")

  local override_script = vim.fs.joinpath(vim.fn.stdpath("run"), "transport-override.sh")
  local override_marker = vim.fs.joinpath(vim.fn.stdpath("run"), "transport-override.txt")
  vim.fn.writefile({
    "#!/bin/sh",
    "printf '%s|%s\\n' \"$ENTORNO_AGENT_CONTEXT_MAX_BYTES\" "
      .. "\"$ENTORNO_AGENT_CONTEXT_DIR\" > \"$ENTORNO_OVERRIDE_MARKER\"",
    "rm -f \"$1\"",
  }, override_script)
  vim.uv.fs_chmod(override_script, 448)
  vim.env.ENTORNO_NVIM_AGENT_TRANSPORT = override_script
  vim.env.ENTORNO_OVERRIDE_MARKER = override_marker
  vim.env.ENTORNO_AGENT_CONTEXT_MAX_BYTES = "4096"
  set_prompt("TRANSPORTE_OVERRIDE")
  agent_context.send({ visual = false })
  assert(vim.wait(5000, function()
    return vim.uv.fs_stat(override_marker) ~= nil
  end, 20), "no se ejecuto ENTORNO_NVIM_AGENT_TRANSPORT")
  local override_result = vim.fn.readfile(override_marker)[1]
  assert(override_result == "4096|" .. runtime_context, "Lua y transporte no recibieron el mismo limite o directorio")
  vim.env.ENTORNO_NVIM_AGENT_TRANSPORT = nil
  vim.env.ENTORNO_OVERRIDE_MARKER = nil
  vim.env.ENTORNO_AGENT_CONTEXT_MAX_BYTES = nil
  vim.uv.fs_unlink(override_script)
  vim.uv.fs_unlink(override_marker)

  vim.fn.mkdir(runtime_context, "p")
  local old_context = vim.fs.joinpath(runtime_context, "context-999-111.json")
  local recent_context = vim.fs.joinpath(runtime_context, "context-999-222.json")
  local linked_context = vim.fs.joinpath(runtime_context, "context-999-333.json")
  local foreign_file = vim.fs.joinpath(runtime_context, "archivo-ajeno.json")
  for _, path in ipairs({ old_context, recent_context, linked_context, foreign_file }) do
    vim.uv.fs_unlink(path)
  end
  vim.fn.writefile({ "antiguo" }, old_context)
  vim.fn.writefile({ "reciente" }, recent_context)
  vim.fn.writefile({ "ajeno" }, foreign_file)
  local old_time = os.time() - (25 * 60 * 60)
  vim.uv.fs_utime(old_context, old_time, old_time)
  vim.uv.fs_utime(foreign_file, old_time, old_time)
  assert(vim.uv.fs_symlink(recent_context, linked_context), "no se pudo crear el symlink de prueba")

  vim.cmd("enew")
  vim.api.nvim_buf_set_name(0, vim.fs.joinpath(vim.fn.stdpath("run"), ".env"))
  local prompted = false
  vim.ui.input = function()
    prompted = true
  end
  agent_context.send({ visual = false })
  assert(not prompted, "un archivo .env no debe llegar al prompt")
  assert(not vim.uv.fs_lstat(old_context), "no se purgo el contexto regular de mas de 24 horas")
  assert(vim.uv.fs_lstat(recent_context), "se purgo un contexto reciente")
  assert(vim.uv.fs_lstat(linked_context), "la purga siguio o elimino un symlink")
  assert(vim.uv.fs_lstat(foreign_file), "la purga elimino un archivo ajeno")

  for _, relative in ipairs({
    ".git-credentials",
    "certificado.pem",
    "privada.key",
    "certificado.p12",
    ".kube/config",
    ".docker/config.json",
    ".pgpass",
    ".my.cnf",
    ".s3cfg",
    ".netrc",
    ".npmrc",
    ".pypirc",
    ".env.local",
    ".ssh/id_rsa",
    ".gnupg/secring.gpg",
    ".password-store/correo.gpg",
  }) do
    vim.cmd("enew")
    vim.api.nvim_buf_set_name(0, vim.fs.joinpath(vim.fn.stdpath("run"), "sensible", relative))
    prompted = false
    agent_context.send({ visual = false })
    assert(not prompted, "un archivo sensible llego al prompt: " .. relative)
  end

  for _, path in ipairs({ recent_context, linked_context, foreign_file }) do
    vim.uv.fs_unlink(path)
  end

  tmux({ "set-option", "-p", "-u", "-t", agent_pane, "@entorno_role" })
  vim.cmd("edit " .. vim.fn.fnameescape(fixture))
  notifications = {}
  set_prompt("SIN_PANEL")
  agent_context.send({ visual = false })
  assert(vim.wait(5000, function()
    return vim.iter(notifications):any(function(item)
      return item.message:find("se esperaba un panel con rol agent", 1, true) ~= nil
    end)
  end, 20), "no se notifico claramente la ausencia del panel agent")
  local preserved = context_files()
  assert(#preserved == 1, "el contexto no se conservo tras el error de transporte")
  assert(vim.fn.getfperm(preserved[1]) == "rw-------", "el contexto conservado no tiene permisos 0600")
  vim.uv.fs_unlink(preserved[1])
end

local ok, error_message = xpcall(run, debug.traceback)
pcall(tmux, { "kill-server" })
clear_context_files()
vim.ui.input = original.input
vim.notify = original.notify
vim.env.ENTORNO_AGENT_ALLOWED_COMMANDS = original.allowed
vim.env.ENTORNO_AGENT_CONTEXT_MAX_BYTES = original.max_bytes
vim.env.ENTORNO_OVERRIDE_MARKER = original.override_marker
vim.env.ENTORNO_NVIM_AGENT_TRANSPORT = original.transport
vim.env.ENTORNO_TMUX_SOCKET = original.socket
vim.env.TMUX = original.tmux
vim.env.TMUX_PANE = original.tmux_pane
if not ok then
  error(error_message)
end
