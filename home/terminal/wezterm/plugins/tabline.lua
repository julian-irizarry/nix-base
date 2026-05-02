local wezterm = require("wezterm")
local ssh = require("utils.ssh")

local M = {}

local function is_claude_code(pane)
	local title = pane.title or ""
	if title:find("Claude Code") then
		return true
	end
	-- Claude Code titles: braille spinner icon (U+2800-U+28FF) or ✳ (U+2733)
	-- followed by a space. Both are 3-byte UTF-8 starting with 0xE2.
	local b1, b2 = title:byte(1, 2)
	return b1 == 0xE2 and (b2 == 0x9C or (b2 >= 0xA0 and b2 <= 0xA3)) and title:byte(4) == 0x20
end

function M.setup(bell_tabs)
	local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "iTerm2 Pastel Dark Background",
			theme_overrides = {
				normal_mode = {
					a = { bg = "#ff9da4" },
					b = { bg = "#000000" },
					c = { bg = "#000000" },
					x = { bg = "#000000" },
					y = { bg = "#000000" },
					z = { bg = "#ff9da4" },
				},
				tab = {
					active = { fg = "#ffffff", bg = "#1a1826" },
					inactive = { bg = "#000000" },
					inactive_hover = { bg = "#18162a" },
				},
			},
			tabs_enabled = true,
			section_separators = "",
			component_separators = "",
			tab_separators = {
				left = wezterm.nerdfonts.pl_left_hard_divider,
				right = wezterm.nerdfonts.pl_right_hard_divider,
			},
		},
		sections = {
			-- Show MODE only when in a special key table (copy_mode, search_mode, etc.)
			tabline_a = {
				{
					"mode",
					cond = function(window)
						local kt = window:active_key_table()
						return kt ~= nil and kt ~= "" and kt ~= "normal_mode"
					end,
					fmt = function(s)
						return s:gsub("_mode$", "")
					end,
				},
			},
			tabline_b = {},
			tabline_c = { " " },

			tab_active = {
				"",
				{ Foreground = { Color = "#E8885C" } },
				function(tab)
					if not is_claude_code(tab.active_pane) then
						return ""
					end
					return (tab.active_pane.title or ""):match("^(%S+)%s") or ""
				end,
				"ResetAttributes",
				{
					"process",
					icons_only = true,
					process_to_icon = {
						nvim = { wezterm.nerdfonts.custom_neovim, color = { fg = "#a6e3a1" } },
						ssh = { wezterm.nerdfonts.md_server, color = { fg = "#f5c2e7" } },
					},
					cond = function(tab)
						return not is_claude_code(tab.active_pane)
					end,
					padding = { left = 0, right = 0 },
				},
				" ",
				-- Custom component: show SSH hostname or parent/cwd
				function(tab)
					local pane = tab.active_pane
					local ssh_host = ssh.get_ssh_host(pane)
					if ssh_host then
						-- Truncate long hostnames
						if #ssh_host > 27 then
							return ssh_host:sub(1, 27)
						end
						return ssh_host
					end
					-- Fall back to parent/cwd for non-SSH
					local cwd_uri = pane.current_working_dir
					if cwd_uri then
						-- cwd_uri is a URL string like "file:///path/to/dir"
						local cwd = type(cwd_uri) == "string" and cwd_uri:gsub("^file://", "")
							or (cwd_uri.file_path or "")
						local parent = cwd:match(".*/([^/]+)/[^/]+$") or ""
						local current = cwd:match(".*/([^/]+)$") or cwd
						local display = parent ~= "" and (parent .. "/" .. current) or current
						-- Truncate if too long
						if #display > 27 then
							return display:sub(1, 27)
						end
						return display
					end
					return ""
				end,
				{ "zoomed", padding = 0 },
			},

			-- INACTIVE TAB: icon + cwd (or SSH host)
			tab_inactive = {
				"",
				{ Foreground = { Color = "#E8885C" } },
				function(tab)
					if not is_claude_code(tab.active_pane) then
						return ""
					end
					return (tab.active_pane.title or ""):match("^(%S+)%s") or ""
				end,
				"ResetAttributes",
				{
					"process",
					icons_only = true,
					process_to_icon = {
						nvim = { wezterm.nerdfonts.custom_neovim },
						ssh = { wezterm.nerdfonts.md_server },
					},
					cond = function(tab)
						return not is_claude_code(tab.active_pane)
					end,
					padding = { left = 0, right = 0 },
				},
				" ",
				-- Custom component: show SSH hostname or cwd
				function(tab)
					local pane = tab.active_pane
					local ssh_host = ssh.get_ssh_host(pane)
					if ssh_host then
						-- Truncate long hostnames
						if #ssh_host > 18 then
							return ssh_host:sub(1, 15) .. "..."
						end
						return ssh_host
					end
					-- Fall back to cwd for non-SSH
					local cwd_uri = pane.current_working_dir
					if cwd_uri then
						-- cwd_uri is a URL string like "file:///path/to/dir"
						local cwd = type(cwd_uri) == "string" and cwd_uri:gsub("^file://", "")
							or (cwd_uri.file_path or "")
						local current = cwd:match(".*/([^/]+)$") or cwd
						if #current > 18 then
							return current:sub(1, 15) .. "..."
						end
						return current
					end
					return ""
				end,
			},

			tabline_x = { "cpu", "datetime" },
			tabline_y = {},
			tabline_z = { "domain" },
		},
		extensions = {},
	})

	-- Wrap tabline's tab renderer to tint inactive tabs with unseen bells.
	-- tabs.lua builds: [1-2] separator attrs, [3] separator glyph,
	-- [4-5] inactive attrs (fg, bg), components…, [n-2,n-1] separator attrs, [n] glyph.
	local tabs_mod = require("tabline.tabs")
	local orig_set_title = tabs_mod.set_title
	tabs_mod.set_title = function(tab, hover)
		local result = orig_set_title(tab, hover)
		if result and not tab.is_active and bell_tabs[tab.tab_id] then
			local bell_bg = "#3a1a28"
			result[1] = { Foreground = { Color = bell_bg } }
			result[#result - 2] = { Foreground = { Color = bell_bg } }
			for i = 4, #result - 3 do
				if result[i].Background then
					result[i] = { Background = { Color = bell_bg } }
				end
			end
		end
		return result
	end

	return tabline
end

return M
