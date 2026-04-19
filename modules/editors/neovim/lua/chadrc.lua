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
local sep_r = "%#St_sep_r#" .. "█" .. " %#ST_EmptySpace#"

local function gen_block(icon, txt, sep_l_hlgroup, iconHl_group, txt_hl_group)
  return sep_l_hlgroup .. sep_l .. iconHl_group .. icon .. txt_hl_group .. " " .. txt
end

local function search_indicator()
  if vim.v.hlsearch == 0 then
    return ""
  end

  local result = vim.fn.searchcount { recompute = 1 }
  if vim.tbl_isempty(result) then
    return ""
  end

  if result.incomplete == 1 then
    return string.format(" /%s [?/??]", vim.fn.getreg "/")
  elseif result.incomplete == 2 then
    if result.total > result.maxcount and result.current > result.maxcount then
      return string.format(" /%s [>%d/>%d]", vim.fn.getreg "/", result.current, result.total)
    elseif result.total > result.maxcount then
      return string.format(" /%s [%d/>%d]", vim.fn.getreg "/", result.current, result.total)
    end
  end
  return string.format(" %d/%d ", result.current, result.total)
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
      "lsp_msg",
      "%=",
      "search_indicator",
      "diagnostics",
      "lsp",
      "neocodeium",
      "line_percent",
    },
    modules = {
      line_percent = function()
        return gen_block(" ", "%p%% ", "%#St_Pos_sep#", "%#St_Pos_bg#", "%#St_Pos_txt#")
      end,
      search_indicator = function()
        return "%#St_Pos_txt#" .. " " .. search_indicator()
      end,
      neocodeium = function()
        local ok, neocodeium = pcall(require, "neocodeium")
        if not ok then
          return ""
        end
        local status, server_status = neocodeium.get_status()
        local status_icons = {
          [0] = "󰚩", -- Enabled
          [1] = "󱚧", -- Disabled Globally
          [2] = "󱙻", -- Disabled for Buffer
          [3] = "󱙺", -- Disabled filetype
          [4] = "󱙺", -- Disabled filter
          [5] = "󱚠", -- Wrong encoding
          [6] = "󱚠", -- Special buftype
        }
        local server_icons = {
          [0] = "", -- Connected
          [1] = "", -- Connecting
          [2] = "", -- Disconnected
        }
        if status == 0 and server_status == 0 then
          return "%#St_Pos_txt#" .. (status_icons[status] or "") .. (server_icons[server_status] or "") .. " "
        end
        return ""
      end,
    },
  },

  tabufline = { enabled = false },

  cmp = {
    lspkind_text = true,
    style = "atom", -- default/flat_light/flat_dark/atom/atom_colored
    format_colors = {
      tailwind = false,
    },
  },
}

return M
