return {
  {
    "theprimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    config = function()
      local harpoon = require("harpoon")

      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end, { desc = "[A]dd file to Harpoon" })
      vim.keymap.set("n", "<C-S-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Toggle Harpoon Menu" })

      vim.keymap.set("n", "<C-j>", function()
        harpoon:list():select(1)
      end, { desc = "Jump to first file in Harpoon" })
      vim.keymap.set("n", "<C-k>", function()
        harpoon:list():select(2)
      end, { desc = "Jump to second file in Harpoon" })
      vim.keymap.set("n", "<C-l>", function()
        harpoon:list():select(3)
      end, { desc = "Jump to third file in Harpoon" })
      vim.keymap.set("n", "<C-;>", function()
        harpoon:list():select(4)
      end, { desc = "Jump to fourth file in Harpoon" })

      -- basic telescope configuration
      local conf = require("telescope.config").values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        local make_finder = function()
          local paths = {}

          for _, item in ipairs(harpoon_files.items) do
            table.insert(paths, item.value)
          end

          return require("telescope.finders").new_table({
            results = paths,
          })
        end

        require("telescope.pickers")
          .new({}, {
            prompt_title = "Harpoon",
            finder = require("telescope.finders").new_table({
              results = file_paths,
            }),
            previewer = conf.file_previewer({}),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_buffer_number, map)
              -- The keymap you need
              map("i", "<c-d>", function()
                local state = require("telescope.actions.state")
                local selected_entry = state.get_selected_entry()
                local current_picker = state.get_current_picker(prompt_buffer_number)

                -- This is the line you need to remove the entry
                harpoon:list():remove(selected_entry)
                current_picker:refresh(make_finder())
              end)

              return true
            end,
          })
          :find()
      end

      vim.keymap.set("n", "<C-e>", function()
        toggle_telescope(harpoon:list())
      end, { desc = "Open harpoon window" })
    end,
  },
}
