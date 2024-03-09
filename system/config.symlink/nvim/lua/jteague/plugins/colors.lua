function ColorMyPencils(color)
  color = color or "onedark"
  vim.cmd.colorscheme(color)

  vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

return {
  { 'rose-pine/neovim', name = 'rose-pine' },
  {
    'navarasu/onedark.nvim',
    name = 'onedark',
    config = function ()
      require('onedark').setup {
        style = 'darker',
        transparent = true,
      }
      require('onedark').load()

      ColorMyPencils()
    end
  },
}
