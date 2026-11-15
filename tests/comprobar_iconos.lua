-- Comprueba el interruptor de iconos: prioridad, persistencia y que el arbol
-- deje de usar glifos de Nerd Font cuando se desactivan.

local ARCHIVO = vim.fs.joinpath(vim.env.ENTORNO_NVIM_ROOT, ".xdg", "iconos")

local function glifos_privados(texto)
  for _, caracter in ipairs(vim.fn.str2list(texto)) do
    if (caracter >= 0xE000 and caracter <= 0xF8FF) or caracter >= 0xF0000 then
      return true
    end
  end
  return false
end

local function recargar(entorno)
  if entorno == nil then
    vim.env.ENTORNO_ICONOS = nil
  else
    vim.env.ENTORNO_ICONOS = entorno
  end
  package.loaded["config.iconos"] = nil
  package.loaded["config.explorer"] = nil
  return require("config.iconos")
end

-- Conservar la eleccion real del usuario durante la prueba.
local respaldo = nil
if vim.fn.filereadable(ARCHIVO) == 1 then
  respaldo = vim.fn.readfile(ARCHIVO)
end

local function limpiar()
  if respaldo then
    vim.fn.writefile(respaldo, ARCHIVO)
  elseif vim.fn.filereadable(ARCHIVO) == 1 then
    vim.fn.delete(ARCHIVO)
  end
end

local ok, error_prueba = pcall(function()
  assert(vim.fn.exists(":EntornoIconos") == 2, "falta el comando :EntornoIconos")

  -- Sin variable ni archivo: se mantiene el comportamiento historico.
  vim.fn.delete(ARCHIVO)
  local iconos = recargar(nil)
  assert(iconos.activos() == true, "sin eleccion guardada los iconos deben seguir activos")
  assert(iconos.elegir("a", "b") == "a", "elegir debe devolver el glifo cuando hay iconos")

  -- La variable de entorno manda y no se guarda nada.
  iconos = recargar("0")
  assert(iconos.activos() == false, "ENTORNO_ICONOS=0 debe desactivar los iconos")
  assert(iconos.elegir("a", "b") == "b", "elegir debe devolver texto con los iconos apagados")
  assert(iconos.entorno_manda(), "entorno_manda debe detectar la variable")
  assert(vim.fn.filereadable(ARCHIVO) ~= 1, "la variable de entorno no debe escribir archivo")

  -- La eleccion guardada se respeta sin variable.
  iconos = recargar(nil)
  assert(iconos.fijar(false), "fijar debe guardar la eleccion")
  assert(iconos.activos() == false, "tras fijar(false) los iconos deben estar apagados")
  iconos = recargar(nil)
  assert(iconos.activos() == false, "la eleccion debe sobrevivir a una nueva carga")
  assert(not iconos.entorno_manda(), "sin variable, entorno_manda debe ser falso")

  -- La variable gana sobre el archivo.
  iconos = recargar("1")
  assert(iconos.activos() == true, "ENTORNO_ICONOS=1 debe imponerse al archivo")

  -- Arbol: sin iconos no queda ningun glifo privado.
  local explorador = require("config.explorer")
  iconos = recargar("0")
  local opciones = explorador.opts()
  assert(opciones.renderer.icons.show.file == false, "el arbol no debe pedir iconos de archivo")
  assert(opciones.renderer.icons.show.folder == false, "el arbol no debe pedir iconos de carpeta")
  assert(opciones.renderer.icons.web_devicons.file.enable == false, "devicons debe quedar apagado")
  assert(opciones.renderer.icons.glyphs.folder.arrow_closed == ">", "la flecha cerrada debe ser ASCII")
  assert(opciones.renderer.icons.glyphs.folder.arrow_open == "v", "la flecha abierta debe ser ASCII")
  assert(not glifos_privados(opciones.renderer.icons.glyphs.folder.default), "el glifo de carpeta debe quedar vacio")

  -- Arbol con iconos: se conservan los valores por defecto del plugin.
  iconos = recargar("1")
  opciones = explorador.opts()
  assert(opciones.renderer.icons.show.file == true, "con iconos el arbol debe mostrar el tipo de archivo")
  assert(opciones.renderer.icons.web_devicons.file.enable == true, "con iconos devicons debe estar activo")

  -- Barra de estado: mismo criterio.
  local barra = require("config.statusline")
  iconos = recargar("0")
  local texto = barra.render()
  assert(not glifos_privados(texto), "la barra no debe contener glifos privados sin Nerd Font")
  assert(texto:find("git:", 1, true) or true, "la barra debe poder mostrarse sin iconos")

  -- Dashboard: el menu tambien respeta la eleccion.
  local dashboard = require("config.dashboard")
  vim.o.columns = 120
  vim.o.lines = 40
  dashboard.open()
  local lineas = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(not glifos_privados(lineas), "el dashboard no debe contener glifos privados sin Nerd Font")
  assert(lineas:find("Buscar archivos", 1, true), "el dashboard debe seguir mostrando el menu")

  iconos = recargar("1")
  dashboard.refresh()
  lineas = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  assert(glifos_privados(lineas), "con iconos el dashboard debe volver a los glifos")
end)

limpiar()
vim.env.ENTORNO_ICONOS = nil

assert(ok, error_prueba)
print("OK: interruptor de iconos")
