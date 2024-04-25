return {
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
  { -- Replace Netrw
    "stevearc/oil.nvim",
    event = "VimEnter",
    cmd = "Oil",
    opts = {
      view_options = {
        show_hidden = true,
      },
      default_file_explorer = true,
    },
    keys = {
      { "<leader>pv", "<CMD>Oil<CR>", { desc = "Open Parent Directory" } },
    },
  },
  -- 'gc' to comment visual regions/lines
  { "numToStr/Comment.nvim", opts = {} },
  { -- Useful plugin to show you pending keybinds.
    "folke/which-key.nvim",
    event = "VimEnter", -- Sets the loading event to 'VimEnter'
    config = function() -- This is the function that runs, AFTER loading
      require("which-key").setup({
        plugins = {
          presets = {
            g = false, -- bindings for prefixed with g
          },
        },
      })

      -- Document existing key chains
      require("which-key").register({
        ["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
        ["<leader>d"] = { name = "[D]iagnostic/[D]ocument", _ = "which_key_ignore" },
        ["<leader>g"] = { name = "[G]it/[G]o", _ = "which_key_ignore" },
        ["<leader>h"] = { name = "[H]unk", _ = "which_key_ignore" },
        ["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
        ["<leader>s"] = { name = "[S]earch", _ = "which_key_ignore" },
        ["<leader>w"] = { name = "[W]orkspace", _ = "which_key_ignore" },
      })
    end,
  },
  {
    "karb94/neoscroll.nvim",
    event = "BufEnter",
    opts = {
      mappings = {
        "<C-u>",
        "<C-d>",
      },
    },
  },

  { -- Highlight todo, notes, etc in comments
    "folke/todo-comments.nvim",
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = true },
  },

  { -- Collection of various small independent plugins/modules
    "echasnovski/mini.nvim",
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require("mini.ai").setup({ n_lines = 500 })

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require("mini.surround").setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require("mini.statusline")
      -- set use_icons to true if you have a Nerd Font
      statusline.setup({ use_icons = vim.g.have_nerd_font })

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return "%2l:%-2v"
      end

      require("mini.files").setup({
        mappings = {
          go_in_plus = "<CR>",
          close = "<ESC>",
        },
        options = {
          use_as_default_explorer = false,
        },
        windows = {
          preview = true,
          width_preview = 50,
        },
      })
      vim.keymap.set("n", "-", function()
        require("mini.files").open(vim.api.nvim_buf_get_name(0), false)
      end, { desc = "Open File Explorer at Parent" })

      -- ... and there is more!
      --  Check out: https://github.com/echasnovski/mini.nvim
    end,
  },

  { -- Highlight lines and changes that were undone or redone
    "tzachar/highlight-undo.nvim",
    event = "BufEnter",
    -- HACK: This plugin **MUST** come after mini.nvim because of u and <c-r> remaps
    -- https://github.com/tzachar/highlight-undo.nvim/issues/8#issuecomment-1595776700
    opts = {},
  },

  { -- Change case of text
    "johmsalas/text-case.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    opts = {},
    config = function(_, opts)
      require("textcase").setup(opts)
      require("telescope").load_extension("textcase")
    end,
    keys = {
      "ga", -- Default invocation prefix
      { "ga.", "<cmd>TextCaseOpenTelescope<CR>", mode = { "n", "s" }, desc = "Telescope" },
    },
    cmd = {
      -- NOTE: The Subs command name can be customized via the option 'substitude_command_name'
      "Subs",
      "TextCaseOpenTelescope",
      "TextCaseOpenTelescopeQuickChange",
      "TextCaseOpenTelescopeLSPChange",
      "TextCaseStartReplacingCommand",
    },
    -- If you want to use the interactive feature of the `Subs` command right away, text-case.nvim
    -- has to be loaded on startup. Otherwise, the interactive feature of the `Subs` will only be
    -- available after the first executing of it or after a keymap of text-case.nvim has been used.
    lazy = true,
  },
  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope").load_extension("git_worktree")
    end,
    keys = {
      { "<leader>gw", "<cmd>Telescope git_worktree<cr>", desc = "[G]it [W]orktree" },
      {
        "<leader>gwc",
        function()
          require("telescope").extensions.git_worktree.create_git_worktree()
        end,
        desc = "[G]it [W]orktree [C]reate",
      },
    },
  },
  {
    "crnvl96/lazydocker.nvim",
    opts = {},
    keys = {
      { "<leader>ld", "<cmd>LazyDocker<cr>", desc = "[L]azy [D]ocker" },
    },
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
  },
  "tpope/vim-dotenv",
  { -- Pretty Quick Fix Lists
    "yorickpeterse/nvim-pqf",
    opts = {},
  },
  {
    "ggandor/leap.nvim",
    keys = {
      { "m", "<Plug>(leap-forward)", mode = { "n", "x", "o" }, desc = "Leap Forward" },
      { "M", "<Plug>(leap-backward)", mode = { "n", "x", "o" }, desc = "Leap Backward" },
      { "ms", "<Plug>(leap-from-window)", mode = { "n", "x", "o" }, desc = "Leap From Window" },
    },
  },
  {
    "vyfor/cord.nvim",
    build = "./build",
    event = "VeryLazy",
    opts = {},
  },
}
