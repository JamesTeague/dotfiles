local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "rd", function()
  vim.cmd.RustLsp({ "renderDiagnostic", "current" })
end, {
  silent = true,
  buffer = bufnr,
  desc = "Display a hover window with the rendered diagnostic, as displayed during cargo build",
})

vim.keymap.set("n", "<leader>em", function()
  vim.cmd.RustLsp("expandMacro")
end, { silent = true, buffer = bufnr, desc = "Expand macros recursively" })

vim.keymap.set("n", "<leader>ee", function()
  vim.cmd.RustLsp({ "explainError", "current" })
end, {
  silent = true,
  buffer = bufnr,
  desc = "Display a hover window with explanations from the rust error codes index over error diagnostics.",
})

vim.keymap.set("n", "<leader>oc", function()
  vim.cmd.RustLsp("openCargo")
end, { silent = true, buffer = bufnr, desc = "Open Cargo.toml" })

vim.keymap.set("n", "<leader>od", function()
  vim.cmd.RustLsp("openDocs")
end, { silent = true, buffer = bufnr, desc = "Open docs.rs documentation for the symbol under the cursor." })
