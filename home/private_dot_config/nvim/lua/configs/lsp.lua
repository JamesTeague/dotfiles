local signs = { Error = "", Warn = "", Hint = "󰌵", Info = "" }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local config = {
  signs = {
    active = signs,
  },
  inlay_hints = {
    enabled = true,
  },
  update_in_insert = true,
  underline = true,
  severity_sort = true,
  float = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  },
}

vim.diagnostic.config(config)

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("teague-lsp-attach", { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
    end

    -- NOTE: Want to disable virtual_text because of the lsp_lines plugin.
    vim.diagnostic.config({ virtual_text = false })
    vim.lsp.inlay_hint.enable()

    local builtin = require("telescope.builtin")

    --  To jump back, press <C-t>.
    map("gd", builtin.lsp_definitions, "[G]oto [D]efinition")
    map("gr", builtin.lsp_references, "[G]oto [R]eferences")
    map("gi", builtin.lsp_implementations, "[G]oto [I]mplementation")
    map("<leader>D", builtin.lsp_type_definitions, "Type [D]efinition")
    map("<leader>ds", builtin.lsp_document_symbols, "[D]ocument [S]ymbols")
    map("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header
    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    map("<leader>dh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, "[D]isplay [H]ints")

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client.server_capabilities.documentHighlightProvider then
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        buffer = event.buf,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        buffer = event.buf,
        callback = vim.lsp.buf.clear_references,
      })
    end
  end,
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

local servers = {
  gopls = {
    ["ui.inlayhint.hints"] = {
      compositeLiteralFields = true,
      constantValues = true,
      parameterNames = true,
    },
  },
  ts_ls = {},
  lua_ls = {
    settings = {
      Lua = {
        hint = {
          enable = true,
        },
        completion = {
          callSnippet = "Replace",
        },
        diagnostics = { disable = { "missing-fields" } },
        workspace = {
          checkThirdParty = "Disable",
        },
      },
    },
  },
}

require("mason").setup()

local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  "stylua",
  "golines",
  "goimports",
})
require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

require("mason-lspconfig").setup({
  handlers = {
    function(server_name)
      local server = servers[server_name] or {}

      server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
      require("lspconfig")[server_name].setup(server)
    end,
  },
})
