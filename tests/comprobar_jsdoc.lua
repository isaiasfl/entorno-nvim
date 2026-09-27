local root = vim.env.ENTORNO_NVIM_ROOT or vim.fn.getcwd()
vim.opt.rtp:append(root .. '/.xdg/0.12.4/data/nvim/lazy/mini.nvim')
local child = require('mini.test').new_child_neovim()
child.start({ '-u', 'NONE' })
child.lua('_G.entorno_test_root = ' .. vim.inspect(root))
child.lua([[
  local root = _G.entorno_test_root
  vim.opt.rtp:append(root .. '/nvim')
  vim.opt.rtp:append(root .. '/.xdg/0.12.4/data/nvim/lazy/mini.nvim')
  require('config.snippets').setup()
  require('config.completion').setup()
  vim.cmd('edit /tmp/entorno-jsdoc-key-case.ts')
  vim.bo.filetype = 'typescript'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { '', 'function cifrar(texto: string): string { return texto }' })
  _G.client_id = vim.lsp.start({ name = 'ts_ls', root_dir = '/tmp',
    cmd = { root .. '/tools/lsp-web/node_modules/.bin/typescript-language-server', '--stdio' },
    init_options = { preferences = { generateReturnInDocTemplate = true } },
  })
]])
assert(vim.wait(15000, function() return child.lua_get("#vim.lsp.get_clients({bufnr=0,name='ts_ls'}) > 0") end, 50))
child.type_keys('i', '/', '*', '*', '<CR>')
local success = vim.wait(5000, function()
  return child.lua_get("table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\\n')"):find('@param texto', 1, true)
end, 50)
if not success then
  print(vim.inspect(child.lua_get("{lines=vim.api.nvim_buf_get_lines(0,0,-1,false), mode=vim.fn.mode(), messages=vim.api.nvim_exec2('messages',{output=true}).output, cursor=vim.api.nvim_win_get_cursor(0)}")))
  child.stop()
  error('Pulsar /** y Enter no genero el comentario')
end
local text = child.lua_get("table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\\n')")
assert(text:find('@returns', 1, true), text)
assert(text:find('function cifrar', 1, true), text)
child.type_keys('<Esc>')
child.lua("vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'normal' }); vim.api.nvim_win_set_cursor(0, {1, 0})")
child.type_keys('A', '<CR>', 'siguiente', '<Esc>')
assert(child.lua_get('vim.api.nvim_buf_line_count(0)') == 2, 'Enter normal no funciona')
child.stop()
print('OK: pulsaciones reales /** + Enter, JSDoc y Enter normal')
vim.cmd('qa!')
