{
  config,
  lib,
  pkgs,
  nixBaseInputs,
  ...
}:

let
  cfg = config.my.desktop.hyprland;
in
lib.mkIf (cfg.enable && cfg.shell == "noctalia" && pkgs.stdenv.hostPlatform.isLinux) {
  programs.noctalia = {
    enable = true;
    package = nixBaseInputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Palette JSONs land in ~/.config/noctalia/palettes/<name>.json and are
    # selected by [theme] source = "custom" + custom_palette below.
    customPalettes = {
      Eventide = lib.importJSON ./colorschemes/eventide.json;
      Pastel = lib.importJSON ./colorschemes/pastel.json;
    };

    # v5 config is TOML at ~/.config/noctalia/config.toml. Validated at build
    # time by `noctalia config validate` (programs.noctalia.validateConfig).
    settings = {
      shell = {
        font_family = "Fira Sans";
        telemetry_enabled = false;
        settings_show_advanced = true;
        polkit_agent = true;

        shadow.alpha = 0.55;

        animation.enabled = true;

        panel = {
          transparency_mode = "solid";
          borders = false;
          shadow = true;
          control_center_placement = "attached";
          wallpaper_placement = "attached";
          session_placement = "attached";
          launcher_placement = "floating";
          launcher_position = "center";
          clipboard_placement = "floating";
          clipboard_position = "center";
        };
      };

      theme = {
        mode = "dark";
        source = "custom";
        custom_palette = "Eventide";

        templates = {
          enable_builtin_templates = true;
          # v5 renamed the gtk template to gtk3/gtk4 and dropped spicetify from
          # the builtin catalog; wezterm/kitty are new and match our terminals.
          builtin_ids = [
            "gtk3"
            "gtk4"
            "qt"
            "wezterm"
            "kitty"
          ];
        };
      };

      lockscreen = {
        enabled = true;
        blur_intensity = 0.70;
      };

      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/wallpapers";
        fill_mode = "crop";

        automation = {
          enabled = true;
          order = "random";
          recursive = true;
        };
      };

      notification = {
        enable_daemon = true;
        position = "top_right";
        background_opacity = 0.97;
      };

      dock.enabled = true;

      system.monitor.enabled = true;

      # hypridle is gone in favor of noctalia's built-in [idle] behaviors —
      # one less daemon, and lock/screen-off share noctalia's lockscreen state.
      idle.behavior = {
        lock = {
          enabled = cfg.idle.enable;
          timeout = cfg.idle.lockTimeout;
          action = "lock";
        };

        screen-off = {
          enabled = cfg.idle.enable;
          timeout = cfg.idle.displayOffTimeout;
          action = "screen_off";
        };
      };

      # v5 bars are named tables; widgets are flat id lists and per-widget
      # options live in separate [widget.<id>] tables below.
      bar.main = {
        position = "top";
        thickness = 34;
        background_opacity = 0.95;
        radius = 12;
        margin_ends = 385;
        margin_edge = 2;
        padding = 14;
        widget_spacing = 6;
        shadow = true;
        reserve_space = true;
        capsule = false;
        start = [
          "launcher"
          "workspaces"
          "sysmon_cpu"
          "sysmon_ram"
          "spacer"
          "audio_visualizer"
        ];
        center = [ "clock" ];
        end = [
          "spacer"
          "volume"
          "brightness"
          "battery"
          "notifications"
          "settings"
          "control-center"
          "session"
        ];

        dead_zone.actions.right = "panel-toggle control-center home";
      };

      widget = {
        workspaces = {
          style = "regular";
          show_labels = false;
          hide_when_empty = false;
          active_pill_size = 0.6;
          inactive_pill_size = 0.6;
          focused_color = "error";
          occupied_color = "on_surface";
          focused_output_only = false;
        };

        # v5 splits the monolithic SystemMonitor widget into one instance per
        # stat, so CPU and RAM are two bar entries rather than one widget's flags.
        sysmon_cpu = {
          type = "sysmon";
          stat = "cpu_usage";
          show_glyph = true;
          show_value = true;
        };

        sysmon_ram = {
          type = "sysmon";
          stat = "ram_used";
          show_glyph = true;
          show_value = true;
        };

        audio_visualizer = {
          width = 100;
          bands = 24;
          mirrored = false;
          centered = true;
          show_when_idle = true;
          color_1 = "primary";
        };

        clock = {
          format = "{:%H:%M %a %b %d}";
          vertical_format = "{:%H\n%M}";
          tooltip_format = "{:%A, %B %d, %Y}";
        };

        volume.show_label = false;

        battery = {
          display_mode = "graphic";
          hide_when_full = false;
          show_label = false;
        };

        notifications.hide_when_no_unread = false;
      };
    };
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = lib.mkAfter [ "noctalia" ];

    input = {
      touchpad = {
        natural_scroll = true;
      };
    };

    decoration = {
      rounding = 12;
      rounding_power = 2;
      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };
      blur.enabled = false;
    };

    general.border_size = 0;

    decoration.dim_inactive = false;
  };
}
