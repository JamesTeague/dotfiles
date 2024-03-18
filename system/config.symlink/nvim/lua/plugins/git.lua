return {
  {
    'NeogitOrg/neogit',
    dependencies = {
      'nvim-lua/plenary.nvim',  -- required
      'sindrets/diffview.nvim', -- optional - Diff integration
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      { '<leader>gs',   '<cmd>Neogit<cr>',                                                                  desc = '[G]it [S]tatus' },
      { '<leader>grp',  '<cmd>DiffviewOpen origin/HEAD...HEAD --imply-local<cr>',                           desc = '[G]it [R]eview [P]ull' },
      { '<leader>grpc', '<cmd>DiffviewFileHistory --range=origin/HEAD...HEAD --right-only --no-merges<cr>', desc = '[G]it [R]eview [P]ull [C]ommits' },
      { '<leader>grs',  '<cmd>DiffviewFileHistory -g --range=stash<cr>',                                    desc = '[G]it [R]eview [S]tash' },
    },
    config = true
  },
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    config = true
  },
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        current_line_blame = true,
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            vim.schedule(function() gs.next_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            vim.schedule(function() gs.prev_hunk() end)
            return '<Ignore>'
          end, { expr = true })

          -- Actions
          map('n', '<leader>hs', gs.stage_hunk, { desc = '[H]unk [S]tage' })
          map('n', '<leader>hr', gs.reset_hunk, { desc = '[H]unk [R]eset' })
          map('v', '<leader>hs', function() gs.stage_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
            { desc = '[H]unk [S]tage Line' })
          map('v', '<leader>hr', function() gs.reset_hunk { vim.fn.line('.'), vim.fn.line('v') } end,
            { desc = '[H]unk [R]eset Line' })
          map('n', '<leader>hsb', gs.stage_buffer, { desc = '[H]unk [S]tage [B]uffer' })
          map('n', '<leader>hu', gs.undo_stage_hunk, { desc = '[H]unk [U]ndo Stage' })
          map('n', '<leader>hrb', gs.reset_buffer, { desc = '[H]unk [R]eset [B]uffer' })
          map('n', '<leader>hp', gs.preview_hunk, { desc = '[H]unk [P]review' })
          map('n', '<leader>hb', function() gs.blame_line { full = true } end, { desc = '[H]unk [B]lame Line' })
          map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = '[T]oggle Current Line [B]lame' })
          map('n', '<leader>hd', gs.diffthis, { desc = '[H]unk [D]iff' })
          map('n', '<leader>hdf', function() gs.diffthis('~') end, { desc = '[H]unk [D]iff [F]ile' })
          map('n', '<leader>td', gs.toggle_deleted, { desc = '[T]oggle [D]eleted' })

          -- Text object
          map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
        end
      })
    end,
  },
}
