local go = require('go')

go.setup({
  icons = { breakpoint = '🔴' }
})

-- Run gofmt + goimport on save
local format_sync_grp = vim.api.nvim_create_augroup("GoImport", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    require('go.format').goimport()
  end,
  group = format_sync_grp,
})


vim.env.TEST_ENV = "local"

vim.keymap.set("n", "<leader>gt", [[:let $TEST_ENV = 'local' | GoTestFunc<CR>]], { desc = "Run Nearest Go Test" })
vim.keymap.set("n", "<leader>gts", [[:let $TEST_ENV = 'local' | GoTestFunc -s <CR>]], { desc = "Select Go Tests to run" })
vim.keymap.set("n", "<leader>gtf", [[:let $TEST_ENV = 'local' | GoTestFile <CR>]], { desc = "Run Go Tests in File" })

vim.keymap.set("n", "<leader>gp", ":GoPkgOutline<CR>", { desc = "View Go Package Outline" })
