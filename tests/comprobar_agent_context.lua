local root = vim.env.ENTORNO_NVIM_ROOT
local socket = "entorno-nvim-context-" .. vim.fn.getpid()
local runtime_context = vim.fs.joinpath(vim.fn.stdpath("run"), "agent-context")
local original = {
  input = vim.ui.input,
  notify = vim.notify,
  tmux = vim.env.TMUX,
  tmux_pane = vim.env.TMUX_PANE,
  socket = vim.env.ENTORNO_TMUX_SOCKET,
}

local function tmux(arguments)
  local command = { "tmux", "-L", socket }
  vim.list_extend(command, arguments)
  local result = vim.system(command, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout)
end

local function wait_for(pattern, pane)
  return vim.wait(5000, function()
    local content = tmux({ "capture-pane", "-p", "-J", "-t", pane })
    return content:find(pattern, 1, true) ~= nil
  end, 20)
end

local function context_files()
  if not vim.uv.fs_stat(runtime_context) then
    return {}
  end
  return vim.fn.glob(vim.fs.joinpath(runtime_context, "context-*.json"), false, true)
end

local function run()
  local normal_mapping = vim.fn.maparg("<leader>ac", "n", false, true)
  local visual_mapping = vim.fn.maparg("<leader>ac", "x", false, true)
  assert(normal_mapping.desc == "Enviar contexto al agente", "leader+ac normal no esta configurado")
  assert(visual_mapping.desc == "Enviar contexto al agente", "leader+ac visual no esta configurado")
  assert(type(normal_mapping.callback) == "function", "leader+ac normal no usa callback")
  assert(type(visual_mapping.callback) == "function", "leader+ac visual no usa callback")
  assert(vim.tbl_isempty(vim.fn.maparg("ac", "n", false, true)), "ac no debe ser un mapping global")

  tmux({ "-f", root .. "/tmux/tmux.conf", "new-session", "-d", "-x", "240", "-y", "60", "-s", "context", "-c", root })
  local editor_pane = tmux({ "display-message", "-p", "-t", "context:1.1", "#{pane_id}" })
  local agent_pane = tmux({ "split-window", "-h", "-t", editor_pane, "-c", root, "-P", "-F", "#{pane_id}" })
  tmux({ "set-option", "-p", "-t", agent_pane, "@entorno_role", "agent" })

  vim.env.TMUX = "test"
  vim.env.TMUX_PANE = editor_pane
  vim.env.ENTORNO_TMUX_SOCKET = socket

  local notifications = {}
  vim.notify = function(message, level)
    notifications[#notifications + 1] = { message = message, level = level }
  end

  local fixture = root .. "/tests/fixtures/agent-context/ejemplo.lua"
  vim.cmd("edit " .. vim.fn.fnameescape(fixture))
  vim.api.nvim_win_set_cursor(0, { 2, 6 })

  local sentinel = vim.fs.joinpath(vim.fn.stdpath("run"), "contexto-no-ejecutado")
  vim.uv.fs_unlink(sentinel)
  vim.ui.input = function(_, callback)
    callback("NORMAL $(touch " .. sentinel .. ")")
  end
  require("config.agent_context").send({ visual = false })
  assert(wait_for('"prompt":"NORMAL $(touch', agent_pane), "el contexto normal no llego al panel agent")
  assert(not vim.uv.fs_stat(sentinel), "el contexto normal envio Enter o ejecuto contenido")
  local normal_capture = tmux({ "capture-pane", "-p", "-J", "-t", agent_pane })
  assert(normal_capture:find('"project":"' .. root .. '"', 1, true), "el contexto normal no incluye el proyecto")
  assert(
    normal_capture:find('"file":"tests/fixtures/agent-context/ejemplo.lua"', 1, true),
    "el contexto normal no incluye el archivo"
  )
  assert(normal_capture:find('"position":', 1, true), "el contexto normal no incluye la posicion")
  assert(not normal_capture:find('"selection":', 1, true), "el contexto normal incluyo contenido")
  assert(#context_files() == 0, "quedo un temporal tras enviar contexto normal")
  tmux({ "send-keys", "-t", agent_pane, "C-c" })

  vim.api.nvim_win_set_cursor(0, { 1, 6 })
  vim.cmd("normal! vj$")
  vim.ui.input = function(_, callback)
    callback("VISUAL")
  end
  require("config.agent_context").send({ visual = true })
  assert(wait_for('"prompt":"VISUAL"', agent_pane), "el contexto visual no llego al panel agent")
  local visual_capture = tmux({ "capture-pane", "-p", "-J", "-t", agent_pane })
  assert(visual_capture:find('"range":', 1, true), "el contexto visual no incluye el rango")
  assert(visual_capture:find('"selection":', 1, true), "el contexto visual no incluye la seleccion")
  assert(visual_capture:find("saludo", 1, true), "el contexto visual no contiene el texto seleccionado")
  assert(#context_files() == 0, "quedo un temporal tras enviar contexto visual")
  tmux({ "send-keys", "-t", agent_pane, "C-c" })

  tmux({ "set-option", "-p", "-u", "-t", agent_pane, "@entorno_role" })
  vim.cmd("normal! \27")
  vim.ui.input = function(_, callback)
    callback("SIN PANEL")
  end
  require("config.agent_context").send({ visual = false })
  assert(vim.wait(5000, function()
    for _, item in ipairs(notifications) do
      if item.message:find("se esperaba un panel con rol agent", 1, true) then
        return true
      end
    end
    return false
  end, 20), "no se notifico claramente la ausencia del panel agent")
  assert(#context_files() == 1, "el contexto no se conservo al faltar el panel agent")
  vim.uv.fs_unlink(context_files()[1])

  vim.cmd("enew")
  vim.api.nvim_buf_set_name(0, vim.fs.joinpath(vim.fn.stdpath("run"), ".env"))
  local prompted = false
  vim.ui.input = function()
    prompted = true
  end
  require("config.agent_context").send({ visual = false })
  assert(not prompted, "un archivo .env no debe llegar al prompt ni al transporte")
end

local ok, error_message = xpcall(run, debug.traceback)
pcall(tmux, { "kill-server" })
vim.ui.input = original.input
vim.notify = original.notify
vim.env.TMUX = original.tmux
vim.env.TMUX_PANE = original.tmux_pane
vim.env.ENTORNO_TMUX_SOCKET = original.socket
if not ok then
  error(error_message)
end
