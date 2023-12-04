vim.g.markdown_fencede_languages = {
  "ts=typescript"
}

local lsp = require('lsp-zero').preset("recommended")

lsp.ensure_installed({
  'tsserver',
  'eslint',
  'lua_ls',
  'rust_analyzer',
  'jedi_language_server',
  'gopls',
  'volar',
})

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
  ['<C-m>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
  ['<CR>'] = cmp.mapping.confirm({ select = true }),
  ['<C-Space>'] = cmp.mapping.complete(),
})

lsp.setup_nvim_cmp({
  mapping = cmp_mappings
})

lsp.on_attach(function(_, bufnr)
  --  lsp.default_keymaps({buffer = bufnr})
  --  local opts = {buffer = bufnr, remap = false}
  lsp.buffer_autoformat()
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end,
    { buffer = bufnr, remap = false, desc = "Go to definition" })
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end,
    { buffer = bufnr, remap = false, desc = "Hover for cursor" })
  vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end,
    { buffer = bufnr, remap = false, desc = "workspace_symbol" })
  vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end,
    { buffer = bufnr, remap = false, desc = "open_float" })
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end,
    { buffer = bufnr, remap = false, desc = "Go to Next" })
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end,
    { buffer = bufnr, remap = false, desc = "Go to Previous" })
  vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end,
    { buffer = bufnr, remap = false, desc = "Signature Help" })
  vim.keymap.set("n", "<leader>re", function() vim.lsp.buf.rename() end,
    { buffer = bufnr, remap = false, desc = "Rename Variable" })
  vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end,
    { buffer = bufnr, remap = false, desc = "Code Action" })
  vim.keymap.set("n", "<leader>rr", function() vim.lsp.buf.references() end,
    { buffer = bufnr, remap = false, desc = "Find usages" })
end)

lsp.set_sign_icons({
  error = '✘',
  warn = '▲',
  hint = '⚑',
  info = '»'
})

-- (Optional) Configure lua language server for neovim
local lspconfig = require('lspconfig')

lspconfig.lua_ls.setup(lsp.nvim_lua_ls())

lspconfig.denols.setup {
  root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc"),
}

lspconfig.tsserver.setup {
  root_dir = lspconfig.util.root_pattern("package.json"),
  single_file_support = false
}

lsp.setup()

vim.diagnostic.config({
  virtual_text = true
})
