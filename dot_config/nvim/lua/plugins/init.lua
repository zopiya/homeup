return {
  -- 1. Core Dependencies & Package Manager
  "nvim-lua/plenary.nvim",
  "nvim-tree/nvim-web-devicons",

  -- 2. Theme (Catppuccin)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- 3. UI Enhancements (Statusline & Keymaps)
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = { theme = "catppuccin" },
    },
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },

  -- 4. File Navigation (Telescope & Neo-tree & Flash)
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("config.telescope") end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
    },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },

  -- 5. Editing Efficiency (Mini.nvim Bundle)
  {
    "echasnovski/mini.nvim",
    version = false,
    config = function()
      require("mini.surround").setup() -- Fast surround (sa/sd/sr)
      require("mini.comment").setup()  -- Fast comment (gc)
      require("mini.pairs").setup()    -- Auto pairs
      require("mini.ai").setup()       -- Enhanced text objects (va)
    end,
  },

  -- 6. Syntax Highlighting & Git
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function() require("config.treesitter") end,
  },
  {
    "lewis6991/gitsigns.nvim",
    event = "User FilePost",
    opts = {},
  },

  -- 7. LSP & Completion (Lightweight)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function() require("config.lsp") end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function() require("config.cmp") end,
  },
}
