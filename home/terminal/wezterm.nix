{
  config,
  pkgs,
  ...
}:

{
  programs.wezterm = {
    enable = true;
    package =
      if config.my.platform.nixGL.enable then config.lib.nixGL.wrap pkgs.wezterm else pkgs.wezterm;
    extraConfig = ''
      local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')
      local rose_pine_black = require 'rose_pine_black'
      local keys = require 'keymaps'
      local tabline_config = require 'plugins.tabline'

      local tabline = tabline_config.setup()

      local config = {}

      config.default_prog = { '${pkgs.zsh}/bin/zsh', '--login' }

      config.term = 'wezterm'

      config.font = wezterm.font '${config.my.font.name}'
      config.font_size = ${toString config.my.font.size}

      config.colors = rose_pine_black

      config.window_background_opacity = 0.85

      local function set_opacity(window, opacity)
        local o = window:get_config_overrides() or {}
        o.window_background_opacity = opacity
        window:set_config_overrides(o)
      end

      wezterm.on('set-opacity-full', function(window, _) set_opacity(window, 1.0) end)
      wezterm.on('set-opacity-reduced', function(window, _) set_opacity(window, 0.85) end)
      wezterm.on('set-opacity-transparent', function(window, _) set_opacity(window, 0.55) end)

      -- Remote-controlled workspace focus for the vicinae sessionizer:
      -- setting the SESSIONIZER_FOCUS user var on any pane switches this
      -- window to the named workspace. Runs in-process so the OS window
      -- raises — external activate-pane requests are blocked by GNOME's
      -- focus stealing prevention.
      wezterm.on('user-var-changed', function(window, pane, name, value)
        if name == 'SESSIONIZER_FOCUS' and value and value ~= ''' then
          window:perform_action(wezterm.action.SwitchToWorkspace { name = value }, pane)
        end
      end)

      config.keys = keys.keymaps()
      config.key_tables = keys.key_tables()

      config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

      config.tab_bar_at_bottom = true
      config.hide_tab_bar_if_only_one_tab = true

      config.scrollback_lines = 10000

      config.inactive_pane_hsb = { saturation = 0.7, brightness = 0.6 }

      tabline.apply_to_config(config)
      smart_splits.apply_to_config(config)

      -- Must come after plugin apply_to_config calls — tabline otherwise
      -- overwrites window_decorations.
      config.window_decorations = '${if pkgs.stdenv.hostPlatform.isDarwin then "RESIZE" else "NONE"}'

      return config
    '';
  };

  xdg.configFile = {
    "wezterm/rose_pine_black.lua".source = ./wezterm/rose_pine_black.lua;
    "wezterm/keymaps.lua".source = ./wezterm/keymaps.lua;
    "wezterm/plugins/tabline.lua".source = ./wezterm/plugins/tabline.lua;
    "wezterm/plugins/workspace_switcher.lua".source = ./wezterm/plugins/workspace_switcher.lua;
    "wezterm/utils/ssh.lua".source = ./wezterm/utils/ssh.lua;
  };
}
