local dap = require("dap")
local dapui = require("dapui")

require("mason-nvim-dap").setup({
  automatic_setup = true,
  handlers = {},
  ensure_installed = {
    "delve",
    "node2",
    "codelldb",
    "cpptools",
  },
})

require("dap-vscode-js").setup({
  debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
  adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
})

for _, language in ipairs({ "typescript", "javascript", "typescriptreact" }) do
  dap.configurations[language] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
      sourceMaps = true,
    },
    {
      type = "pwa-chrome",
      request = "launch",
      name = "Launch Chrome against localhost",
      url = "http://localhost:3000",
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
      trace = true,
      userDataDir = "${workspaceFolder}/.vscode/vscode-chrome-debug-userdatadir",
    },
  }
end

vim.keymap.set("n", "<F9>", dap.continue, { desc = "Debug: Start/Continue" })
vim.keymap.set("n", "<F7>", dap.step_into, { desc = "Debug: Step Into" })
vim.keymap.set("n", "<F8>", dap.step_over, { desc = "Debug: Step Over" })
vim.keymap.set("n", "<F6>", dap.step_out, { desc = "Debug: Step Out" })
vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
vim.keymap.set("n", "<leader>B", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Debug: Set Breakpoint" })
vim.keymap.set("n", "<leader>bc", function()
  dap.clear_breakpoints()
  require("notify")("Breakpoints cleared", "warn")
end, { desc = "Debug: Clear Breakpoints" })
vim.keymap.set("n", "<leader>bl", function()
  dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, { desc = "Debug: Set Logpoint" })

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◉", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped" })

dapui.setup({
  icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
  controls = {
    icons = {
      pause = "⏸",
      play = "▶",
      step_into = "⏎",
      step_over = "⏭",
      step_out = "⏮",
      step_back = "b",
      run_last = "▶▶",
      terminate = "⏹",
      disconnect = "⏏",
    },
  },
})

vim.keymap.set("n", "<F5>", dapui.toggle, { desc = "Debug: See last session result." })

dap.listeners.after.event_initialized["dapui_config"] = dapui.open
dap.listeners.before.event_terminated["dapui_config"] = dapui.close
dap.listeners.before.event_exited["dapui_config"] = dapui.close

require("dap-go").setup({
  dap_configurations = {
    -- Add Specific Configurations Here
  },
  delve = {
    -- additional args to pass to dlv
    args = { "--check-go-version=false" },
  },
})
