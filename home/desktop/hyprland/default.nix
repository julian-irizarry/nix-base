{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop.hyprland;
  kb = import ./keybinds.nix { inherit pkgs; };
in
{
  imports = [ ./noctalia.nix ];

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        bind = kb.binds;

        windowrulev2 = [
          "float, class:^([Vv]icinae|org\\.vicinaehq\\.vicinae)$"
          "center, class:^([Vv]icinae|org\\.vicinaehq\\.vicinae)$"
        ];

        general = {
          layout = "dwindle";
          gaps_in = 4;
          gaps_out = 8;
        };

        input = {
          kb_layout = "us";
          follow_mouse = 1;
        };

        monitor = [ ",preferred,auto,1" ];
      };
    };

    home.packages = [ kb.cycleLayout ];
  };
}
