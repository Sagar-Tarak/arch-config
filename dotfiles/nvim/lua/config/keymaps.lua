-- ==============================================================================
-- Forge — Neovim Keymaps
-- LazyVim sets many defaults; these are Forge-specific additions/overrides.
-- ==============================================================================

local map = vim.keymap.set

-- Leader is set by LazyVim to <space>

-- --- Editing -----------------------------------------------------------------
map("n", "<C-s>",        "<cmd>w<cr><esc>",         { desc = "Save file" })
map("i", "<C-s>",        "<esc><cmd>w<cr>",          { desc = "Save file" })
map("n", "<leader>q",    "<cmd>qa<cr>",              { desc = "Quit all" })

-- Clear search highlight
map("n", "<Esc>",        "<cmd>noh<cr><Esc>",        { desc = "Clear highlight" })

-- --- Movement ----------------------------------------------------------------
-- Better up/down on wrapped lines
map({ "n", "v" }, "j",  "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Move down" })
map({ "n", "v" }, "k",  "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Move up" })

-- Move to start/end of line
map({ "n", "v" }, "H",  "^",                         { desc = "Start of line" })
map({ "n", "v" }, "L",  "$",                         { desc = "End of line" })

-- --- Windows -----------------------------------------------------------------
map("n", "<leader>wh",   "<C-w>h",                   { desc = "Focus left" })
map("n", "<leader>wj",   "<C-w>j",                   { desc = "Focus down" })
map("n", "<leader>wk",   "<C-w>k",                   { desc = "Focus up" })
map("n", "<leader>wl",   "<C-w>l",                   { desc = "Focus right" })
map("n", "<leader>w=",   "<C-w>=",                   { desc = "Equalise splits" })
map("n", "<leader>ws",   "<cmd>split<cr>",            { desc = "Split horizontal" })
map("n", "<leader>wv",   "<cmd>vsplit<cr>",           { desc = "Split vertical" })

-- --- Buffers -----------------------------------------------------------------
map("n", "<S-h>",        "<cmd>bprevious<cr>",        { desc = "Prev buffer" })
map("n", "<S-l>",        "<cmd>bnext<cr>",            { desc = "Next buffer" })
map("n", "<leader>bd",   "<cmd>bdelete<cr>",          { desc = "Delete buffer" })

-- --- Visual ------------------------------------------------------------------
-- Stay in visual mode after indent
map("v", "<",            "<gv",                       { desc = "Indent left" })
map("v", ">",            ">gv",                       { desc = "Indent right" })

-- Move selected lines
map("v", "J",            ":m '>+1<CR>gv=gv",         { desc = "Move line down" })
map("v", "K",            ":m '<-2<CR>gv=gv",         { desc = "Move line up" })

-- Paste without replacing register
map("v", "p",            '"_dP',                     { desc = "Paste (keep register)" })
