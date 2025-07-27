return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      { "mrcjkb/rustaceanvim", version = "^6" },
      -- Useful status updates for LSP.
      { "j-hui/fidget.nvim", opts = {} },
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      require("configs.lsp")
    end,
  },
  {
    "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    opts = {},
    config = function()
      require("lsp_lines").setup()

      vim.diagnostic.config({ virtual_lines = { only_current_line = true } })

      vim.keymap.set("", "<Leader>l", require("lsp_lines").toggle, { desc = "Toggle lsp_lines" })
    end,
  },
  {
    "nvimdev/lspsaga.nvim",
    opts = {},
    keys = {
      { "<leader>lic", "<cmd>Lspsaga incoming_calls<cr>", desc = "[L]ist [I]ncoming [C]alls" },
      { "<leader>loc", "<cmd>Lspsaga outgoing_calls<cr>", desc = "[L]ist [O]utgoing [C]alls" },
      -- NOTE: Overwritten from lsp
      { "K", "<cmd>Lspsaga hover_doc<cr>", desc = "Hover Documentation" },
      { "<leader>pd", "<cmd>Lspsaga peek_definition<cr>", desc = "[P]eek [D]efinition" },
    },
  },
}
