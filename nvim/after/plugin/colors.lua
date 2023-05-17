function ColorMyPencils(color)
	color = color or "onedark"
  if (color == "onedark") then
    require('onedark').setup {
      style = 'darker',
      transparent = true,
    }
    require('onedark').load()
  else
    vim.cmd.colorscheme(color)
  end

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

ColorMyPencils()
