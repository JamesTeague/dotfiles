require("nvim-tree").setup()

vim.keymap.set("n", "<leader>pv", ":NvimTreeFocus<CR>", { desc = "Switch Focus to File Tree" })
vim.keymap.set("n", "<C-\\>", ":NvimTreeToggle<CR>", { desc = "Toggle File Tree" })
vim.keymap.set("n", "<leader>lf", ":NvimTreeFindFile<CR>", { desc = "Find file in File Tree" })
vim.keymap.set("n", "<C-_>", ":NvimTreeCollapse<CR>", { desc = "Collaps File Tree Recursively" })
