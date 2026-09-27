local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root .. '/nvim')
vim.opt.rtp:append(root .. '/.xdg/0.12.4/data/nvim/lazy/mini.nvim')
local indent = vim.env.ENTORNO_INDENT_PLUGIN or root .. '/.xdg/0.12.4/data/nvim/lazy/indent-blankline.nvim'
vim.opt.rtp:append(indent)
vim.g.mapleader = ' '
require('config.options')
require('config.help').setup()
vim.cmd('AyudaEntorno')
assert(vim.api.nvim_win_get_config(0).relative == 'editor')
vim.cmd('close')
require('config.snippets').setup()
for _, ft in ipairs({'html', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact'}) do
 local data = vim.json.decode(table.concat(vim.fn.readfile(root .. '/nvim/snippets/' .. ft .. '.json'), '\n'))
 for _, item in pairs(data) do
  assert(item.prefix and item.body and item.description)
  require('mini.snippets').parse(table.concat(item.body, '\n'))
 end
end
local plugin = dofile(root .. '/nvim/lua/plugins/indent.lua')[1]
plugin.config()
vim.bo.filetype = 'typescript'
vim.api.nvim_buf_set_lines(0, 0, -1, false, {'function demo() {', '  if (true) {', '    return 1', '  }', '}'})
require('ibl').refresh(0)
assert(vim.o.foldlevel == 99)
print('OK: ayuda, snippets y guías de indentación')
vim.cmd('qa!')
