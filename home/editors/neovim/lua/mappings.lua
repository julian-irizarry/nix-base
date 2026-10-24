require "nvchad.mappings"

local map = vim.keymap.set

-- Seamless nvim split / terminal pane navigation: herdr-splits inside herdr
-- panes, smart-splits elsewhere. Both expose the same move_cursor_* API.
local in_herdr = vim.env.HERDR_ENV == "1"
local splits = require(in_herdr and "herdr-splits" or "smart-splits")
map("n", "<C-h>", splits.move_cursor_left, { desc = "Move to left split/pane" })
map("n", "<C-j>", splits.move_cursor_down, { desc = "Move to below split/pane" })
map("n", "<C-k>", splits.move_cursor_up, { desc = "Move to above split/pane" })
map("n", "<C-l>", splits.move_cursor_right, { desc = "Move to right split/pane" })
if in_herdr then
  -- herdr forwards alt+hjkl here; these shadow NvChad's <A-h> terminal toggle.
  map("n", "<M-h>", splits.resize_left, { desc = "Resize split/pane left" })
  map("n", "<M-j>", splits.resize_down, { desc = "Resize split/pane down" })
  map("n", "<M-k>", splits.resize_up, { desc = "Resize split/pane up" })
  map("n", "<M-l>", splits.resize_right, { desc = "Resize split/pane right" })
end

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

map("n", "<leader>gs", fzf.git_status, { desc = "FzfLua Search Git Status" })

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

-- <C-g> prints bufname() as remembered (often a relative path). Force the
-- full-path variant so file info is unambiguous regardless of how the buffer
-- was opened.
map("n", "<C-g>", "1<C-g>", { desc = "Show full file path + status" })

-- Quit
map("n", "<leader>q", "<cmd>qa<CR>", { desc = "Quit all" })
map("n", "<leader>Q", "<cmd>qa!<CR>", { desc = "Quit all (force)" })

-- Clear search highlights
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Gitsigns hunk navigation
map("n", "[c", "<cmd>Gitsigns prev_hunk<CR>", { desc = "Prev hunk" })
map("n", "]c", "<cmd>Gitsigns next_hunk<CR>", { desc = "Next hunk" })

local nomap = vim.keymap.del
nomap("i", "<C-b>")
nomap("i", "<C-e>")
nomap("n", "<C-n>")
nomap("n", "<leader>v")
