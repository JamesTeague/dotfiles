-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Format on Save
vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Format on save',
  group = vim.api.nvim_create_augroup('LSPFormatOnSave', { clear = true }),
  callback = function()
    vim.lsp.buf.format()
  end,
})

-- Prevent ColorScheme clears self-defined DAP icon colors
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  desc = 'Prevent colorscheme clears self-defined DAP icon colors.',
  callback = function()
    vim.api.nvim_set_hl(0, 'DapBreakpoint', { ctermbg = 0, fg = '#993939' })
    vim.api.nvim_set_hl(0, 'DapLogPoint', { ctermbg = 0, fg = '#61afef' })
    vim.api.nvim_set_hl(0, 'DapStopped', { ctermbg = 0, fg = '#98c379' })
  end
})

-- reload current color scheme to pick up colors override if it was set up in a lazy plugin definition fashion
vim.cmd.colorscheme(vim.g.colors_name)

-- HACK: This may be a hack. Want to disable virtual_text because of the lsp_lines plugin.
-- see `:help lsp_lines.nvim-setup
vim.api.nvim_create_autocmd('VimEnter', {
  desc = 'Disable virtual_text upon enter',
  callback = function()
    -- Disable Code Diagnostic in favor of lsp_lines plugin
    vim.diagnostic.config({ virtual_text = false })
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)
