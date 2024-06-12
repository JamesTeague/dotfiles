return {
  {
    "navarasu/onedark.nvim",
    name = "onedark",
    opts = {
      style = "darker",
      transparent = true,
    },
    config = function(_, opts)
      require("onedark").setup(opts)
      require("onedark").load()
    end,
  },
}
