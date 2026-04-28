{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  cfg = config.my.desktop.hyprland;
  kb = import ./keybinds.nix { inherit pkgs; };
  allPlugins = [
    inputs.hyprland-plugins.packages.${system}.hyprexpo
  ]
  ++ cfg.plugins;
  # HM's plugins option uses exec-once which races with UWSM. Write
  # plugin directives to a separate file and source it — sourceFirst
  # ensures source lines land before keybinds in the generated config.
  pluginConf = pkgs.writeText "hypr-plugins.conf" (
    lib.concatMapStringsSep "\n" (p: "plugin = ${p}/lib/lib${p.pname}.so") allPlugins + "\n"
  );
in
{
  imports = [ ./noctalia.nix ];

  config = lib.mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isLinux) {
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${system}.hyprland;

      settings = {
        source = [ "${pluginConf}" ];

        gesture = [
          "3, horizontal, workspace"
        ];

        "plugin:hyprexpo" = {
          columns = 3;
          gap_size = 5;
          bg_col = "rgb(111111)";
          workspace_method = "first 1";
          enable_gesture = false;
        };

        bind = kb.binds;
        bindl = [
          ", switch:Lid Switch, exec, noctalia-shell ipc call lockScreen lock"
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

      extraConfig = ''
        windowrule {
          name = vicinae
          match:class = ^([Vv]icinae|org\.vicinaehq\.vicinae)$
          float = on
          center = on
        }

        windowrule {
          name = wezterm
          match:class = ^(org\.wezfurlong\.wezterm)$
          workspace = 1
        }

        windowrule {
          name = wezterm-border
          enable = false
          match:class = ^(org\.wezfurlong\.wezterm)$
          border_size = 2
          border_color = rgba(F0B6D0ee) rgba(8BD5CAee) 45deg
        }

        windowrule {
          name = kitty-border
          enable = false
          match:class = ^(kitty)$
          border_size = 2
          border_color = rgba(F0B6D0ee) rgba(8BD5CAee) 45deg
        }

        windowrule {
          name = chrome
          match:class = ^([Gg]oogle-chrome)$
          workspace = 2
        }

        windowrule {
          name = discord
          match:class = ^([Dd]iscord)$
          workspace = 3
        }
      '';
    };

    # Ensures Chrome and other apps that respect XDG color-scheme use dark mode.
    # Noctalia's syncGsettings will keep this in sync at runtime; this seeds
    # the value before noctalia has started on a fresh session.
    dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

    xdg.mime.enable = true;

    # The HM hyprland module auto-enables xdg.portal with only
    # xdg-desktop-portal-hyprland in extraPortals, and emits an
    # ~/.config/environment.d/10-home-manager.conf line pinning
    # NIX_XDG_DESKTOP_PORTAL_DIR to the user-profile portal dir. That
    # value wins over the system-level one set by /etc/set-environment,
    # so the portal frontend never finds gtk.portal even though the NixOS
    # xdg.portal module installs it system-wide. Without the gtk backend,
    # org.freedesktop.portal.Settings is missing entirely and noctalia's
    # color-scheme dconf writes never reach kitty / libadwaita subscribers.
    # Re-add gtk here so the user profile aggregates both portals.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.hyprland = {
        default = [
          "gtk"
          "hyprland"
        ];
      };
    };

    home.packages = [
      kb.cycleLayout
      pkgs.hyprshot
      pkgs.hyprpicker
      pkgs.wf-recorder
      pkgs.gpu-screen-recorder
    ];
  };
}
