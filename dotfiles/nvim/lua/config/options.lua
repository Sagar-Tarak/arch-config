-- ==============================================================================
-- Forge — Neovim Options
-- These run before lazy.nvim so LazyVim's defaults can override where needed.
-- ==============================================================================

local opt = vim.opt

-- Line numbers
opt.number         = true
opt.relativenumber = true

-- Tabs / indentation
opt.tabstop        = 2
opt.softtabstop    = 2
opt.shiftwidth     = 2
opt.expandtab      = true
opt.smartindent    = true

-- Wrapping
opt.wrap           = false

-- Scroll
opt.scrolloff      = 8
opt.sidescrolloff  = 8

-- Search
opt.ignorecase     = true
opt.smartcase      = true
opt.hlsearch       = true
opt.incsearch      = true

-- Appearance
opt.signcolumn     = "yes"
opt.colorcolumn    = "80"
opt.termguicolors  = true
opt.cursorline     = true
opt.showmode       = false   -- LazyVim status line shows mode

-- Splits
opt.splitright     = true
opt.splitbelow     = true

-- Clipboard
opt.clipboard      = "unnamedplus"

-- Undo
opt.undofile       = true
opt.undolevels     = 10000

-- Update time (faster CursorHold)
opt.updatetime     = 250
opt.timeoutlen     = 300

-- Completion
opt.completeopt    = "menu,menuone,noselect"

-- Files
opt.swapfile       = false
opt.backup         = false
