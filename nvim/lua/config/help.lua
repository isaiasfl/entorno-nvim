local M = {}
function M.setup()
  local function open()
    local lines = {
      "AYUDA RÁPIDA — modo normal salvo indicación",
      "",
      "Esc        Volver a modo normal",
      "jk rápido  También sale de insertar (sin pausa entre letras)",
      "i / a      Insertar antes / después del cursor",
      "o / O      Nueva línea debajo / encima y empezar a escribir",
      "u / Ctrl+r Deshacer / rehacer",
      "",
      "MOVIMIENTO: h ←    j ↓    k ↑    l →",
      "w / b      Inicio de palabra siguiente / anterior",
      "e          Final de palabra",
      "0 / ^ / $  Inicio de línea / primer texto / final",
      "f) / t)    Ir al siguiente ) / quedarse justo antes",
      "; / ,      Repetir búsqueda f/t / repetir al revés",
      "%          Saltar al paréntesis o llave correspondiente",
      "gg / G     Inicio / final del archivo",
      "",
      "PALABRAS: cursor en cualquier letra",
      "viw        Seleccionar palabra (v = selección visual)",
      "ciw        Cambiar palabra y escribir (c = change)",
      "diw        Borrar palabra (d = delete)",
      "* / n      Buscar palabra / siguiente coincidencia",
      "cgn / .    Cambiar coincidencia / repetir en siguiente",
      "",
      "BLOQUES: cursor dentro de las llaves",
      "vi{        Seleccionar contenido entre llaves",
      "ci{        Cambiar contenido; conserva las llaves",
      "di{        Borrar contenido; conserva las llaves",
      "va{ / da{  Seleccionar / borrar incluyendo llaves",
      "           La declaración de función queda fuera.",
      "V          Seleccionar líneas; j/k amplían selección",
      "d / c      Borrar / cambiar una selección visual",
      "",
      "PLIEGUES: cursor en la función o bloque",
      "za         Abrir/cerrar bloque",
      "zc / zo    Cerrar / abrir bloque",
      "zM / zR    Cerrar / abrir todos los bloques",
      "",
      "REVISAR ERRORES Y ENTENDER EL CÓDIGO",
      "[d / ]d    Error anterior / siguiente",
      "K          Tipo y documentación del símbolo",
      "gl         Errores de esta línea",
      "Espacio ld Errores del archivo",
      "gd         Ir a definición; Ctrl+o vuelve",
      "K otra vez Entrar en ayuda del símbolo; j/k desplaza",
      "Espacio lf Formatear código",
      "           Los mensajes LSP no ejecutan el programa.",
      "           Para valores reales: console.log o depurador.",
      "",
      "PLANTILLAS (según tipo de archivo)",
      "Ctrl+Space Solicitar autocompletado, en insertar",
      "Ctrl+n/p   Completar palabras del texto sin servidor LSP",
      "Tab        Recorrer sugerencias; Enter acepta la elegida",
      "Espacio lj Documentar función con JSDoc",
      "/** Enter  JSDoc automático, en insertar encima de función",
      "Ctrl+j     Elegir/expandir snippet, en insertar",
      "           En línea vacía muestra todas las del lenguaje",
      "           .ts: if, for, fn, clg...; .tsx: también React",
      "Ctrl+l/h   Campo siguiente/anterior del snippet",
      "           Esc termina la edición del snippet",
      "",
      "Espacio    Menú de acciones; z muestra ayuda de pliegues",
      "q / Esc    Cerrar esta ayuda",
    }
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].bufhidden = "wipe"
    local width = math.min(76, vim.o.columns - 4)
    local height = math.min(#lines, vim.o.lines - 6)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor", width = width, height = height,
      row = math.floor((vim.o.lines - height) / 2) - 1,
      col = math.floor((vim.o.columns - width) / 2),
      style = "minimal", border = "rounded", title = " Teclas habituales ",
    })
    vim.wo[win].wrap = true
    for _, key in ipairs({ "q", "<Esc>" }) do
      vim.keymap.set("n", key, function()
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
      end, { buffer = buf, silent = true })
    end
  end
  vim.api.nvim_create_user_command("AyudaEntorno", open, {})
  vim.keymap.set("n", "<leader>?", open, { desc = "Ayuda de teclas habituales" })
  vim.keymap.set("n", "<F1>", open, { desc = "Ayuda de teclas habituales" })
end
return M
