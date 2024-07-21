return {
  {
    event = "VeryLazy",
    "JamesTeague/quicknote.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      sign = "",
    },
    keys = {
      {
        "<leader>nc",
        function()
          require("quicknote").NewNoteAtCurrentLine()
          require("quicknote").OpenNoteAtCurrentLine()
        end,
        { desc = "Create Note at Current Line" },
      },
      {
        "<leader>nx",
        function()
          require("quicknote").DeleteNoteAtCurrentLine()
        end,
        { desc = "Delete Note at Current Line" },
      },
    },
    config = function(_, opts)
      require("quicknote").setup(opts)
      require("quicknote").ShowNoteSigns()
      require("telescope").load_extension("quicknote")
    end,
  },
}
