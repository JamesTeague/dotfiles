return {
  "folke/trouble.nvim",
  opts = { icons = true },
  keys = {
    {
      "<leader>tt",
      function()
        require("trouble").toggle()
      end,
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
  },
}
