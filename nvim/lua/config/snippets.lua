local M = {}

function M.setup()
  local snippets = require("mini.snippets")
  snippets.setup({
    snippets = { snippets.gen_loader.from_lang() },
    expand = {
      insert = function(snippet)
        local ft = vim.bo.filetype
        if snippet.prefix == "docfn" and (ft == "typescript" or ft == "typescriptreact"
          or ft == "javascript" or ft == "javascriptreact") then
          require("config.jsdoc").generate(snippet)
          return
        end
        snippets.default_insert(snippet, { empty_tabstop = "", empty_tabstop_final = "" })
      end,
      select = function(items, insert)
        if #items == 0 then return end
        if #items == 1 then
          insert(items[1])
          return
        end
        vim.ui.select(items, {
          prompt = "Snippets > ",
          format_item = function(item)
            return item.prefix .. " | " .. (item.desc or item.description or "")
          end,
        }, vim.schedule_wrap(function(item)
          if item then insert(item) end
        end))
      end,
    },
  })

  vim.api.nvim_create_user_command("DocumentarFuncion", function()
    require("config.jsdoc").generate()
  end, { desc = "Generar JSDoc con los parametros de la funcion" })
  vim.keymap.set("n", "<leader>lj", "<cmd>DocumentarFuncion<cr>", {
    desc = "Documentar funcion (JSDoc)", silent = true,
  })

  local group = vim.api.nvim_create_augroup("entorno_nvim_snippets", { clear = true })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    desc = "Terminar las plantillas al salir de insertar",
    callback = function()
      while snippets.session.get() do snippets.session.stop() end
    end,
  })
end

return M
