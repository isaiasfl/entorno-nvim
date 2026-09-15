local M = {}

function M.open_file()
  vim.ui.input({ prompt = "Abrir archivo: ", completion = "file" }, function(path)
    if path and path ~= "" then
      vim.cmd.edit(vim.fn.fnameescape(path))
    end
  end)
end

function M.pick(method)
  if require("config.lazy").available then
    require("lazy").load({ plugins = { "fzf-lua" } })
    require("fzf-lua")[method]()
    return
  end
  if method == "files" then
    M.open_file()
  elseif method == "buffers" then
    local buffers = vim.tbl_filter(function(buf)
      return vim.bo[buf].buflisted
    end, vim.api.nvim_list_bufs())
    vim.ui.select(buffers, {
      prompt = "Buffers",
      format_item = function(buf)
        local name = vim.api.nvim_buf_get_name(buf)
        return name ~= "" and name or "[Sin nombre]"
      end,
    }, function(buf)
      if buf then vim.api.nvim_set_current_buf(buf) end
    end)
  elseif method == "oldfiles" then
    vim.ui.select(vim.v.oldfiles, { prompt = "Archivos recientes" }, function(path)
      if path then vim.cmd.edit(vim.fn.fnameescape(path)) end
    end)
  elseif method == "live_grep" then
    if vim.fn.executable("rg") ~= 1 then
      vim.notify("Falta ripgrep; use / para buscar en el archivo actual", vim.log.levels.WARN)
      return
    end
    vim.ui.input({ prompt = "Buscar en el proyecto: " }, function(pattern)
      if not pattern or pattern == "" then return end
      vim.system({ "rg", "--vimgrep", "--smart-case", "--", pattern, "." }, {
        text = true, cwd = vim.fn.getcwd(),
      }, vim.schedule_wrap(function(result)
        if result.code > 1 then
          vim.notify(result.stderr, vim.log.levels.ERROR)
          return
        end
        vim.fn.setqflist({}, " ", {
          title = pattern,
          lines = vim.split(result.stdout or "", "\n", { trimempty = true }),
          efm = "%f:%l:%c:%m",
        })
        vim.cmd.copen()
      end))
    end)
  end
end

local previous_buffers = {}

function M.explorer()
  if require("config.lazy").available then
    require("lazy").load({ plugins = { "nvim-tree.lua" } })
    require("nvim-tree.api").tree.toggle({ focus = true })
  else
    local window = vim.api.nvim_get_current_win()
    if vim.bo.filetype == "netrw" then
      local previous = previous_buffers[window]
      previous_buffers[window] = nil
      if previous and vim.api.nvim_buf_is_valid(previous) then
        vim.api.nvim_win_set_buf(window, previous)
      else
        require("config.dashboard").open()
      end
      return
    end
    previous_buffers[window] = vim.api.nvim_get_current_buf()
    -- El dashboard tiene una URI ifl://, no una carpeta del sistema.
    -- Sin ruta explicita netrw no sale de esa pantalla.
    vim.cmd.Explore(vim.fn.fnameescape(vim.fn.getcwd()))
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("entorno_explorer_keys", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "netrw",
    callback = function(event)
      -- netrw define Space localmente; retirarlo para que no intercepte el leader.
      pcall(vim.keymap.del, "n", "<Space>", { buffer = event.buf })
      for _, key in ipairs({ "<leader>e", "<leader>ee" }) do
        vim.keymap.set("n", key, M.explorer,
          { buffer = event.buf, silent = true, desc = "Cerrar explorador" })
      end
    end,
  })
  for key, method in pairs({ ff = "files", fg = "live_grep", fb = "buffers" }) do
    vim.keymap.set("n", "<leader>" .. key, function() M.pick(method) end,
      { desc = "Navegacion: " .. method })
  end
  vim.keymap.set("n", "<leader>ee", M.explorer, { desc = "Explorador de archivos" })
  vim.keymap.set("n", "<leader>ef", function()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
      vim.notify("El buffer actual no corresponde a un archivo")
      return
    end
    vim.cmd.Explore(vim.fn.fnameescape(vim.fs.dirname(path)))
  end, { desc = "Abrir la carpeta del archivo actual (explorador nativo)" })
end

return M
