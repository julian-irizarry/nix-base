-- this line for types, by hovering and autocompletion (lsp required)
-- will help you understanding properties, fields, and what highlightings the color used for
---@type Base46Table
local M = {}

M.base_30 = {
  white = "#D4D4D4", -- vscFront
  black = "#1F1F1F", -- vscBack
  darker_black = "#1B1B1B", -- 6% darker than black
  black2 = "#252526", -- vscLeftDark
  one_bg = "#2D2D2D", -- vscTabOther
  one_bg2 = "#373737", -- vscLeftMid
  one_bg3 = "#636369", -- vscLeftLight
  grey = "#898989", -- vscSplitLight
  grey_fg = "#BBBBBB", -- vscPopupFront
  grey_fg2 = "#AEAFAD", -- vscCursorLight
  light_grey = "#D4D4D4", -- vscFront
  red = "#F44747", -- vscRed
  baby_pink = "#D16969", -- vscLightRed
  pink = "#C586C0", -- vscPink
  line = "#1F1F1F", -- 15% lighter than black
  green = "#6A9955", -- vscGreen
  vibrant_green = "#4B5632", -- vscDiffGreenLight
  nord_blue = "#569CD6", -- vscBlue
  blue = "#18a2fe", -- vscPopupHighlightBlue
  seablue = "#18a2fe", -- vscMediumBlue
  yellow = "#DCDCAA", -- vscYellow
  sun = "#FFD602", -- vscDarkYellow
  purple = "#646695", -- vscViolet
  dark_purple = "#4B1818", -- vscDiffRedDark
  teal = "#4EC9B0", -- vscBlueGreen
  orange = "#CE9178", -- vscOrange
  cyan = "#9CDCFE", -- vscLightBlue
  statusline_bg = "#272727", -- vscPopupBack
  lightbg = "#252526", -- vscLeftDark
  pmenu_bg = "#272727", -- vscPopupBack
  folder_bg = "#569CD6" -- vscBlue
}

M.base_16 = {
  base00 = "#1F1F1F", -- Default Background (vscBack)
  base01 = "#2D2D2D", -- Lighter Background (Used for status bars, line number, and folding marks) (vscTabOther)
  base02 = "#252526", -- Selection Background (vscLeftDark)
  base03 = "#373737", -- Comments, Invisibles, Line Highlighting (vscLeftMid)
  base04 = "#636369", -- Dark Foreground (Used for status bars) (vscLeftLight)
  base05 = "#D4D4D4", -- Default Foreground, Caret, Delimiters, Operators (vscFront)
  base06 = "#AEAFAD", -- Light Foreground (Not often used) (vscCursorLight)
  base07 = "#BBBBBB", -- Light Background (Not often used) (vscPopupFront)
  base08 = "#569CD6", -- Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted (vscRed)
  base09 = "#CE9178", -- Integers, Boolean, Constants, XML Attributes, Markup Link Url (vscOrange)
  base0A = "#DCDCAA", -- Classes, Markup Bold, Search Text Background (vscYellow)
  base0B = "#6A9955", -- Strings, Inherited Class, Markup Code, Diff Inserted (vscGreen)
  base0C = "#4EC9B0", -- Support, Regular Expressions, Escape Characters, Markup Quotes (vscBlueGreen)
  base0D = "#569CD6", -- Functions, Methods, Attribute IDs, Headings (vscBlue)
  base0E = "#C586C0", -- Keywords, Storage, Selector, Markup Italic, Diff Changed (vscPink)
  base0F = "#D7BA7D", -- Deprecated, Opening/Closing Embedded Language Tags (vscYellowOrange)
}

M.polish_hl = {
  -- Treesitter highlights
  -- treesitter = {
  --   ["@error"] = { fg = M.base_30.red, bg = "NONE" },
  --   ["@punctuation.bracket"] = { fg = M.base_30.white, bg = "NONE" },
  --   ["@punctuation.special"] = { fg = M.base_30.white, bg = "NONE" },
  --   ["@punctuation.delimiter"] = { fg = M.base_30.white, bg = "NONE" },
  --   ["@comment"] = { fg = M.base_30.green, bg = "NONE", italic = true },
  --   ["@comment.note"] = { fg = M.base_30.blue_green, bg = "NONE", bold = true },
  --   ["@comment.warning"] = { fg = M.base_30.yellow, bg = "NONE", bold = true },
  --   ["@comment.error"] = { fg = M.base_30.red, bg = "NONE", bold = true },
  --   ["@constant"] = { fg = M.base_30.accent_blue, bg = "NONE" },
  --   ["@constant.builtin"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@constant.macro"] = { fg = M.base_30.blue_green, bg = "NONE" },
  --   ["@string.regexp"] = { fg = M.base_30.orange, bg = "NONE" },
  --   ["@string"] = { fg = M.base_30.orange, bg = "NONE" },
  --   ["@character"] = { fg = M.base_30.orange, bg = "NONE" },
  --   ["@number"] = { fg = M.base_30.light_green, bg = "NONE" },
  --   ["@number.float"] = { fg = M.base_30.light_green, bg = "NONE" },
  --   ["@boolean"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@annotation"] = { fg = M.base_30.yellow, bg = "NONE" },
  --   ["@attribute"] = { fg = M.base_30.yellow, bg = "NONE" },
  --   ["@attribute.builtin"] = { fg = M.base_30.blue_green, bg = "NONE" },
  --   ["@module"] = { fg = M.base_30.blue_green, bg = "NONE" },
  --   ["@function"] = { fg = M.base_30.yellow, bg = "NONE" },
  --   ["@function.builtin"] = { fg = M.base_30.yellow, bg = "NONE" },
  --   ["@function.macro"] = { fg = M.base_30.yellow, bg = "NONE" },
  --   ["@function.method"] = { fg = M.base_30.yellow, bg = "NONE" },
  --   ["@define"] = { fg = M.base_30.pink, bg = "NONE" },
  --   ["@variable"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@variable.builtin"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@variable.parameter"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@variable.parameter.reference"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@variable.member"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@property"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@constructor"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@label"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@keyword"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@keyword.conditional"] = { fg = M.base_30.pink, bg = "NONE" },
  --   ["@keyword.repeat"] = { fg = M.base_30.pink, bg = "NONE" },
  --   ["@keyword.return"] = { fg = M.base_30.pink, bg = "NONE" },
  --   ["@keyword.exception"] = { fg = M.base_30.pink, bg = "NONE" },
  --   ["@keyword.import"] = { fg = M.base_30.pink, bg = "NONE" },
  --   ["@operator"] = { fg = M.base_30.white, bg = "NONE" },
  --   ["@type"] = { fg = M.base_30.blue_green, bg = "NONE" },
  --   ["@type.qualifier"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@structure"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@tag"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@tag.builtin"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@tag.delimiter"] = { fg = M.base_30.grey, bg = "NONE" },
  --   ["@tag.attribute"] = { fg = M.base_30.cyan, bg = "NONE" },
  --   ["@text"] = { fg = M.base_30.white, bg = "NONE" },
  --   ["@markup.strong"] = { fg = M.base_30.blue, bg = "NONE", bold = true },
  --   ["@markup.italic"] = { fg = M.base_30.white, bg = "NONE", italic = true },
  --   ["@markup.underline"] = { fg = M.base_30.yellow, bg = "NONE", underline = true },
  --   ["@markup.strikethrough"] = { fg = M.base_30.white, bg = "NONE", strikethrough = true },
  --   ["@markup.heading"] = { fg = M.base_30.blue, bg = "NONE", bold = true },
  --   ["@markup.raw"] = { fg = M.base_30.white, bg = "NONE" },
  --   ["@markup.raw.markdown"] = { fg = M.base_30.orange, bg = "NONE" },
  --   ["@markup.raw.markdown_inline"] = { fg = M.base_30.orange, bg = "NONE" },
  --   ["@markup.link.label"] = { fg = M.base_30.cyan, bg = "NONE", underline = true },
  --   ["@markup.link.url"] = { fg = M.base_30.white, bg = "NONE", underline = true },
  --   ["@markup.list.checked"] = { link = "Todo" },
  --   ["@markup.list.unchecked"] = { link = "Todo" },
  --   ["@textReference"] = { fg = M.base_30.orange },
  --   ["@stringEscape"] = { fg = M.base_30.orange, bold = true },
  --   ["@diff.plus"] = { link = "DiffAdd" },
  --   ["@diff.minus"] = { link = "DiffDelete" },
  --   ["@diff.delta"] = { link = "DiffChange" },
  -- },
  --
  -- lsp = {
  --   ["@type.builtin"] = { fg = M.base_30.blue, bg = "NONE" },
  --   ["@lsp.typemod.type.defaultLibrary"] = { link = "@type.builtin" },
  --   ["@lsp.type.type"] = { link = "@type" },
  --   ["@lsp.type.typeParameter"] = { link = "@type" },
  --   ["@lsp.type.macro"] = { link = "@constant" },
  --   ["@lsp.type.enumMember"] = { link = "@constant" },
  --   ["@lsp.typemod.variable.readonly"] = { link = "@constant" },
  --   ["@lsp.typemod.property.readonly"] = { link = "@constant" },
  --   ["@lsp.typemod.variable.constant"] = { link = "@constant" },
  --   ["@lsp.type.member"] = { link = "@function" },
  --   ["@lsp.type.keyword"] = { link = "@keyword" },
  --   ["@lsp.typemod.keyword.controlFlow"] = { fg = M.base_30.pink, bg = "NONE" },
  --   ["@lsp.type.comment.c"] = { fg = M.base_30.dim_highlight, bg = "NONE" },
  --   ["@lsp.type.comment.cpp"] = { fg = M.base_30.dim_highlight, bg = "NONE" },
  --   ["@event"] = { link = "Identifier" },
  --   ["@interface"] = { link = "Identifier" },
  --   ["@modifier"] = { link = "Identifier" },
  --   ["@regexp"] = { fg = M.base_30.red, bg = "NONE" },
  --   ["@decorator"] = { link = "Identifier" },
  -- },
  --
  -- Python specific highlights
  treesitter = {
    ["@statement.python"] = { fg = M.base_30.white, bg = "NONE" }, -- Statements like `if`, `else`, `while`, etc.
    ["pythonOperator"] = { fg = M.base_30.white, bg = "NONE" }, -- Operators like `+`, `-`, etc.
    ["pythoException"] = { fg = M.base_30.white, bg = "NONE" }, -- Exception keywords like `try`, `except`
    ["pythonExClass"] = { fg = M.base_30.white, bg = "NONE" }, -- Class definitions
    ["pythonBuiltinObj"] = { fg = M.base_30.white, bg = "NONE" }, -- Built-in objects like `str`, `list`
    ["pythonBuiltinType"] = { fg = M.base_30.white, bg = "NONE" }, -- Built-in types like `int`, `float`
    ["pythonBoolean"] = { fg = M.base_30.white, bg = "NONE" }, -- Boolean values like `True`, `False`
    ["@none.python"] = { fg = M.base_30.white, bg = "NONE" }, -- Constants like `None`
    ["pythonTodo"] = { fg = M.base_30.white, bg = "NONE" }, -- Todo comments
    ["pythonClassVar"] = { fg = M.base_30.white, bg = "NONE" }, -- Class variables
    ["pythonClassDef"] = { fg = M.base_30.white, bg = "NONE" }, -- Class definitions
    ["@constructor.python"] = { fg = M.base_30.red, bg = "NONE" }, -- Constructor methods
  },
}

M.type = "dark"

M = require("base46").override_theme(M, "new_vscode")

return M
