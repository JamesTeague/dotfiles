return {
  {
    "ray-x/go.nvim",
    opts = {
      icons = { breakpoint = "🔴" },
    },
    keys = {
      { "<leader>gt", "<cmd>GoTestFunc<CR>", { desc = "Run Nearest [G]o [T]est" } },
      { "<leader>gts", "<cmd> GoTestFunc -s <CR>", { desc = "Select Go Tests to run" } },
      { "<leader>gtf", "<cmd> GoTestFile <CR>", { desc = "Run [G]o [T]ests in [F]ile" } },
      { "<leader>gp", ":GoPkgOutline<CR>", { desc = "View Go Package Outline" } },
      { "<leader>gm", ":GoMockGen -s<CR>", { desc = "Generate Go Mock for Interface by source" } },
    },
    -- config = function()
    --   vim.env.TEST_ENV = "local"
    --
    --   vim.keymap.set(
    --     "n",
    --     "<leader>gt",
    --     [[:let $TEST_ENV = 'local' | GoTestFunc<CR>]],
    --     { desc = "Run Nearest [G]o [T]est" }
    --   )
    --   vim.keymap.set(
    --     "n",
    --     "<leader>gts",
    --     [[:let $TEST_ENV = 'local' | GoTestFunc -s <CR>]],
    --     { desc = "Select Go Tests to run" }
    --   )
    --   vim.keymap.set(
    --     "n",
    --     "<leader>gtf",
    --     [[:let $TEST_ENV = 'local' | GoTestFile <CR>]],
    --     { desc = "Run [G]o [T]ests in [F]ile" }
    --   )
    --
    --   vim.keymap.set("n", "<leader>gp", ":GoPkgOutline<CR>", { desc = "View Go Package Outline" })
    --   vim.keymap.set("n", "<leader>gm", ":GoMockGen -s<CR>", { desc = "Generate Go Mock for Interface by source" })
    -- end,
  },
  "ray-x/guihua.lua", -- recommended if need floating window support
  {
    "ray-x/lsp_signature.nvim",
    opts = {},
  },
}
