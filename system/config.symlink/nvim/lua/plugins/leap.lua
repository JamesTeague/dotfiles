return {
  {
    'ggandor/leap.nvim',
    keys = {
      { '<leader>f', '<Plug>(leap-forward)', mode = {'n', 'x', 'o'}, desc = 'Leap Forward' },
      { '<leader>F', '<Plug>(leap-backward)', mode = {'n', 'x', 'o'}, desc = 'Leap Backward' },
      { '<leader>fs', '<Plug>(leap-from-window)', mode = {'n', 'x', 'o'}, desc = 'Leap From Window' },
    },
  },
}
