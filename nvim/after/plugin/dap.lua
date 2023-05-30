local dap = require('dap')
local ui = require('dapui')

vim.keymap.set("n", "<F9>", dap.continue)
vim.keymap.set("n", "<F8>", dap.step_over)
vim.keymap.set("n", "<F7>", dap.step_into)
vim.keymap.set("n", "<F6>", dap.step_out)
vim.keymap.set("n", "<F6>", dap.step_out)
vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
vim.keymap.set("n", "<leader>B", function()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end)
vim.keymap.set("n", "<leader>lp", function()
  dap.set_breakpoint(vim.fn.input(nil, nil, vim.fn.input('Log point message: ')))
end)
vim.keymap.set("n", "<leader>dr", dap.repl.open)
vim.keymap.set("n", "<leader>dd", function()
  dap.continue()
  ui.toggle({})
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false) -- Spaces buffers evenly
end)
vim.keymap.set("n", "<leader>dc", function()
  dap.clear_breakpoints()
  --  require("notify")("Breakpoints cleared", "warn")
end)
vim.keymap.set("n", "<leader>st", function()
  dap.clear_breakpoints()
  ui.toggle({})
  dap.terminate()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false)
  --  require("notify")("Debugger session ended", "warn")
end)

require("mason-nvim-dap").setup({
  ensure_installed = {
    "delve",
    "node2",
    "js-debug-adapter",
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
        "scopes",
      },
      size = 0.3,
      position = "right"
    },
    {
      elements = {
        "repl",
        "breakpoints"
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
