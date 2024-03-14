return {
  {
    'folke/trouble.nvim',
    config = function()
      require("trouble").setup({
        icons = true,
      })

      vim.keymap.set("n", "<leader>tt", function()
        require("trouble").toggle()
      end, { desc = "[T]oggle [T]rouble" })

      vim.keymap.set("n", "[t", function()
        require("trouble").next({skip_groups = true, jump = true});
      end, { desc = "Next Error" })

      vim.keymap.set("n", "]t", function()
        require("trouble").previous({skip_groups = true, jump = true});
      end, { desc = "Previous Error" })

    end
  },
}
