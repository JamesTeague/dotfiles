return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("lualine").setup({
      sections = {
        lualine_y = {
          {
            require("pomodoro").statusline,
            cond = function()
              if string.find(require("pomodoro").statusline(), "inactive") then
                return false
              else
                return true
              end
            end,
          },
        },
      },
      inactive_sections = {
        lualine_y = {},
      },
    })
  end,
}
