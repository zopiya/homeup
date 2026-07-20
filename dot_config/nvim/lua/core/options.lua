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
opt.sidescrolloff = 8

-- Encoding
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"

-- Performance
opt.updatetime = 250     -- 更快的 CursorHold 触发（默认 4000ms）
opt.timeoutlen = 300     -- which-key 弹出延迟

-- Completion menu
opt.pumheight = 10       -- 补全下拉菜单最多显示 10 条
opt.completeopt = "menu,menuone,noselect"  -- nvim-cmp 需要：有候选才显示，不自动选中
