-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
  -- Packer can manage itself
  use 'wbthomason/packer.nvim'

  use {
    'nvim-telescope/telescope.nvim', tag = '0.1.x',
    -- or                            , branch = '0.1.x',
    requires = { { 'nvim-lua/plenary.nvim' } }
  }

  use({ 'rose-pine/neovim', as = 'rose-pine' })
  use({ 'navarasu/onedark.nvim', as = 'onedark' })
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons', -- optional
    },
  }
  use('theprimeagen/vim-be-good')

  require('onedark').setup {
    style = 'warmer',
    transparent = true
  }
  require('onedark').load()

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end,
  }
  use({
    "nvim-treesitter/nvim-treesitter-textobjects",
    after = "nvim-treesitter",
    requires = "nvim-treesitter/nvim-treesitter",
  })
  use('nvim-treesitter/nvim-treesitter-context')
  use('nvim-treesitter/playground')
  use('theHamsta/nvim-dap-virtual-text')
  use('theprimeagen/harpoon')
  use('mbbill/undotree')
  use('tpope/vim-fugitive')
  use('lewis6991/gitsigns.nvim')
  use('yorickpeterse/nvim-pqf')
  use { 'akinsho/git-conflict.nvim', tag = "v1.2.2", config = function()
    require('git-conflict').setup()
  end }
  use('voldikss/vim-floaterm')
  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }
  use({
    "stevearc/oil.nvim",
    config = function()
      require("oil").setup()
    end,
  })
  use('ray-x/go.nvim')
  use('ray-x/guihua.lua') -- recommended if need floating window support
  use('ray-x/lsp_signature.nvim')

  -- Debugging
  use('jay-babu/mason-nvim-dap.nvim')
  use('mfussenegger/nvim-dap')
  use('leoluz/nvim-dap-go')
  use { "mxsdev/nvim-dap-vscode-js", requires = { "mfussenegger/nvim-dap" } }
  use {
    "microsoft/vscode-js-debug",
    opt = true,
    run = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out"
  }
  use { 'rcarriga/nvim-dap-ui', requires = { { 'mfussenegger/nvim-dap' } } }

  use {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v2.x',
    requires = {
      -- LSP Support
      { 'neovim/nvim-lspconfig' }, -- Required
      {
        -- Optional
        'williamboman/mason.nvim',
        run = ":MasonUpdate"
      },
      { 'williamboman/mason-lspconfig.nvim' }, -- Optional

      -- Autocompletion
      { 'hrsh7th/nvim-cmp' },     -- Required
      { 'hrsh7th/cmp-nvim-lsp' }, -- Required
      { 'L3MON4D3/LuaSnip' },     -- Required
    }
  }
end)
