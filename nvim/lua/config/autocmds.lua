local function augroup(name)
  return vim.api.nvim_create_augroup("entorno_nvim_" .. name, { clear = true })
end

-- Los temas marcan las faltas solo con subrayado ondulado, que Windows
-- Terminal/WSL y tmux no suelen dibujar: se añade texto rojo y subrayado.
vim.api.nvim_create_autocmd("ColorScheme", {
  group = augroup("spell_visible"),
  callback = function()
    vim.api.nvim_set_hl(0, "SpellBad", { fg = "#f38ba8", sp = "#f38ba8", underline = true, ctermfg = 203, cterm = { underline = true } })
    vim.api.nvim_set_hl(0, "SpellCap", { sp = "#f9e2af", undercurl = true })
    vim.api.nvim_set_hl(0, "SpellLocal", { sp = "#f9e2af", undercurl = true })
    vim.api.nvim_set_hl(0, "SpellRare", { sp = "#f9e2af", undercurl = true })
    -- Diagnósticos: subrayado simple y color, visible sin undercurl.
    for name, color in pairs({ Error = "#f38ba8", Warn = "#f9e2af", Info = "#89dceb", Hint = "#94e2d5" }) do
      vim.api.nvim_set_hl(0, "DiagnosticUnderline" .. name, { sp = color, underline = true })
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank({ timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup("checktime"),
  callback = function()
    if vim.bo.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_position"),
  callback = function(event)
    local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(event.buf)

    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("text_layout"),
  pattern = { "gitcommit", "markdown", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter_highlight"),
  pattern = {
    "css",
    "html",
    "javascript",
    "javascriptreact",
    "json",
    "python",
    "sh",
    "typescript",
    "typescriptreact",
  },
  callback = function(event)
    local language = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
    local ok, loaded = pcall(vim.treesitter.language.add, language or "")
    if language and ok and loaded then
      vim.treesitter.start(event.buf, language)
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("python_indent"),
  pattern = "python",
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
    vim.opt_local.tabstop = 4
  end,
})
