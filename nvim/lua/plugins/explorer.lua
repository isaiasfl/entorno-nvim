return {
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      {
        "nvim-tree/nvim-web-devicons",
        commit = "2ae6958df7ced50baac5035cec0c15799eedfbf7",
      },
    },
    cmd = {
      "NvimTreeFocus",
      "NvimTreeOpen",
      "NvimTreeToggle",
    },
    keys = {
      {
        "<leader>E",
        function()
          local path = vim.api.nvim_buf_get_name(0)
          if path == "" then
            vim.notify("El buffer actual no corresponde a un archivo", vim.log.levels.WARN)
            return
          end

          require("nvim-tree.api").tree.find_file({
            open = true,
            focus = true,
            update_root = false,
          })
        end,
        desc = "Enfocar el archivo actual en el arbol",
      },
    },
    -- Las opciones viven en config/explorer.lua para que :EntornoIconos pueda
    -- reaplicarlas en caliente sin reiniciar Neovim.
    opts = function()
      return require("config.explorer").opts()
    end,
  },
}
