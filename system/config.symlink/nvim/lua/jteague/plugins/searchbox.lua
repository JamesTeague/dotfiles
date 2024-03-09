return {
  {
    'VonHeikemen/searchbox.nvim',
    dependencies = {
      {'MunifTanjim/nui.nvim'}
    },
    config = function ()
      require('searchbox').setup({
        defaults = {
          show_matches = true,
        },
      })

      vim.keymap.set('n', '<leader>s', ':SearchBoxIncSearch<CR>')
      vim.keymap.set('x', '<leader>s', ':SearchBoxIncSearch visual_mode=true<CR>')
      vim.keymap.set('n', '<leader>r', ':SearchBoxReplace<CR>')
      vim.keymap.set('x', '<leader>r', ':SearchBoxReplace exact=true visual_mode=true<CR>')
    end
  },
}
