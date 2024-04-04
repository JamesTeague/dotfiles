-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  {
    -- NOTE: Yes, you can install new plugins here!
    'mfussenegger/nvim-dap',
    -- NOTE: And you can specify dependencies as well
    dependencies = {
      -- Creates a beautiful debugger UI
      'rcarriga/nvim-dap-ui',

      -- Installs the debug adapters for you
      'williamboman/mason.nvim',
      'jay-babu/mason-nvim-dap.nvim',

      'nvim-neotest/nvim-nio',

      -- Add your own debuggers here
      'leoluz/nvim-dap-go',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      require('mason-nvim-dap').setup {
        -- Makes a best effort to setup the various debuggers with
        -- reasonable debug configurations
        automatic_setup = true,

        -- You can provide additional configuration to the handlers,
        -- see mason-nvim-dap README for more information
        handlers = {},

        -- You'll need to check that you have the required things installed
        -- online, please don't ask me how to install them :)
        ensure_installed = {
          -- Update this to ensure that you have the debuggers for the langs you want
          'delve',
          'node2',
        },
      }

      -- Basic debugging keymaps, feel free to change to your liking!
      vim.keymap.set('n', '<F9>', dap.continue, { desc = 'Debug: Start/Continue' })
      vim.keymap.set('n', '<F7>', dap.step_into, { desc = 'Debug: Step Into' })
      vim.keymap.set('n', '<F8>', dap.step_over, { desc = 'Debug: Step Over' })
      vim.keymap.set('n', '<F6>', dap.step_out, { desc = 'Debug: Step Out' })
      vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
      vim.keymap.set('n', '<leader>B', function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end, { desc = 'Debug: Set Breakpoint' })
      vim.keymap.set('n', '<leader>bc', function()
        dap.clear_breakpoints()
        require('notify')('Breakpoints cleared', 'warn')
      end, { desc = 'Debug: Clear Breakpoints' })
      vim.keymap.set('n', '<leader>bl', function()
        dap.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))
      end, { desc = 'Debug: Set Logpoint' })


      vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DapBreakpoint' })
      vim.fn.sign_define('DapBreakpointCondition', { text = '◉', texthl = 'DapBreakpoint' })
      vim.fn.sign_define('DapBreakpointRejected', { text = '', texthl = 'DapBreakpoint' })
      vim.fn.sign_define('DapLogPoint', { text = '', texthl = 'DapLogPoint' })
      vim.fn.sign_define('DapStopped', { text = '', texthl = 'DapStopped' })


      -- Dap UI setup
      -- For more information, see |:help nvim-dap-ui|
      dapui.setup {
        -- Set icons to characters that are more likely to work in every terminal.
        --    Feel free to remove or use ones that you like more! :)
        --    Don't feel like these are good choices.
        icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
        controls = {
          icons = {
            pause = '⏸',
            play = '▶',
            step_into = '⏎',
            step_over = '⏭',
            step_out = '⏮',
            step_back = 'b',
            run_last = '▶▶',
            terminate = '⏹',
            disconnect = '⏏',
          },
        },
      }

      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      vim.keymap.set('n', '<F5>', dapui.toggle, { desc = 'Debug: See last session result.' })

      dap.listeners.after.event_initialized['dapui_config'] = dapui.open
      dap.listeners.before.event_terminated['dapui_config'] = dapui.close
      dap.listeners.before.event_exited['dapui_config'] = dapui.close

      -- Install golang specific config
      require('dap-go').setup({
        dap_configurations = {
          -- {
          --   -- Must be "go" or it will be ignored by the plugin
          --   type = "go",
          --   name = "Attach remote",
          --   mode = "remote",
          --   request = "attach",
          -- },
          -- {
          --   -- Must be "go" or it will be ignored by the plugin
          --   type = "go",
          --   name = "Attach remote with port",
          --   mode = "remote",
          --   request = "attach",
          --   port = function()
          --     return vim.fn.input("Enter listening port:")
          --   end,
          -- },
          {
            name = "Project Workflows",
            type = "go",
            request = "launch",
            mode = "debug",
            program = "${workspaceFolder}/cmd/project_workflows/",
            args = { "start" },
            env = { ENVIRONMENT_NAME = "local" },
          },
          {
            name = "Project Workflows w/ Localstack",
            type = "go",
            request = "launch",
            mode = "debug",
            program = "${workspaceFolder}/cmd/project_workflows/",
            args = { "start", "--env-file", "${workspaceFolder}/.env.local" },
            env = { ENVIRONMENT_NAME = "local" },
          },
          {
            name = "Rendering Service",
            type = "go",
            request = "launch",
            mode = "debug",
            program = "${workspaceFolder}/cmd/rendering_service/",
            args = { "start" },
            env = {
              ENVIRONMENT_NAME = "local",
            },
          },
          {
            name = "Rendering Service w/ Localstack",
            type = "go",
            request = "launch",
            mode = "debug",
            program = "${workspaceFolder}/cmd/rendering_service/",
            args = { "start", "--env-file", "${workspaceFolder}/.env.local" },
            env = { ENVIRONMENT_NAME = "local" },
          },
          {
            name = "Shadow Detection",
            type = "go",
            request = "launch",
            mode = "debug",
            program = "${workspaceFolder}/cmd/sync_cli/",
            args = { "shadowdetection", "--env-file", "${workspaceFolder}/.env.local.shadow" },
            env = { ENVIRONMENT_NAME = "local" },
          },
        },
        delve = {
          -- additional args to pass to dlv
          args = { "--check-go-version=false" },
        },
      })
    end,
  },
  'theHamsta/nvim-dap-virtual-text',
}
