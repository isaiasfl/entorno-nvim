local markdown_pdf = require("config.markdown_pdf")

assert(vim.fn.exists(":MarkdownPdf") == 2, "falta el comando :MarkdownPdf")

local generate_mapping = vim.fn.maparg("<leader>mp", "n", false, true)
local preview_mapping = vim.fn.maparg("<leader>mv", "n", false, true)
assert(type(generate_mapping.callback) == "function", "<leader>mp no usa un callback Lua")
assert(generate_mapping.desc == "Generar PDF del Markdown actual", "<leader>mp tiene una descripción incorrecta")
assert(type(preview_mapping.callback) == "function", "<leader>mv no usa un callback Lua")
assert(
  preview_mapping.desc == "Generar y visualizar PDF del Markdown actual",
  "<leader>mv tiene una descripción incorrecta"
)

local original_export = markdown_pdf.export_current
local calls = {}
markdown_pdf.export_current = function(output, options)
  calls[#calls + 1] = { options = options, output = output }
end

vim.cmd.MarkdownPdf("salida con espacios.pdf")
assert(calls[1].output == "salida con espacios.pdf", ":MarkdownPdf no delega la salida indicada")

generate_mapping.callback()
assert(#calls == 2 and calls[2].output == nil, "<leader>mp no exporta el Markdown actual")
assert(calls[2].options == nil, "<leader>mp activó la visualización")

preview_mapping.callback()
assert(#calls == 3 and calls[3].output == nil, "<leader>mv no exporta el Markdown actual")
assert(calls[3].options.preview == true, "<leader>mv no activa la visualización")

markdown_pdf.export_current = original_export
