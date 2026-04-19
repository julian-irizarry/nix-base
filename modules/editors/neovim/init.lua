vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, vim.tbl_deep_extend("force", lazy_config, {
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
}))


-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "nvchad.autocmds"

-- Initialize transparency state and apply it
if vim.g.__transparent_on == nil then
  vim.g.__transparent_on = true -- default to transparency ON
  vim.schedule(function()
    pcall(function() require("base46").toggle_transparency() end)
  end)
end

vim.api.nvim_create_user_command("Toggle", function(opts)
  if opts.args == "transparency" then
    local ok = pcall(function() require("base46").toggle_transparency() end)
    if not ok then
      -- ignore persistence error; ensure highlights are reapplied
      pcall(function() require("base46").load_all_highlights() end)
    end
    vim.g.__transparent_on = not vim.g.__transparent_on
  else
    vim.notify("Unknown toggle: " .. opts.args, vim.log.levels.WARN)
  end
end, { nargs = 1, complete = function() return { "transparency" } end })
vim.cmd("cnoreabbrev togt Toggle transparency")

vim.g.__zen_mode = vim.g.__zen_mode or false

vim.api.nvim_create_user_command("Zen", function()
  if vim.g.__zen_mode then
    -- turn OFF zen mode
    vim.fn.jobstart("zen") -- calls your Kitty zen script
    if vim.g.__transparent_on then
      vim.cmd("Toggle transparency") -- restore only if it was enabled
    end
    vim.g.__zen_mode = false
    vim.notify("Zen mode OFF")
  else
    -- turn ON zen mode
    vim.fn.jobstart("zen")
    if not vim.g.__transparent_on then
      vim.cmd("Toggle transparency") -- enable only if off
    end
    vim.g.__zen_mode = true
    vim.notify("Zen mode ON")
  end
end, {})

vim.schedule(function()
  require "mappings"
end)

