local function normalizar(texto)
  return vim.trim(texto)
end

local resultado = normalizar(" hola ")
print(resultado)
print(resultado)

local desconocido = global_inexistente
print(desconocido)
