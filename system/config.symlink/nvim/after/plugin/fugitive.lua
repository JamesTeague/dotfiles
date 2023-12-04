vim.keymap.set("n", "<leader>gs", vim.cmd.Git, { desc = "git status" })
vim.keymap.set("n", "<leader>gf", function()
  vim.cmd.Git("diff")
end, { desc = "git diff" })
-- vim.keymap.set("n", "gf", "<cmd>diffget //2<CR>")
-- vim.keymap.set("n", "gj", "<cmd>diffget //3<CR>")
local Jteague_Fugitive = vim.api.nvim_create_augroup("Jteague_Fugitive", {})

local autocmd = vim.api.nvim_create_autocmd
autocmd("BufWinEnter", {
  group = Jteague_Fugitive,
  pattern = "*",
  callback = function()
    if vim.bo.ft ~= "fugitive" then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    --    local opts = { buffer = bufnr, remap = false }
    vim.keymap.set("n", "<leader>c", function()
      vim.cmd.Git('commit')
    end, { buffer = bufnr, remap = false, desc = "Commit changes" })

    vim.keymap.set("n", "<leader>p", function()
      vim.cmd.Git('push')
    end, { buffer = bufnr, remap = false, desc = "Push changes" })

    -- rebase always
    vim.keymap.set("n", "<leader>P", function()
      vim.cmd.Git('pull')
    end, { buffer = bufnr, remap = false, desc = "Pull branch" })

    -- NOTE: It allows me to easily set the branch i am pushing and any tracking
    -- needed if i did not set the branch up correctly
    vim.keymap.set("n", "<leader>t", ":Git push -u origin ",
      { buffer = bufnr, remap = false, desc = "Setup branch origin" });
  end,
})
