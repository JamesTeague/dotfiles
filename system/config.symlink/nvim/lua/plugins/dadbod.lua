return {
  'tpope/vim-dadbod',
  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      {
        'kristijanhusak/vim-dadbod-completion',
        ft = { 'sql', 'mysql', 'plsql' }
      }
    }
  },
}
