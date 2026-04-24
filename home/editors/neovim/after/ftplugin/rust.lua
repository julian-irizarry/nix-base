local bufnr = vim.api.nvim_get_current_buf()
local map = vim.keymap.set

-- Code actions (with rust-analyzer grouping support)
map("n", "<leader>ca", function()
  vim.cmd.RustLsp "codeAction"
end, { silent = true, buffer = bufnr, desc = "Rust Code Action" })

map("v", "<leader>ca", function()
  vim.cmd.RustLsp "codeAction"
end, { silent = true, buffer = bufnr, desc = "Rust Code Action (Visual)" })

-- Hover actions (Override K to use rustaceanvim's hover)
map("n", "K", function()
  vim.cmd.RustLsp { "hover", "actions" }
end, { silent = true, buffer = bufnr, desc = "Rust Hover Actions" })

-- Runnables
map("n", "<leader>rr", function()
  vim.cmd.RustLsp "runnables"
end, { silent = true, buffer = bufnr, desc = "Rust Runnables" })

-- Debuggables (requires nvim-dap)
map("n", "<leader>rd", function()
  vim.cmd.RustLsp "debuggables"
end, { silent = true, buffer = bufnr, desc = "Rust Debuggables" })

-- Testables
map("n", "<leader>rt", function()
  vim.cmd.RustLsp "testables"
end, { silent = true, buffer = bufnr, desc = "Rust Testables" })

-- Expand macro
map("n", "<leader>rm", function()
  vim.cmd.RustLsp "expandMacro"
end, { silent = true, buffer = bufnr, desc = "Rust Expand Macro" })

-- Rebuild proc macros
map("n", "<leader>rp", function()
  vim.cmd.RustLsp "rebuildProcMacros"
end, { silent = true, buffer = bufnr, desc = "Rust Rebuild Proc Macros" })

-- Move item up/down
map("n", "<leader>rk", function()
  vim.cmd.RustLsp("moveItem", "up")
end, { silent = true, buffer = bufnr, desc = "Rust Move Item Up" })

map("n", "<leader>rj", function()
  vim.cmd.RustLsp("moveItem", "down")
end, { silent = true, buffer = bufnr, desc = "Rust Move Item Down" })

-- Open Cargo.toml
map("n", "<leader>rc", function()
  vim.cmd.RustLsp "openCargo"
end, { silent = true, buffer = bufnr, desc = "Rust Open Cargo.toml" })

-- Parent module
map("n", "<leader>rP", function()
  vim.cmd.RustLsp "parentModule"
end, { silent = true, buffer = bufnr, desc = "Rust Parent Module" })

-- Join lines
map("n", "<leader>rJ", function()
  vim.cmd.RustLsp "joinLines"
end, { silent = true, buffer = bufnr, desc = "Rust Join Lines" })

-- Structural search replace
map("n", "<leader>rs", function()
  vim.cmd.RustLsp "ssr"
end, { silent = true, buffer = bufnr, desc = "Rust Structural Search Replace" })

-- View crate graph
map("n", "<leader>rv", function()
  vim.cmd.RustLsp "crateGraph"
end, { silent = true, buffer = bufnr, desc = "Rust View Crate Graph" })

-- Explain error
map("n", "<leader>re", function()
  vim.cmd.RustLsp "explainError"
end, { silent = true, buffer = bufnr, desc = "Rust Explain Error" })

-- Render diagnostics
map("n", "<leader>rD", function()
  vim.cmd.RustLsp "renderDiagnostic"
end, { silent = true, buffer = bufnr, desc = "Rust Render Diagnostics" })

-- Open docs.rs
map("n", "<leader>ro", function()
  vim.cmd.RustLsp "openDocs"
end, { silent = true, buffer = bufnr, desc = "Rust Open docs.rs" })

-- Related diagnostics
map("n", "<leader>rR", function()
  vim.cmd.RustLsp "relatedDiagnostics"
end, { silent = true, buffer = bufnr, desc = "Rust Related Diagnostics" })
