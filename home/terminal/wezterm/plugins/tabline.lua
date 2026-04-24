local wezterm = require("wezterm")
local ssh = require("utils.ssh")

local M = {}

function M.setup()
	local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")

	tabline.setup({
		options = {
			icons_enabled = true,
			theme = "iTerm2 Pastel Dark Background",
			theme_overrides = {
				normal_mode = {
					a = { bg = "#ff9da4" },
					b = { bg = "transparent" },
					c = { bg = "transparent" },
					x = { bg = "transparent" },
					y = { bg = "transparent" },
					z = { bg = "#ff9da4" },
				},
				tab = {
					active = { fg = "#ffffff", bg = "rgba(38, 35, 58, 0.6)" },
					inactive = { bg = "transparent" },
					inactive_hover = { bg = "rgba(38, 35, 58, 0.4)" },
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

			-- ACTIVE TAB: Neovim icon + parent/cwd (or SSH host) + zoom indicator
			tab_active = {
				"",
				{
					"process",
					icons_only = true,
					process_to_icon = {
						nvim = { wezterm.nerdfonts.custom_neovim, color = { fg = "#a6e3a1" } },
						ssh = { wezterm.nerdfonts.md_server, color = { fg = "#f5c2e7" } },
					},
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

			-- INACTIVE TAB: Neovim icon + cwd (or SSH host)
			tab_inactive = {
				"",
				{
					"process",
					icons_only = true,
					process_to_icon = {
						nvim = { wezterm.nerdfonts.custom_neovim },
						ssh = { wezterm.nerdfonts.md_server },
					},
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

	return tabline
end

return M
