local M = {}

function M.setup_core()
  require("nvim-treesitter").install {
    "bash",
    "c",
    "cpp",
    "go",
    "lua",
    "markdown",
    "markdown_inline",
    "nix",
    "python",
    "rust",
    "vim",
    "vimdoc",
  }

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("user_treesitter_highlight", { clear = true }),
    callback = function(args)
      local lang = vim.treesitter.language.get_lang(args.match)
      if lang and pcall(vim.treesitter.start, args.buf, lang) then
        vim.bo[args.buf].syntax = ""
      end
    end,
  })

  M._wire_incremental_selection()
end

function M.setup_textobjects()
  require("nvim-treesitter-textobjects").setup {
    select = { lookahead = true },
  }

  local select = require("nvim-treesitter-textobjects.select").select_textobject
  local map = vim.keymap.set
  local pairs_list = {
    { "a=", "@assignment.outer", "Outer assignment" },
    { "i=", "@assignment.inner", "Inner assignment" },
    { "l=", "@assignment.lhs", "Assignment LHS" },
    { "r=", "@assignment.rhs", "Assignment RHS" },
    { "aa", "@parameter.outer", "Outer parameter" },
    { "ia", "@parameter.inner", "Inner parameter" },
    { "ai", "@conditional.outer", "Outer conditional" },
    { "ii", "@conditional.inner", "Inner conditional" },
    { "al", "@loop.outer", "Outer loop" },
    { "il", "@loop.inner", "Inner loop" },
    { "af", "@call.outer", "Outer call" },
    { "if", "@call.inner", "Inner call" },
    { "am", "@function.outer", "Outer function" },
    { "im", "@function.inner", "Inner function" },
    { "ac", "@class.outer", "Outer class" },
    { "ic", "@class.inner", "Inner class" },
  }
  for _, p in ipairs(pairs_list) do
    map({ "x", "o" }, p[1], function()
      select(p[2], "textobjects")
    end, { desc = p[3] })
  end

  local repeat_move = require "nvim-treesitter-textobjects.repeatable_move"
  map({ "n", "x", "o" }, ";", repeat_move.repeat_last_move_next, { desc = "Repeat last textobject move (next)" })
  map({ "n", "x", "o" }, ",", repeat_move.repeat_last_move_previous, { desc = "Repeat last textobject move (prev)" })
  map({ "n", "x", "o" }, "f", repeat_move.builtin_f_expr, { expr = true })
  map({ "n", "x", "o" }, "F", repeat_move.builtin_F_expr, { expr = true })
  map({ "n", "x", "o" }, "t", repeat_move.builtin_t_expr, { expr = true })
  map({ "n", "x", "o" }, "T", repeat_move.builtin_T_expr, { expr = true })
end

-- Incremental selection: <C-space> starts/expands, <BS> shrinks.
function M._wire_incremental_selection()
  local stack = {}

  local function visual_range(node)
    local sr, sc, er, ec = node:range()
    vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
    vim.cmd "normal! v"
    vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
  end

  local function reselect(node)
    local sr, sc, er, ec = node:range()
    vim.cmd "normal! o"
    vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
    vim.cmd "normal! o"
    vim.api.nvim_win_set_cursor(0, { er + 1, math.max(ec - 1, 0) })
  end

  vim.keymap.set("n", "<C-space>", function()
    local node = vim.treesitter.get_node()
    if not node then
      return
    end
    stack = { node }
    visual_range(node)
  end, { desc = "TS: start incremental selection" })

  vim.keymap.set("x", "<C-space>", function()
    local node = stack[#stack]
    if not node then
      return
    end
    local parent = node:parent()
    if not parent then
      return
    end
    table.insert(stack, parent)
    reselect(parent)
  end, { desc = "TS: expand incremental selection" })

  vim.keymap.set("x", "<BS>", function()
    if #stack <= 1 then
      return
    end
    table.remove(stack)
    reselect(stack[#stack])
  end, { desc = "TS: shrink incremental selection" })
end

return M
