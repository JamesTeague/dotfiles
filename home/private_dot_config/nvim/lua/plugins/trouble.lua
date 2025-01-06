return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {
    auto_close = true, -- auto close when there are no items
    auto_open = false, -- auto open when there are items
    auto_jump = true, -- auto jump to the item when there's only one
    focus = true, -- Focus the window when opened
  },
  keys = {
    {
      "<leader>tt",
      "<cmd>Trouble diagnostics toggle<cr>",
      { desc = "[T]oggle [T]rouble" },
    },
    {
      "[t",
      function()
        require("trouble").next({ skip_groups = true, jump = true })
      end,
      { desc = "Next Error" },
    },
    {
      "]t",
      function()
        require("trouble").previous({ skip_groups = true, jump = true })
      end,
      { desc = "Previous Error" },
    },
    {
      "<leader>tT",
      "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
      desc = "Buffer Diagnostics (Trouble)",
    },
    {
      "<leader>ts",
      "<cmd>Trouble symbols toggle focus=false<cr>",
      desc = "Symbols (Trouble)",
    },
    {
      "<leader>tl",
      "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
      desc = "LSP Definitions / references / ... (Trouble)",
    },
    {
      "<leader>tL",
      "<cmd>Trouble loclist toggle<cr>",
      desc = "Location List (Trouble)",
    },
    {
      "<leader>tQ",
      "<cmd>Trouble qflist toggle<cr>",
      desc = "Quickfix List (Trouble)",
    },
  },
}
