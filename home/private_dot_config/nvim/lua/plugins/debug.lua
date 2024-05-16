return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
      "nvim-neotest/nvim-nio",
      "leoluz/nvim-dap-go",
      "mxsdev/nvim-dap-vscode-js",
      {
        "microsoft/vscode-js-debug",
        build = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
      },
    },
    config = function()
      require("configs.dap")
    end,
  },
  "theHamsta/nvim-dap-virtual-text",
}
