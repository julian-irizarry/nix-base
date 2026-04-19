-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "pastelbeans",
  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },

    St_sep_r = { fg = "ffffffff", bg = "#252525" },
    St_Lsp = { fg = "ffffffff", bg = "#252525" },
    St_LspHints = { fg = "ffffffff", bg = "#252525" },
    St_LspMsg = { fg = "ffffffff", bg = "#252525" },
    St_gitIcons = { fg = "ffffffff", bg = "#252525" },
    St_lspWarning = { fg = "ffffffff", bg = "#252525" },
    St_lspError = { fg = "ffffffff", bg = "#252525" },
  },
}

local sep_l = "█"

local function gen_block(icon, txt, sep_l_hlgroup, iconHl_group, txt_hl_group)
  return sep_l_hlgroup .. sep_l .. iconHl_group .. icon .. txt_hl_group .. " " .. txt
end

-- Noice provides search / command / mode statusline APIs. Wrap them with a
-- pcall so the statusline still renders if noice hasn't loaded yet.
local function noice_status(component)
  local ok, noice = pcall(require, "noice")
  if not ok or not noice.api.status[component].has() then
    return ""
  end
  return "%#St_Pos_txt# " .. noice.api.status[component].get() .. " "
end

M.ui = {
  statusline = {
    theme = "minimal",
    separator_style = "block",
    order = {
      "mode",
      "cwd",
      "file",
      "git",
      "%=",
      "%=",
      "noice_cmd",
      "noice_mode",
      "noice_search",
      "diagnostics",
      "lsp",
      "line_percent",
    },
    modules = {
      line_percent = function()
        return gen_block(" ", "%p%% ", "%#St_Pos_sep#", "%#St_Pos_bg#", "%#St_Pos_txt#")
      end,
      noice_cmd = function()
        return noice_status "command"
      end,
      noice_mode = function()
        return noice_status "mode"
      end,
      noice_search = function()
        return noice_status "search"
      end,
    },
  },

  tabufline = { enabled = false },
}

return M
