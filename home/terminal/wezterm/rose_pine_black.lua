-- Custom color scheme based on kitty's Rosé Pine with black background
local rose_pine_black = {
	-- Default colors
	foreground = "#dddddd",
	background = "#000000",

	-- Selection colors
	selection_fg = "#e0def4",
	selection_bg = "#403d52",

	-- Cursor colors
	cursor_fg = "#e0def4",
	cursor_bg = "#524f67",

	-- Tab bar colors
	tab_bar = {
		background = "#000000",
		active_tab = {
			bg_color = "#26233a",
			fg_color = "#e0def4",
		},
		inactive_tab = {
			bg_color = "#000000",
			fg_color = "#6e6a86",
		},
		new_tab = {
			bg_color = "#191724",
			fg_color = "#6e6a86",
		},
		new_tab_hover = {
			bg_color = "#1f1d2e",
			fg_color = "#908caa",
		},
	},

	-- Terminal colors (index 0-15)
	ansi = {
		"#26233a", -- black
		"#eb6f92", -- red
		"#31748f", -- green
		"#f6c177", -- yellow
		"#9ccfd8", -- blue
		"#c4a7e7", -- magenta
		"#ebbcba", -- cyan
		"#e0def4", -- white
	},
	brights = {
		"#6e6a86", -- bright black
		"#eb6f92", -- bright red
		"#31748f", -- bright green
		"#f6c177", -- bright yellow
		"#9ccfd8", -- bright blue
		"#c4a7e7", -- bright magenta
		"#ebbcba", -- bright cyan
		"#e0def4", -- bright white
	},
}

return rose_pine_black
