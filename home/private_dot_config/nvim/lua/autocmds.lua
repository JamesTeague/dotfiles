-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Prevent ColorScheme clears self-defined DAP icon colors
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "*",
  desc = "Prevent colorscheme clears self-defined DAP icon colors.",
  callback = function()
    vim.api.nvim_set_hl(0, "DapBreakpoint", { ctermbg = 0, fg = "#993939" })
    vim.api.nvim_set_hl(0, "DapLogPoint", { ctermbg = 0, fg = "#61afef" })
    vim.api.nvim_set_hl(0, "DapStopped", { ctermbg = 0, fg = "#98c379" })
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost" }, {
  pattern = "*",
  desc = "Open all code folds",
  group = vim.api.nvim_create_augroup("open_folds", { clear = true }),
  callback = function()
    -- Add a small delay to ensure treesitter is ready
    vim.defer_fn(function()
      vim.cmd("normal! zR")
    end, 100) -- 100ms delay
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)
