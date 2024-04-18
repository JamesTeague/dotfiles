function ColorMyPencils(color)
  color = color or "onedark"
  vim.cmd.colorscheme(color)
end

return {
  {
    "navarasu/onedark.nvim",
    name = "onedark",
    config = function()
      require("onedark").setup({
        style = "darker",
        transparent = true,
      })
      require("onedark").load()

      ColorMyPencils()
    end,
  },
}
