-- Interruptor unico de iconos del entorno.
--
-- Prioridad, de mayor a menor:
--   1. variable ENTORNO_ICONOS=0 (solo para la sesion actual)
--   2. archivo .xdg/iconos, escrito por :EntornoIconos y persistente
--   3. activados, que es el comportamiento historico
--
-- Nada de esto instala fuentes ni toca archivos fuera del repositorio: solo
-- decide si se escriben glifos de Nerd Font o texto corriente.
local M = {}

local ARCHIVO = "iconos"
local cache

local function ruta()
  return vim.fs.joinpath(require("config.paths").repository(), ".xdg", ARCHIVO)
end

local function desde_entorno()
  local valor = vim.env.ENTORNO_ICONOS
  if valor == nil or valor == "" then
    return nil
  end
  return valor ~= "0"
end

local function desde_archivo()
  local archivo = ruta()
  if vim.fn.filereadable(archivo) ~= 1 then
    return nil
  end

  local lineas = vim.fn.readfile(archivo)
  local valor = vim.trim(lineas[1] or "")
  if valor == "1" or valor == "si" then
    return true
  end
  if valor == "0" or valor == "no" then
    return false
  end
  return nil
end

--- Indica si deben mostrarse iconos. Es barato: se resuelve una vez por sesion.
function M.activos()
  if cache ~= nil then
    return cache
  end

  local activos = desde_entorno()
  if activos == nil then
    activos = desde_archivo()
  end
  if activos == nil then
    activos = true
  end

  cache = activos
  return activos
end

--- Devuelve el glifo de Nerd Font o, si los iconos estan desactivados, el texto.
function M.elegir(nerd, texto)
  return M.activos() and nerd or texto
end

--- True si la variable de entorno manda sobre la eleccion guardada.
function M.entorno_manda()
  return desde_entorno() ~= nil
end

local function redibujar()
  pcall(function()
    require("config.explorer").aplicar()
  end)
  pcall(function()
    require("config.dashboard").refresh()
  end)
  pcall(vim.cmd.redrawstatus)
end

--- Guarda la eleccion en .xdg/iconos y la aplica sin reiniciar el editor.
function M.fijar(activos)
  local archivo = ruta()
  vim.fn.mkdir(vim.fs.dirname(archivo), "p")
  local resultado = vim.fn.writefile({ activos and "1" or "0" }, archivo)
  if resultado ~= 0 then
    vim.notify("No se pudo guardar la eleccion de iconos en " .. archivo, vim.log.levels.ERROR)
    return false
  end

  cache = activos
  redibujar()
  return true
end

local function ejemplo()
  if M.activos() then
    return "  󰈔   󰉋      "
  end
  return "  [txt]  [dir]  lua  ts"
end

--- Explica el estado, con una muestra de glifos para comprobar la terminal.
function M.mostrar()
  local lineas
  if M.activos() then
    lineas = {
      "Iconos activados.",
      "",
      "  Muestra: " .. ejemplo(),
      "",
      "Si ve cuadros, huecos o simbolos raros en lugar de la muestra, su terminal",
      "no tiene una Nerd Font: escriba :EntornoIconos 0 para pasar a texto.",
    }
  else
    lineas = {
      "Iconos desactivados: todo en texto, sin fuentes especiales.",
      "",
      "  Muestra: " .. ejemplo(),
      "",
      "Puede activarlos con :EntornoIconos 1 si su terminal tiene Nerd Font.",
    }
  end

  if M.entorno_manda() then
    table.insert(lineas, "")
    table.insert(lineas, "Aviso: ENTORNO_ICONOS esta definida en esta sesion y tiene prioridad.")
    table.insert(lineas, "Para que la eleccion se guarde, abra el entorno sin esa variable.")
  end

  vim.api.nvim_echo({ { table.concat(lineas, "\n") } }, true, {})
end

local function plataforma_wsl()
  if (vim.env.WSL_DISTRO_NAME or "") ~= "" then
    return true
  end
  local version = vim.uv.fs_stat("/proc/version")
  if not version then
    return false
  end
  local ok, lineas = pcall(vim.fn.readfile, "/proc/version")
  return ok and #lineas > 0 and lineas[1]:lower():find("microsoft", 1, true) ~= nil
end

-- Aviso unico, solo cuando no hay eleccion previa y la plataforma lo justifica.
-- No cambia nada: informa de que el comando existe.
local function avisar_una_vez()
  -- Sin interfaz (por ejemplo, las comprobaciones del instalador) no hay aviso
  -- que mostrar: no debe consumirse la marca antes del primer arranque real.
  if #vim.api.nvim_list_uis() == 0 then
    return
  end

  local marca = vim.fs.joinpath(require("config.paths").repository(), ".xdg", "aviso-iconos")
  if vim.fn.filereadable(marca) == 1 then
    return
  end

  vim.fn.mkdir(vim.fs.dirname(marca), "p")
  pcall(vim.fn.writefile, { os.date("%Y-%m-%d") }, marca)

  if desde_archivo() ~= nil or M.entorno_manda() then
    return
  end
  if not plataforma_wsl() then
    return
  end

  vim.schedule(function()
    vim.notify(
      "Si ve cuadros en vez de iconos, su terminal no tiene Nerd Font.\nEscriba :EntornoIconos y mantenga los iconos o pase a texto.",
      vim.log.levels.INFO
    )
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("EntornoIconos", function(arguments)
    local argumento = vim.trim(arguments.args or "")
    local deseado

    if argumento == "" then
      deseado = not M.activos()
    elseif argumento == "1" or argumento == "si" then
      deseado = true
    elseif argumento == "0" or argumento == "no" then
      deseado = false
    else
      vim.notify("Uso: :EntornoIconos [0|1]", vim.log.levels.ERROR)
      return
    end

    if not M.fijar(deseado) then
      return
    end
    M.mostrar()
  end, {
    nargs = "?",
    complete = function()
      return { "0", "1" }
    end,
    desc = "Activar o desactivar los iconos y guardar la eleccion",
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("entorno_nvim_iconos", { clear = true }),
    callback = avisar_una_vez,
  })
end

return M
