return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/neotest-go",
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			-- Your other test adapters here
		},
		config = function()
			require("neotest").setup({
				diagnostic = {
					enabled = true,
					severity = 4,
				},
				adapters = {
					require("neotest-go"),
				},
			})
			vim.keymap.set("n", "<leader>tm", require("neotest").run.run, { desc = "[T]est [M]ethod" })
			vim.keymap.set("n", "<leader>tf", function()
				require("neotest").run.run(vim.fn.expand("%"))
			end, { desc = "[T]est [F]ile" })
			vim.keymap.set("n", "<leader>td", function()
				require("neotest").run.run(vim.fn.input("Path to Directory:"))
			end, { desc = "[T]est [D]irectory" })
			vim.keymap.set("n", "<leader>ts", function()
				require("neotest").run.run(vim.fn.getcwd())
			end, { desc = "[T]est [S]uite" })
		end,
	},
}
