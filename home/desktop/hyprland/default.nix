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

        general = {
          layout = "dwindle";
          gaps_in = 2;
          gaps_out = 4;
        };

        input = {
          kb_layout = "us";
          follow_mouse = 1;
        };

        monitor = [ ",preferred,auto,1" ];

        animations = {
          enabled = true;
          bezier = [ "ease, 0.25, 0.1, 0.25, 1.0" ];
          animation = [
            "workspaces, 1, 4, ease, slidefade"
            "windows, 1, 3, ease"
            "fade, 1, 4, ease"
          ];
        };
      };

      # Block syntax required by Hyprland 0.49+; old flat windowrule= is rejected.
      extraConfig = ''
        windowrule {
          name = vicinae
          float = true
          center = true
          match {
            class = ^([Vv]icinae|org\.vicinaehq\.vicinae)$
          }
        }

        windowrule {
          name = wezterm-ws1
          workspace = 1
          match {
            class = ^(org\.wezfurlong\.wezterm)$
          }
        }

        windowrule {
          name = chrome-ws2
          workspace = 2
          match {
            class = ^([Gg]oogle-chrome)$
          }
        }

        windowrule {
          name = discord-ws3
          workspace = 3
          match {
            class = ^([Dd]iscord)$
          }
        }
      '';
    };

    # Ensures Chrome and other apps that respect XDG color-scheme use dark mode.
    # Noctalia's syncGsettings will keep this in sync at runtime; this seeds
    # the value before noctalia has started on a fresh session.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    home.packages = [
      kb.cycleLayout
      pkgs.hyprshot
      pkgs.hyprpicker
      pkgs.wf-recorder
    ];
  };
}
