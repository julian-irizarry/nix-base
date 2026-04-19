require "nvchad.mappings"

local map = vim.keymap.set

-- Smart splits navigation (seamless nvim/wezterm pane navigation)
map("n", "<C-h>", require("smart-splits").move_cursor_left, { desc = "Move to left split/pane" })
map("n", "<C-j>", require("smart-splits").move_cursor_down, { desc = "Move to below split/pane" })
map("n", "<C-k>", require("smart-splits").move_cursor_up, { desc = "Move to above split/pane" })
map("n", "<C-l>", require("smart-splits").move_cursor_right, { desc = "Move to right split/pane" })

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")
map("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" })

-- Basic clipboard interaction
map({ "n", "x" }, "gy", '"+y') -- copy
map({ "n", "x" }, "gp", '"+p') -- paste

-- move visually selected text up/down
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

-- better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- newline w/o leaving normal mode
map("n", "<leader>o", 'o<ESC>0"_D', { desc = "newline w/o leaving normal" })
map("n", "<leader>O", 'O<ESC>0"_D', { desc = "newline w/o leaving normal" })

-- Shortcuts
map({ "n", "x", "o" }, "<leader>h", "^") -- beginning of line
map({ "n", "x", "o" }, "<leader>l", "g_") -- end of line
map("n", "<leader>a", ":keepjumps normal! ggVG<cr>")

map("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "undo tree toggle" })

map("n", "<C-t>", function()
  require("nvchad.themes").open()
end)

local fzf = require "fzf-lua"
map("n", "<leader>?", fzf.oldfiles, { desc = "FzfLua Find Recent Files" })
map("n", "<leader><space>", fzf.buffers, { desc = "FzfLua List Buffers" })
map("n", "<leader>ff", fzf.files, { desc = "FzfLua Find Files" })
map("n", "<leader>fn", function()
  fzf.files {
    cwd = vim.fn.stdpath "config",
  }
end, { desc = "FzfLua Find Neovim Config" })
map("n", "<leader>fp", function()
  fzf.files {
    cwd = vim.fn.stdpath "data" .. "/lazy",
  }
end, { desc = "FzfLua Find Plugin Source" })
local fd_dir_cmd = vim.fn.executable "fd" == 1 and "fd --type d"
  or vim.fn.executable "fdfind" == 1 and "fdfind --type d"
  or "find . -type d -not -path '*/\\.*'"

local function live_grep_in(opts)
  opts = opts or {}
  fzf.live_grep(vim.tbl_extend("force", {
    cwd_header = true,
    actions = {
      ["ctrl-d"] = {
        fn = function(_, o)
          local query = o.last_query or ""
          fzf.fzf_exec(fd_dir_cmd, {
            prompt = "Switch dir> ",
            actions = {
              ["default"] = function(selected)
                if selected and #selected > 0 then
                  live_grep_in { cwd = vim.fn.fnamemodify(selected[1], ":p"), query = query }
                end
              end,
            },
          })
        end,
        desc = "change-directory",
      },
    },
  }, opts))
end

map("n", "<leader>fg", live_grep_in, { desc = "FzfLua Search with Live Grep (ctrl-d to change dir)" })
map("n", "<leader>fd", fzf.diagnostics_document, { desc = "FzfLua Show Diagnostics" })
map("n", "<leader>fs", fzf.git_status, { desc = "FzfLua Git Status" })
map("n", "<leader>fb", fzf.files, { desc = "FzfLua Find Files (File Browser)" })
map("n", "<leader>fS", fzf.lsp_document_symbols, { desc = "FzfLua Show LSP Document Symbols" })
map("n", "<leader>fh", fzf.help_tags, { desc = "FzfLua Search Help Tags" })
map("n", "<leader>sk", fzf.keymaps, { desc = "FzfLua Search Keymaps" })
map("n", "<leader>fw", fzf.grep_cword, { desc = "FzfLua Search Word Under Cursor" })
map("v", "<leader>fw", fzf.grep_visual, { noremap = true, silent = true, desc = "FzfLua Search Selected Text" })

-- Definitions and references
map("n", "gd", "<cmd>Lspsaga goto_definition<CR>", { desc = "Lspsaga Go to [D]efinition" })
-- map("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { desc = "Lspsaga [P]eek Definition" })

-- Hover and documentation
map("n", "shift+k", "<cmd>Lspsaga hover_doc<CR>", { desc = "Lspsaga [H]over Documentation" })

-- Diagnostics
map("n", "gl", "<cmd>Lspsaga show_line_diagnostics<CR>", { desc = "Lspsaga Show Line [D]iagnostics" })
map("n", "]d", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { desc = "Lspsaga Jump to Previous [D]iagnostic" })
map("n", "[d", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Lspsaga Jump to Next [D]iagnostic" })

-- Code actions
map("n", "<leader>ca", "<cmd>Lspsaga code_action<CR>", { desc = "Lspsaga Trigger [C]ode [A]ction" })
map(
  "v",
  "<leader>ca",
  "<cmd>Lspsaga code_action<CR>",
  { noremap = true, silent = true, desc = "Lspsaga Trigger [C]ode [A]ction (Visual)" }
)

map("n", "<leader>gs", fzf.git_status, { desc = "FzfLua Search Git Status" })

-- Rename
map("n", "<leader>rn", "<cmd>Lspsaga rename<CR>", { desc = "Lspsaga [R]e[n]ame Symbol" })

-- Symbol outline
map("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { desc = "Lspsaga Toggle Symbol [O]utline" })

-- Finder
map("n", "<leader>gr", "<cmd>Lspsaga finder<CR>", { desc = "Lspsaga [F]ind References and Definitions" })

-- Call hierarchy
map("n", "<leader>ci", "<cmd>Lspsaga incoming_calls<CR>", { desc = "Lspsaga [C]all Hierarchy: [I]ncoming" })
map("n", "<leader>co", "<cmd>Lspsaga outgoing_calls<CR>", { desc = "Lspsaga [C]all Hierarchy: [O]utgoing" })

-- Key mappings for navigating diagnostics and showing floats
map("n", "[d", "<cmd>Lspsaga diagnostic_jump_next<cr>", { desc = "Goto Prev [d]iagnostic" })
map("n", "]d", "<cmd>Lspsaga diagnostic_jump_prev<cr>", { desc = "Goto Prev [d]iagnostic" })

-- Folding keybindings
map("n", "<leader>cf", "zc", { desc = "Fold current function/class" })
map("n", "<leader>uf", "zo", { desc = "Unfold current function/class" })
map("n", "<leader>fa", "zR", { desc = "Unfold all" })
map("n", "<leader>fz", "zM", { desc = "Fold all" })

-- buffer commands
-- map("n", ";", ":", { desc = "CMD enter command mode" })
map("n", "<leader>x", ":bdelete<CR>", { desc = "Close current buffer" })
map("n", "<leader><tab>", ":bnext<CR>", { desc = "Cycle through open buffers" })

-- run current line(s)
map("n", "<leader>c", ":.lua<CR>", { desc = "Execute selected line" })
map("v", "<leader>c", ":lua<CR>", { desc = "Execute selected lines" })

map("n", "<C-q>", ":q<CR>", { desc = "Close neovim" })

-- Gitsigns hunk navigation
map("n", "[c", "<cmd>Gitsigns next_hunk<CR>", { desc = "Next hunk" })
map("n", "]c", "<cmd>Gitsigns prev_hunk<CR>", { desc = "Prev hunk" })

local nomap = vim.keymap.del
nomap("i", "<C-b>")
nomap("i", "<C-e>")
nomap("n", "<C-n>")
nomap("n", "<leader>v")
