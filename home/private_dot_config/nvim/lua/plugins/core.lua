return {
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
  { -- Replace Netrw
    "stevearc/oil.nvim",
    event = "VimEnter",
    cmd = "Oil",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      view_options = {
        show_hidden = true,
        natural_order = true,
      },
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      keymaps = {
        ["<C-h>"] = false,
        ["<M-h>"] = "actions.select_split",
      },
    },
    keys = {
      { "-", "<CMD>Oil<CR>", { desc = "Open Parent Directory" } },
      { "<leader>-", ":lua require('oil').toggle_float()<CR>", { desc = "Open Parent Directory in floating window" } },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      lsp = {
        signature = {
          enabled = false,
        },
      },
    },
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module='...'` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      -- "rcarriga/nvim-notify",
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
      require("which-key").add({

        { "<leader>c", group = "[C]ode" },
        { "<leader>d", group = "[D]iagnostic/[D]ocument" },
        { "<leader>g", group = "[G]it/[G]o" },
        { "<leader>h", group = "[H]unk" },
        { "<leader>r", group = "[R]ename" },
        { "<leader>s", group = "[S]earch" },
        { "<leader>w", group = "[W]orkspace" },
      })
    end,
  },
  -- {
  --   "karb94/neoscroll.nvim",
  --   event = "BufEnter",
  --   opts = {
  --     mappings = {
  --       "<C-u>",
  --       "<C-d>",
  --     },
  --   },
  -- },
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
    "polarmutex/git-worktree.nvim",
    version = "^2",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      local Hooks = require("git-worktree.hooks")
      local config = require("git-worktree.config")

      Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
        vim.notify("Moved from " .. prev_path .. " to " .. path)
        -- check if current buffer is an oil buffer
        if vim.fn.expand("%"):find("^oil:///") then
          -- switch to new cwd in oil
          require("oil").open(vim.fn.getcwd())
        else
          -- use built in hook for non oil buffers
          Hooks.builtins.update_current_buffer_on_switch(path, prev_path)
        end
      end)

      Hooks.register(Hooks.type.DELETE, function()
        vim.cmd(config.update_on_change_command)
      end)
      require("telescope").load_extension("git_worktree")
    end,
    keys = {
      {
        "gw",
        function()
          require("telescope").extensions.git_worktree.git_worktree()
        end,
        desc = "[G]it [W]orktree",
      },
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
    enabled = false,
  },
  "tpope/vim-dotenv",
  { -- Pretty Quick Fix Lists
    "yorickpeterse/nvim-pqf",
    opts = {},
  },
  {
    "vyfor/cord.nvim",
    build = "./build",
    event = "VeryLazy",
    opts = {},
    enabled = false,
  },
  {
    "sphamba/smear-cursor.nvim",
    opts = {},
  },
}
