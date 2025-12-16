require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "pyright",
    "ts_ls",
    "bashls",
    "jsonls",
  },
})

local status_ok, lspconfig = pcall(require, "lspconfig")
if not status_ok then
  return
end

local cmp_nvim_lsp = require("cmp_nvim_lsp")

local capabilities = cmp_nvim_lsp.default_capabilities()

local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  local keymap = vim.keymap

  keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
  keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  keymap.set("n", "K", vim.lsp.buf.hover, opts)
  keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  keymap.set("n", "gr", vim.lsp.buf.references, opts)
end

lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
})

lspconfig.pyright.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

lspconfig.ts_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

lspconfig.bashls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})

lspconfig.jsonls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
})
