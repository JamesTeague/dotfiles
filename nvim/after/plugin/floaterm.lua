vim.keymap.set("n", "<leader>ft", ":FloatermNew --name=floater --height=0.8 --width=0.7 --autoclose=2 zsh <CR> ")
vim.keymap.set('n', "t", ":FloatermToggle floater<CR>")
vim.keymap.set('t', "<Esc>", "<C-\\><C-n>:q<CR>")
vim.keymap.set('t', "<C-s>", "<C-\\><C-n>")
