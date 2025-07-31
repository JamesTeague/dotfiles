return {
  {
    "ray-x/go.nvim",
    ft = "go",
    opts = {
      icons = { breakpoint = "🔴" },
    },
    keys = {
      { "<leader>gt", "<cmd>GoTestFunc<CR>", { desc = "Run Nearest [G]o [T]est" } },
      { "<leader>gts", "<cmd> GoTestFunc -s <CR>", { desc = "Select Go Tests to run" } },
      { "<leader>gtf", "<cmd> GoTestFile <CR>", { desc = "Run [G]o [T]ests in [F]ile" } },
      { "<leader>gp", ":GoPkgOutline<CR>", { desc = "View Go Package Outline" } },
      { "<leader>gm", ":GoMockGen -s<CR>", { desc = "Generate Go Mock for Interface by source" } },
      { "<leader>gif", ":GoIfErr<CR>", { desc = "Generate if err snippet" } },
    },
  },
}
