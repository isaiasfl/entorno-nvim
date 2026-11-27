-- Prueba aislada de config.eslint: diagnósticos nativos cuando hay proyecto
-- con eslint.config.* y node_modules/.bin/eslint, y silencio total si no hay.
local eslint = require("config.eslint")
eslint.setup()

local base = vim.fn.tempname() .. "_eslint"
local with_eslint = base .. "/con_eslint"
local without_eslint = base .. "/sin_eslint"
vim.fn.mkdir(with_eslint .. "/node_modules/.bin", "p")
vim.fn.mkdir(without_eslint, "p")

-- Configuración y binario simulado que devuelve el formato JSON oficial de ESLint.
vim.fn.writefile({ "export default [];" }, with_eslint .. "/eslint.config.js")
local fake_bin = with_eslint .. "/node_modules/.bin/eslint"
vim.fn.writefile({
  "#!/bin/sh",
  "cat >/dev/null",
  'printf \'%s\' \'[{"filePath":"demo.tsx","messages":[{"ruleId":"react-hooks/exhaustive-deps","severity":1,"message":"Missing dependency","line":2,"column":3,"endLine":2,"endColumn":10},{"ruleId":"no-unused-vars","severity":2,"message":"x is defined but never used","line":1,"column":7,"endLine":1,"endColumn":8}]}]\'',
  "exit 1",
}, fake_bin)
vim.uv.fs_chmod(fake_bin, 493) -- 0755

local file_ok = with_eslint .. "/demo.tsx"
vim.fn.writefile({ "const x = 1;", "  useEffect(() => {}, []);" }, file_ok)
vim.cmd.edit(vim.fn.fnameescape(file_ok))
local buf = vim.api.nvim_get_current_buf()

assert(vim.wait(4000, function()
  return #vim.diagnostic.get(buf, { namespace = eslint.namespace }) == 2
end, 50), "ESLint no publicó los 2 diagnósticos esperados")

local diags = vim.diagnostic.get(buf, { namespace = eslint.namespace })
assert(diags[1].source == "eslint" and diags[1].code == "react-hooks/exhaustive-deps", vim.inspect(diags))
assert(diags[1].severity == vim.diagnostic.severity.WARN, "Se esperaba WARN para severity 1")
assert(diags[2].severity == vim.diagnostic.severity.ERROR and diags[2].code == "no-unused-vars", vim.inspect(diags))

-- Proyecto sin ESLint: no publica nada ni lanza errores.
local file_plain = without_eslint .. "/plain.ts"
vim.fn.writefile({ "const y = 2;" }, file_plain)
vim.cmd.edit(vim.fn.fnameescape(file_plain))
local plain_buf = vim.api.nvim_get_current_buf()
vim.wait(700)
assert(#vim.diagnostic.get(plain_buf, { namespace = eslint.namespace }) == 0, "No debía publicar diagnósticos sin ESLint")

vim.cmd("enew!")
vim.fn.delete(base, "rf")
print("OK: ESLint nativo en proyectos con eslint.config y silencio sin ESLint")
