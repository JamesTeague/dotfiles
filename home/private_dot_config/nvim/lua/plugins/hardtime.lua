return {
  "m4xshen/hardtime.nvim",
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  opts = {
    showmode = false,
    disabled_filetypes = { "qf", "netrw", "lazy", "mason", "oil" },
  },
}
