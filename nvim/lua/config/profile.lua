local M = { missing = {} }

local profiles = {
  inicial = { web = true, diagnostics = false },
  dwec = { web = true, diagnostics = true },
  si = { bash = true, python = true, diagnostics = true },
  profesor = { web = true, python = true, lua = true, pdf = true, diagnostics = true },
}

-- El entorno personal conserva sus funciones; los perfiles docentes son optativos.
M.name = vim.env.ENTORNO_PERFIL or "profesor"
assert(profiles[M.name], "Perfil desconocido: " .. M.name)
M.modules = vim.deepcopy(profiles[M.name])
M.modules.ai = vim.env.ENTORNO_IA == "1"
  or (vim.env.ENTORNO_IA == nil and M.name == "profesor")

function M.has(module)
  return M.modules[module] == true
end

function M.unavailable(component, instruction)
  M.missing[component] = instruction
end

function M.info()
  local lines = { "Perfil: " .. M.name, "IA: " .. (M.has("ai") and "habilitada" or "desactivada") }
  local modules = {}
  for name, enabled in pairs(M.modules) do
    if enabled then
      modules[#modules + 1] = name
    end
  end
  table.sort(modules)
  lines[#lines + 1] = "Modulos: " .. table.concat(modules, ", ")
  for _, component in ipairs(vim.fn.sort(vim.tbl_keys(M.missing))) do
    lines[#lines + 1] = component .. ": " .. M.missing[component]
  end
  if M.name == "si" then
    lines[#lines + 1] = "Zsh, Docker y Kubernetes: integraciones avanzadas pendientes."
  end
  return lines
end

function M.setup()
  vim.api.nvim_create_user_command("EntornoInfo", function()
    vim.notify(table.concat(M.info(), "\n"), vim.log.levels.INFO, { title = "Entorno docente" })
  end, { desc = "Mostrar perfil y funciones pendientes de preparar" })
end

return M
