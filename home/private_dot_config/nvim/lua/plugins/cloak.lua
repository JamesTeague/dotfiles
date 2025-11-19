return {
  "laytan/cloak.nvim",
  keys = {
    { "<leader>cl", ":CloakToggle<CR>", { desc = "Toggle Cloak" } },
  },
  opts = {
    enabled = true,
    cloak_character = "*",
    -- The applied highlight group (colors) on the cloaking, see `:h highlight`.
    highlight_group = "Comment",
    patterns = {
      {
        file_pattern = {
          ".env*",
          "wrangler.toml",
          ".dev.vars",
        },
        -- Match an equals sign and any character after it.
        -- This can also be a table of patterns to cloak,
        -- example: cloak_pattern = { ':.+', '-.+' } for yaml files.
        cloak_pattern = "=.+",
      },
    },
  },
}
