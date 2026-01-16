local opt = vim.opt

-- Line numbers
opt.relativenumber = true
opt.number = true

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Line Wrapping
opt.wrap = false

-- Search settings
opt.ignorecase = true
opt.smartcase = true

-- Cursor line
opt.cursorline = true

-- Appearance
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

-- Clipboard
opt.clipboard:append("unnamedplus")

-- Split windows
opt.splitright = true
opt.splitbelow = true

-- Undo & Scroll
opt.undofile = true
opt.scrolloff = 8

-- Encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
