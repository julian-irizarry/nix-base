-- keymaps.lua
local wezterm = require("wezterm")
local act = wezterm.action

-- Ctrl+Shift+Z: toggle *both* fullscreen and tab bar (zen mode)
local toggle_zen = wezterm.action_callback(function(window, pane)
	-- enter/exit fullscreen first for GNOME top bar reliability
	window:perform_action(act.ToggleFullScreen, pane)

	-- flip tab bar a moment later
	wezterm.time.call_after(0.01, function()
		local o = window:get_config_overrides() or {}
		if o.enable_tab_bar == false then
			o.enable_tab_bar = nil -- restore default (show tab bar)
		else
			o.enable_tab_bar = false -- hide tab bar (tabline disappears too)
		end
		window:set_config_overrides(o)
	end)
end)

local M = {}

-- Keys herdr owns: tabs, splits, panes and workspaces live in herdr, so
-- wezterm must pass these through instead of acting on its own mux. Several
-- are wezterm defaults, hence the explicit DisableDefaultAssignment. Kitty
-- keeps native tabs/splits as the fallback.
local herdr_keys = {
	{ key = "t", mods = "CTRL|SHIFT" },
	{ key = "h", mods = "CTRL|SHIFT" },
	{ key = "l", mods = "CTRL|SHIFT" },
	{ key = "w", mods = "CTRL|SHIFT" },
	{ key = "f", mods = "CTRL|SHIFT" },
	{ key = "e", mods = "CTRL|SHIFT" },
	{ key = "x", mods = "CTRL|SHIFT" },
	{ key = "n", mods = "CTRL|SHIFT" },
	{ key = "Enter", mods = "CTRL|SHIFT" },
	{ key = "-", mods = "CTRL|SHIFT" },
	{ key = "_", mods = "CTRL|SHIFT" },
	{ key = "_", mods = "CTRL" }, -- ctrl+shift+minus can arrive as ctrl+_
	{ key = "<", mods = "CTRL|SHIFT" },
	{ key = ">", mods = "CTRL|SHIFT" },
	{ key = "t", mods = "CTRL|ALT" },
}
for i = 1, 9 do
	table.insert(herdr_keys, { key = tostring(i), mods = "CTRL" })
end

-- normal/global keybindings
function M.keymaps()
	local keys = {
		{ key = "Enter", mods = "SHIFT", action = act.SendString("\x1b[13;2u") }, -- shift+enter for zsh autosuggestions
		{ key = "u", mods = "CTRL", action = act.SendString("\x15") },

		-- Opacity toggles (events are in wezterm.lua)
		{ key = "F10", mods = "CTRL", action = act.EmitEvent("set-opacity-full") },
		{ key = "F11", mods = "CTRL", action = act.EmitEvent("set-opacity-reduced") },
		{ key = "F12", mods = "CTRL", action = act.EmitEvent("set-opacity-transparent") },

		-- Zen toggle (fullscreen + toggle tab bar)
		{ key = "z", mods = "CTRL|SHIFT", action = toggle_zen },
	}
	for _, k in ipairs(herdr_keys) do
		table.insert(keys, { key = k.key, mods = k.mods, action = act.DisableDefaultAssignment })
	end
	return keys
end

-- copy_mode key table: Vim-style search
function M.key_tables()
	local defaults = wezterm.gui and wezterm.gui.default_key_tables() or {}

	-- start from defaults so we keep all built-ins
	local copy = {}
	local search = {}
	if defaults.copy_mode then
		for _, v in ipairs(defaults.copy_mode) do
			table.insert(copy, v)
		end
	end
	if defaults.search_mode then
		for _, v in ipairs(defaults.search_mode) do
			table.insert(search, v)
		end
	end

	-- --- COPY MODE: jump like Vim, and clean exit ---
	-- Use 'n' / 'N' to move between matches *after* you've set a pattern
	table.insert(copy, { key = "n", mods = "NONE", action = act.CopyMode("NextMatch") })
	table.insert(copy, { key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") })

	-- Optional: map '/' in copy mode to open the Search overlay (instead of EditPattern prompt)
	table.insert(copy, { key = "/", mods = "NONE", action = act.Search("CurrentSelectionOrEmptyString") })

	-- Leaving copy mode should also clear the pattern so the overlay doesn't "ghost" later
	table.insert(copy, {
		key = "X",
		mods = "CTRL|SHIFT",
		action = act.Multiple({ act.CopyMode("ClearPattern"), act.CopyMode("Close") }),
	})
	table.insert(copy, {
		key = "Escape",
		mods = "NONE",
		action = act.Multiple({ act.CopyMode("ClearPattern"), act.CopyMode("Close") }),
	})

	-- --- SEARCH MODE: make Enter/Esc dismiss overlay cleanly (and return focus) ---
	-- ENTER: accept the pattern -> jump, then go back to normal Cell selection in copy mode
	table.insert(search, {
		key = "Enter",
		mods = "NONE",
		action = act.Multiple({
			act.CopyMode("AcceptPattern"),
			act.CopyMode({ SetSelectionMode = "Cell" }),
		}),
	})

	-- ESC: clear the pattern (prevents ghosting), accept (to close overlay), and exit copy mode
	table.insert(search, {
		key = "Escape",
		mods = "NONE",
		action = act.Multiple({
			act.CopyMode("ClearPattern"),
			act.CopyMode("AcceptPattern"),
			act.CopyMode("Close"),
		}),
	})

	return {
		copy_mode = copy,
		search_mode = search,
	}
end

return M
