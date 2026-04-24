require "nvchad.options"

-- add yours here!
vim.g.have_nerd_font = true
vim.opt.splitright = true

-- vim.opt.list = true
-- vim.opt.listchars = { trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

vim.o.clipboard = ""

vim.opt.number = true
vim.opt.mouse = "a"
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.wrap = true
vim.opt.breakindent = true

vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = false

vim.opt.signcolumn = "yes"
vim.o.statuscolumn = "%C%l%=%s"
vim.opt.termguicolors = true
vim.opt.cmdheight = 0

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath "data" .. "/undo"
vim.opt.undofile = true

-- vim.opt.timeoutlen = 180

vim.opt.scrolloff = 8

vim.opt.smartindent = true
vim.opt.autoindent = true

-- Use Treesitter for folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldtext = ""
vim.opt.foldenable = false -- Start with all folds open
vim.opt.foldlevel = 20

vim.o.cursorlineopt = "both" -- to enable cursorline!
local group = vim.api.nvim_create_augroup("user_cmds", { clear = true })

vim.api.nvim_create_user_command("ReloadConfig", "source $MYVIMRC", {})

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight on yank",
  group = group,
  callback = function()
    vim.highlight.on_yank { higroup = "Visual", timeout = 200 }
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "help", "man" },
  group = group,
  command = "nnoremap <buffer> q <cmd>quit<cr>",
})

-- nvim 0.12 drops file-write msg_show events before noice's ui_attach sees
-- them, so :w produced no toast. Emit our own via BufWritePost.
vim.api.nvim_create_autocmd("BufWritePost", {
  desc = "Toast on save",
  group = group,
  callback = function(args)
    vim.notify(vim.fn.fnamemodify(args.file, ":~:."), vim.log.levels.INFO, { title = "Saved" })
  end,
})
