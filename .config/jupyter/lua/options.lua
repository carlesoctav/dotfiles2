local opt = vim.opt

-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- number and relative numeber
opt.number = true
opt.relativenumber = true

-- better split
opt.splitbelow = true
opt.splitright = true

-- tab thingy
opt.wrap = false
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4

opt.autoindent = true
opt.smartindent = true

-- buat search
opt.virtualedit = "block"
opt.inccommand = "split"
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- using undofile
opt.swapfile = false
opt.backup = false
opt.undofile = true

-- other
opt.termguicolors = true
opt.scrolloff = 8
opt.signcolumn = "yes"
-- opt.list = true
-- opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.cursorline = true
opt.showmode = false
