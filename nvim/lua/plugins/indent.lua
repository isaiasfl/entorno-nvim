return {
  {
    "lukas-reineke/indent-blankline.nvim",
    commit = "f1e186e44d3b7f9ae918008e2c28ce37c6023d2d",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local names = { "IndentBlue", "IndentPurple", "IndentGreen", "IndentGold" }
      local colors = { "#657f9c", "#89729e", "#718d77", "#9a8864" }
      local hooks = require("ibl.hooks")
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        for i, name in ipairs(names) do
          vim.api.nvim_set_hl(0, name, { fg = colors[i] })
        end
      end)
      require("ibl").setup({
        indent = { char = "│", highlight = names },
        scope = { enabled = false },
      })
    end,
  },
}
