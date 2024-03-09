return {
  {
    'ray-x/go.nvim',
    config = function ()
      local go = require('go')

      go.setup({
        icons = { breakpoint = '🔴' }
      })

      vim.env.TEST_ENV = "local"

      vim.keymap.set("n", "<leader>gt", [[:let $TEST_ENV = 'local' | GoTestFunc<CR>]], { desc = "Run Nearest Go Test" })
      vim.keymap.set("n", "<leader>gts", [[:let $TEST_ENV = 'local' | GoTestFunc -s <CR>]], { desc = "Select Go Tests to run" })
      vim.keymap.set("n", "<leader>gtf", [[:let $TEST_ENV = 'local' | GoTestFile <CR>]], { desc = "Run Go Tests in File" })

      vim.keymap.set("n", "<leader>gp", ":GoPkgOutline<CR>", { desc = "View Go Package Outline" })
      vim.keymap.set("n", "<leader>gm", ":GoMockGen -s<CR>", { desc = "Generate Go Mock for Interface by source" })
    end,
  },
  'ray-x/guihua.lua', -- recommended if need floating window support
  {
    'ray-x/lsp_signature.nvim',
    config = function ()
      require('lsp_signature').setup()
    end,
  }
}
