{ lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
  programs.aerospace = {
    enable = true;
    launchd.enable = true;

    # Consumers extend settings (notably settings.on-window-detected for
    # workspace pins) from their own home modules. home-manager merges
    # across modules; keep list-valued keys unset here so consumer lists
    # don't get clobbered.
    settings = {
      config-version = 2;
      start-at-login = false;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";

      gaps = {
        inner.horizontal = 4;
        inner.vertical = 4;
        outer.left = 8;
        outer.right = 8;
        outer.top = 8;
        outer.bottom = 8;
      };

      # Keybinds mirror home/desktop/hyprland/keybinds.nix. alt = Option.
      # Chosen over cmd to avoid macOS shortcut collisions (cmd+q/w/h) and
      # avoid needing Karabiner.
      mode.main.binding = {
        "alt-h" = "focus left";
        "alt-j" = "focus down";
        "alt-k" = "focus up";
        "alt-l" = "focus right";

        "alt-shift-h" = "move left";
        "alt-shift-j" = "move down";
        "alt-shift-k" = "move up";
        "alt-shift-l" = "move right";

        "alt-1" = "workspace 1";
        "alt-2" = "workspace 2";
        "alt-3" = "workspace 3";
        "alt-4" = "workspace 4";
        "alt-5" = "workspace 5";
        "alt-6" = "workspace 6";
        "alt-7" = "workspace 7";
        "alt-8" = "workspace 8";
        "alt-9" = "workspace 9";

        "alt-shift-1" = "move-node-to-workspace --focus-follows-window 1";
        "alt-shift-2" = "move-node-to-workspace --focus-follows-window 2";
        "alt-shift-3" = "move-node-to-workspace --focus-follows-window 3";
        "alt-shift-4" = "move-node-to-workspace --focus-follows-window 4";
        "alt-shift-5" = "move-node-to-workspace --focus-follows-window 5";
        "alt-shift-6" = "move-node-to-workspace --focus-follows-window 6";
        "alt-shift-7" = "move-node-to-workspace --focus-follows-window 7";
        "alt-shift-8" = "move-node-to-workspace --focus-follows-window 8";
        "alt-shift-9" = "move-node-to-workspace --focus-follows-window 9";

        "alt-o" = "layout tiles horizontal vertical";
        "alt-shift-o" = "layout accordion horizontal vertical";

        "alt-f" = "fullscreen";
        "alt-g" = "layout floating tiling";

        "alt-shift-semicolon" = "reload-config";

        "alt-r" = "mode resize";
      };

      mode.resize.binding = {
        "h" = "resize width -50";
        "j" = "resize height +50";
        "k" = "resize height -50";
        "l" = "resize width +50";

        "shift-h" = "resize width -10";
        "shift-j" = "resize height +10";
        "shift-k" = "resize height -10";
        "shift-l" = "resize width +10";

        "enter" = "mode main";
        "esc" = "mode main";
      };
    };
  };
}
