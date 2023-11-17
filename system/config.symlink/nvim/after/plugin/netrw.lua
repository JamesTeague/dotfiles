vim.api.nvim_create_autocmd('filetype', {
  pattern = 'netrw',
  desc = 'Better mappings for netrw',
  callback = function()
    local bind = function(lhs, rhs)
      vim.keymap.set('n', lhs, rhs, {remap = true, buffer = true})
    end

    vim.g['netrw_keepdir'] = 0
    vim.g['netrw_winsize'] = 30
    vim.g['netrw_banner'] = 0
    vim.g['netrw_localcopydircmd'] = 'cp -r'

    -- edit new file
    bind('n', '%')

    -- rename file
    bind('r', 'R')

    -- mark file
    bind('<TAB>', 'mf')
    bind('<S-TAB>', 'mF')
    bind('<leader><TAB>', 'mu')
  end
})
