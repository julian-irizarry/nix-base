{
  config,
  pkgs,
  ...
}:

{
  programs.wezterm = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.wezterm;
    extraConfig = ''
      local smart_splits = wezterm.plugin.require('https://github.com/mrjones2014/smart-splits.nvim')
      local rose_pine_black = require 'rose_pine_black'
      local keys = require 'keymaps'
      local tabline_config = require 'plugins.tabline'

      local tabline = tabline_config.setup()

      local config = {}

      config.default_prog = { '${pkgs.zsh}/bin/zsh', '--login' }

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

      config.keys = keys.keymaps()
      config.key_tables = keys.key_tables()

      config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }

      config.tab_bar_at_bottom = true
      config.hide_tab_bar_if_only_one_tab = true

      config.scrollback_lines = 10000

      config.inactive_pane_hsb = { saturation = 0.7, brightness = 0.6 }

      tabline.apply_to_config(config)
      smart_splits.apply_to_config(config)

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
