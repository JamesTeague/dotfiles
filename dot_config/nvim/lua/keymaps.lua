-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Disable Arrow Keys to break habit
vim.keymap.set({ 'n', 'i', 'v' }, '<Up>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<Down>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<Right>', '<nop>')
vim.keymap.set({ 'n', 'i', 'v' }, '<Left>', '<nop>')

-- Disable Keys from fat-fingering to something not useful
vim.keymap.set('n', 'Q', '<nop>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Keybinds for rearranging lines
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move line(s) down' })
vim.keymap.set('v', 'K', ":m '>-2<CR>gv=gv", { desc = 'Move line(s) up' })
vim.keymap.set('n', 'J', 'mxJ`z', { desc = 'Join line below' })

-- Keybinds to move about buffer
vim.keymap.set('n', '<C-d>', '<C-d>zz', { desc = 'Scroll down half page' })
vim.keymap.set('n', '<C-u>', '<C-u>zz', { desc = 'Scroll up half page' })

-- Keybinds to extend yank
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]], { desc = 'Yank to clipboard' })
vim.keymap.set('n', '<leader>Y', [["+Y]], { desc = 'Yank to end of line to clipboard' })

-- Keybinds to modify files
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true, desc = 'Add [X] to file permission' })
