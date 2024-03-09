return {
  {
    'theHamsta/nvim-dap-virtual-text',
    config = function ()
      require("nvim-dap-virtual-text").setup()
    end
  },
  'jay-babu/mason-nvim-dap.nvim',
  'mfussenegger/nvim-dap',
  {
    'leoluz/nvim-dap-go',
    config = function ()
      require('dap-go').setup {
        -- Additional dap configurations can be added.
        -- dap_configurations accepts a list of tables where each entry
        -- represents a dap configuration. For more details do:
        -- :help dap-configuration
        dap_configurations = {
          {
            -- Must be "go" or it will be ignored by the plugin
            type = "go",
            name = "Attach remote",
            mode = "remote",
            request = "attach",
          },
          {
            -- Must be "go" or it will be ignored by the plugin
            type = "go",
            name = "Attach remote with port",
            mode = "remote",
            request = "attach",
            port = function()
              return vim.fn.input("Enter listening port:")
            end,
          },
        },
        -- delve configurations
        delve = {
          -- the path to the executable dlv which will be used for debugging.
          -- by default, this is the "dlv" executable on your PATH.
          path = "dlv",
          -- time to wait for delve to initialize the debug session.
          -- default to 20 seconds
          initialize_timeout_sec = 20,
          -- a string that defines the port to start delve debugger.
          -- default to string "${port}" which instructs nvim-dap
          -- to start the process in a random available port
          port = "38697",
          -- additional args to pass to dlv
          args = {},
          -- the build flags that are passed to delve.
          -- defaults to empty string, but can be used to provide flags
          -- such as "-tags=unit" to make sure the test suite is
          -- compiled during debugging, for example.
          -- passing build flags using args is ineffective, as those are
          -- ignored by delve in dap mode.
          build_flags = "",
        },
      }

    end
  },
  {
    'mxsdev/nvim-dap-vscode-js',
    dependencies = { "mfussenegger/nvim-dap" },
    config = function ()
      require("dap-vscode-js").setup({
        -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
        -- debugger_path = "(runtimedir)/site/pack/packer/opt/vscode-js-debug", -- Path to vscode-js-debug installation.
        -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
        adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
        -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
        -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
        -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
      })
    end,
  },
  {
    'rcarriga/nvim-dap-ui',
    dependencies = { { 'mfussenegger/nvim-dap' } },
    config = function ()
      local dap = require('dap')
      local ui = require('dapui')

      vim.keymap.set("n", "<F9>", dap.continue, { desc = "Continue" })
      vim.keymap.set("n", "<F8>", dap.step_over, { desc = "Step Over" })
      vim.keymap.set("n", "<F7>", dap.step_into, { desc = "Step Into" })
      vim.keymap.set("n", "<F6>", dap.step_out, { desc = "Step Out" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>B", function()
        dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
      end, { desc = "Breakpoint with condition" })
      vim.keymap.set("n", "<leader>lp", function()
        dap.set_breakpoint(vim.fn.input(nil, nil, vim.fn.input('Log point message: ')))
      end, { desc = "Log point with message" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
      vim.keymap.set("n", "<leader>dd", function()
        dap.continue()
        ui.toggle({})
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false) -- Spaces buffers evenly
      end, { desc = "Start Debugger" })
      vim.keymap.set("n", "<leader>dc", function()
        dap.clear_breakpoints()
        --  require("notify")("Breakpoints cleared", "warn")
      end, { desc = "Clear breakpoints" })
      vim.keymap.set("n", "<leader>st", function()
        -- dap.clear_breakpoints()
        ui.toggle({})
        dap.terminate()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false)
        --  require("notify")("Debugger session ended", "warn")
      end, { desc = "Stop Debugger" })

      require("mason").setup()
      require("mason-nvim-dap").setup({
        ensure_installed = {
          "delve",
          "node2",
        }
      })

      dap.set_log_level('INFO')

      dap.adapters.go = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. '/mason/bin/dlv',
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. '/mason/bin/codelldb',
          args = { "--port", "${port}" }
        }
      }

      ui.setup({
        icons = { expanded = "▾", collapsed = "▸" },
        mappings = {
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
        expand_lines = vim.fn.has("nvim-0.7"),
        layouts = {
          {
            elements = {
              "repl",
            },
            size = 0.3,
            position = "right"
          },
          {
            elements = {
              {
                id = "watches",
                size = 0.4,
              },
              {
                id = "scopes",
                size = 0.4,
              },
              {
                id = "breakpoints",
                size = 0.2,
              },
            },
            size = 0.3,
            position = "bottom",
          },
        },
        floating = {
          max_height = nil,
          max_width = nil,
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        windows = { indent = 1 },
        render = {
          max_type_length = nil,
        },
      })
      vim.fn.sign_define('DapBreakpoint', { text = '🔴' })
    end
  },
}
