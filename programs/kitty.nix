{ pkgs, dotfiles, ... }:

{
  programs.kitty = {
    enable = true;

    # Font settings
    font = {
      name = "FiraCode Nerd Font";
      size = 12.5;
    };

    # Core settings (converted to settings attrset)
    settings = {
      background_opacity = "0.87";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = "0";
      enabled_layouts = "horizontal,stack";
      linux_display_server = "auto";

      cursor_trail = "1";
      cursor_trail_decay = "0.1 0.3";

      scrollback_pager_history_size = "500";
      scrollback_lines = "4000";
      wheel_scroll_min_lines = "1";

      enable_audio_bell = "no";
      window_padding_width = "3";

      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty";
      shell_integration = "enabled";

      hide_window_decorations = "yes";

      include = "current-theme.conf";
    };

    # Keybindings
    keybindings = {
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

      "ctrl+shift+f" = "toggle_layout stack";
      "alt+w" = "close_tab";
    };

  };

  home.file.".config/kitty/current-theme.conf".source =
    "${dotfiles}/.config/kitty/current-theme.conf";
}
