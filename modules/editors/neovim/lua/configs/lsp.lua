-- Shared LSP setup: capabilities, diagnostics, global LspAttach keymaps.
-- Server-specific config lives under ../../lsp/<name>.lua and is loaded by
-- vim.lsp.enable().

-- Bridge blink.cmp capabilities into every server. Guarded so this file
-- can be sourced even if blink.cmp hasn't loaded yet.
local ok, blink = pcall(require, "blink.cmp")
if ok then
  vim.lsp.config("*", {
    capabilities = blink.get_lsp_capabilities(),
  })
end

vim.lsp.enable {
  "nixd",
  "pyright",
  "clangd",
  "gopls",
  "bashls",
  "lua_ls",
  -- rust_analyzer intentionally omitted: owned by rustaceanvim.
}

vim.diagnostic.config {
  virtual_text = { spacing = 10 },
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
    focusable = false,
    style = "minimal",
    header = "",
    prefix = "",
  },
  underline = { severity = { min = vim.diagnostic.severity.INFO } },
}

vim.cmd [[highlight DiagnosticUnderlineError gui=undercurl]]
vim.cmd [[highlight DiagnosticUnderlineWarn  gui=undercurl]]
vim.cmd [[highlight DiagnosticUnderlineInfo  gui=undercurl]]
vim.cmd [[highlight DiagnosticUnderlineHint  gui=undercurl]]

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
  callback = function(args)
    local buf = args.buf
    local fzf = require "fzf-lua"
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
    end

    map("n", "gd", vim.lsp.buf.definition, "LSP go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "LSP go to declaration")
    map("n", "gi", vim.lsp.buf.implementation, "LSP go to implementation")
    map("n", "K", vim.lsp.buf.hover, "LSP hover")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP code action")
    map("n", "<leader>rn", vim.lsp.buf.rename, "LSP rename")
    map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "[d", function()
      vim.diagnostic.jump { count = -1, float = true }
    end, "Prev diagnostic")
    map("n", "]d", function()
      vim.diagnostic.jump { count = 1, float = true }
    end, "Next diagnostic")
    map("n", "<leader>gr", fzf.lsp_references, "LSP references (fzf)")
    map("n", "<leader>o", fzf.lsp_document_symbols, "LSP document symbols")
    map("n", "<leader>ci", fzf.lsp_incoming_calls, "LSP incoming calls")
    map("n", "<leader>co", fzf.lsp_outgoing_calls, "LSP outgoing calls")
  end,
})
