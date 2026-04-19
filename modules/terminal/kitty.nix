{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.kitty;

    font = {
      name = config.my.font.name;
      size = config.my.font.size;
    };

    settings = {
      shell = "${pkgs.zsh}/bin/zsh --login";

      hide_window_decorations = "yes";
      confirm_os_window_close = 0;
      window_padding_width = 0;

      background_opacity = "0.85";
      dynamic_background_opacity = "yes";

      cursor_trail = 1;
      cursor_trail_decay = "0.1 0.3";

      inactive_text_alpha = "0.6";
      active_border_color = "none";
      inactive_border_color = "none";
      window_border_width = "0";

      tab_bar_edge = "bottom";
      tab_bar_style = "custom";
      tab_bar_min_tabs = 2;
      active_tab_font_style = "normal";
      tab_bar_background = "#000000";

      scrollback_lines = 10000;
      scrollback_pager_history_size = 500;
      wheel_scroll_min_lines = 1;

      enable_audio_bell = "no";
      enabled_layouts = "horizontal,stack";
      linux_display_server = "auto";

      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty";
      shell_integration = "enabled";
    };

    keybindings = {
      "shift+enter" = "send_text all \\x1b[13;2u";

      "ctrl+h" = "neighboring_window left";
      "ctrl+j" = "neighboring_window down";
      "ctrl+k" = "neighboring_window up";
      "ctrl+l" = "neighboring_window right";

      "ctrl+shift+l" = "next_tab";
      "ctrl+shift+h" = "previous_tab";

      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      "ctrl+6" = "goto_tab 6";
      "ctrl+7" = "goto_tab 7";
      "ctrl+8" = "goto_tab 8";
      "ctrl+9" = "goto_tab 9";

      "ctrl+shift+," = "move_tab_backward";
      "ctrl+shift+." = "move_tab_forward";

      "ctrl+shift+w" = "close_window";

      "ctrl+shift+f" = "toggle_layout stack";

      "ctrl+shift+enter" = "launch --location=vsplit --cwd=current";
      "ctrl+shift+minus" = "launch --location=hsplit --cwd=current";

      "ctrl+shift+up" = "move_window up";
      "ctrl+shift+left" = "move_window left";
      "ctrl+shift+right" = "move_window right";
      "ctrl+shift+down" = "move_window down";

      "ctrl+f10" = "set_background_opacity 1.0";
      "ctrl+f11" = "set_background_opacity 0.85";
      "ctrl+f12" = "set_background_opacity 0.55";

      "ctrl+shift+n" = "toggle_fullscreen";
      "ctrl+shift+z" = "combine : toggle_fullscreen : goto_layout stack";

      "kitty_mod+s" = "kitty_scrollback_nvim";
      "kitty_mod+g" = "kitty_scrollback_nvim --config ksb_builtin_last_cmd_output";
    };

    extraConfig = ''
      action_alias kitty_scrollback_nvim kitten ${config.home.homeDirectory}/.local/share/nvim/lazy/kitty-scrollback.nvim/python/kitty_scrollback_nvim.py

      mouse_map ctrl+shift+right press ungrabbed combine : mouse_select_command_output : kitty_scrollback_nvim --config ksb_builtin_last_visited_cmd_output

      include current-theme.conf
    '';
  };

  xdg.configFile = {
    "kitty/current-theme.conf".source = ./kitty-theme.conf;
    "kitty/tab_bar.py".source = ./kitty-tab_bar.py;
  };
}
