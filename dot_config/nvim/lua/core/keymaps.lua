vim.g.mapleader = " "
vim.g.maplocalleader = " "

local keymap = vim.keymap

-- General Keymaps
keymap.set("i", "jk", "<ESC>") -- Exit insert mode with jk
keymap.set("n", "<leader>nh", ":nohl<CR>") -- Clear search highlights
keymap.set("n", "x", '"_x') -- Delete single char without copying into register

-- Fast Save & Quit
keymap.set("n", "<leader>w", ":w<CR>")
keymap.set("n", "<leader>q", ":q<CR>")

-- Window Navigation (Better than <C-w>h/j/k/l)
keymap.set("n", "<C-h>", "<C-w>h")
keymap.set("n", "<C-j>", "<C-w>j")
keymap.set("n", "<C-k>", "<C-w>k")
keymap.set("n", "<C-l>", "<C-w>l")

-- Move Lines (Visual Mode)
keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Window Management
keymap.set("n", "<leader>sv", "<C-w>v") -- Split vertically
keymap.set("n", "<leader>sh", "<C-w>s") -- Split horizontally
keymap.set("n", "<leader>se", "<C-w>=") -- Make split windows equal width
keymap.set("n", "<leader>sx", ":close<CR>") -- Close current split window

-- Tabs
keymap.set("n", "<leader>to", ":tabnew<CR>") -- Open new tab
keymap.set("n", "<leader>tx", ":tabclose<CR>") -- Close current tab
keymap.set("n", "<leader>tn", ":tabn<CR>") -- Go to next tab
keymap.set("n", "<leader>tp", ":tabp<CR>") -- Go to previous tab

-- Plugin Keymaps (Telescope)
keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>")
keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>")
keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>")
keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>")
