local markdown_pdf = require("config.markdown_pdf")

assert(vim.fn.exists(":MarkdownPdf") == 2, "falta el comando :MarkdownPdf")

local mapping = vim.fn.maparg("<leader>mp", "n", false, true)
assert(type(mapping.callback) == "function", "<leader>mp no usa un callback Lua")
assert(mapping.desc == "Generar PDF del Markdown actual", "<leader>mp tiene una descripción incorrecta")

local original_export = markdown_pdf.export_current
local calls = {}
markdown_pdf.export_current = function(output)
  calls[#calls + 1] = { output = output }
end

vim.cmd.MarkdownPdf("salida con espacios.pdf")
assert(calls[1].output == "salida con espacios.pdf", ":MarkdownPdf no delega la salida indicada")

mapping.callback()
assert(#calls == 2 and calls[2].output == nil, "<leader>mp no exporta el Markdown actual")

markdown_pdf.export_current = original_export
