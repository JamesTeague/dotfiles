return {
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      { "<leader>gs", "<cmd>Neogit<cr>", desc = "[G]it [S]tatus" },
      { "<leader>grp", "<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>", desc = "[G]it [R]eview [P]ull" },
      {
        "<leader>grpc",
        "<cmd>DiffviewFileHistory --range=origin/HEAD...HEAD --right-only --no-merges<cr>",
        desc = "[G]it [R]eview [P]ull [C]ommits",
      },
      { "<leader>grs", "<cmd>DiffviewFileHistory -g --range=stash<cr>", desc = "[G]it [R]eview [S]tash" },
    },
    config = true,
  },
  {
    "akinsho/git-conflict.nvim",
    version = "*",
    config = true,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("configs.gitsigns")
    end,
  },
}
