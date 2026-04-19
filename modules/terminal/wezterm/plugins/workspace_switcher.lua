-- workspace_switcher.lua
-- Workspace switcher with zoxide integration using InputSelector

local wezterm = require("wezterm")
local act = wezterm.action
local nf = wezterm.nerdfonts

local M = {}

-- Full path to zoxide (WezTerm doesn't inherit shell PATH)
local ZOXIDE_PATH = wezterm.home_dir .. "/.nix-profile/bin/zoxide"

-- Colors (rose pine inspired)
local colors = {
	workspace = "#9ccfd8", -- foam (cyan)
	current = "#eb6f92", -- love (pink)
	folder = "#908caa", -- subtle (muted white/gray)
	path = "#6e6a86", -- muted
	icon = "#c4a7e7", -- iris (purple)
}

function M.switch_workspace()
	return wezterm.action_callback(function(window, pane)
		local choices = {}
		local seen_names = {}

		local current_ws = window:active_workspace()

		-- Add "Create new workspace" option at the top
		table.insert(choices, {
			id = "new:",
			label = wezterm.format({
				{ Foreground = { Color = colors.icon } },
				{ Text = nf.cod_add .. " " },
				"ResetAttributes",
				{ Foreground = { Color = colors.current } },
				{ Attribute = { Intensity = "Bold" } },
				{ Text = "Create new workspace..." },
			}),
		})

		-- Add existing workspaces
		for _, name in ipairs(wezterm.mux.get_workspace_names()) do
			seen_names[name] = true

			local is_current = (name == current_ws)
			local icon = is_current and nf.cod_workspace_trusted or nf.cod_window
			local name_color = is_current and colors.current or colors.workspace

			local label = wezterm.format({
				{ Foreground = { Color = colors.icon } },
				{ Text = icon .. " " },
				"ResetAttributes",
				{ Foreground = { Color = name_color } },
				{ Attribute = { Intensity = is_current and "Bold" or "Normal" } },
				{ Text = name },
				"ResetAttributes",
				{ Foreground = { Color = colors.path } },
				{ Text = is_current and " (current)" or "" },
			})

			table.insert(choices, {
				id = "workspace:" .. name,
				label = label,
			})
		end

		-- Get zoxide directories
		local success, stdout, stderr = wezterm.run_child_process({ ZOXIDE_PATH, "query", "-l" })

		if success and stdout then
			for path in stdout:gmatch("[^\r\n]+") do
				local name = path:match("([^/]+)$")
				if name and not seen_names[name] then
					local label = wezterm.format({
						{ Foreground = { Color = colors.icon } },
						{ Text = nf.md_folder .. " " },
						"ResetAttributes",
						{ Foreground = { Color = colors.folder } },
						{ Text = name },
						"ResetAttributes",
						{ Foreground = { Color = colors.path } },
						{ Text = " " .. path },
					})

					table.insert(choices, {
						id = "zoxide:" .. path,
						label = label,
					})
				end
			end
		end

		window:perform_action(
			act.InputSelector({
				title = nf.cod_layers .. "  Switch Workspace",
				choices = choices,
				fuzzy = true,
				fuzzy_description = nf.md_magnify .. "  ",
				action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
					if not id then
						return
					end

					-- Handle "Create new workspace"
					if id == "new:" then
						inner_window:perform_action(
							act.PromptInputLine({
								description = wezterm.format({
									{ Foreground = { Color = colors.icon } },
									{ Text = nf.cod_add .. " " },
									"ResetAttributes",
									{ Foreground = { Color = colors.workspace } },
									{ Text = "New workspace name: " },
								}),
								action = wezterm.action_callback(function(win, p, name)
									if name and name ~= "" then
										win:perform_action(act.SwitchToWorkspace({ name = name }), p)
									end
								end),
							}),
							inner_pane
						)
						return
					end

					local ws_match = id:match("^workspace:(.+)$")
					local zoxide_match = id:match("^zoxide:(.+)$")

					if ws_match then
						inner_window:perform_action(act.SwitchToWorkspace({ name = ws_match }), inner_pane)
					elseif zoxide_match then
						local path = zoxide_match
						local ws_name = path:match("([^/]+)$")
						inner_window:perform_action(
							act.SwitchToWorkspace({
								name = ws_name,
								spawn = { cwd = path },
							}),
							inner_pane
						)
					end
				end),
			}),
			pane
		)
	end)
end

return M
