{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # Vicinae — Raycast-style launcher for Linux. The module comes from the
  # vicinae flake input (see lib/mkHome.nix). We pin package to pkgs.vicinae
  # so builds skip the upstream cachix and cache through nixpkgs instead;
  # nixGL.wrap makes Qt's RHI find system GL drivers on non-NixOS.
  services.vicinae = {
    enable = true;
    package =
      if config.my.platform.nixGL.enable then config.lib.nixGL.wrap pkgs.vicinae else pkgs.vicinae;
    systemd = {
      enable = true;
      autoStart = true;
    };
  };

  services.vicinae.themes.kanagawa-deep = {
    meta = {
      version = 1;
      name = "Kanagawa Deep";
      description = "Deep blacks with Kanagawa wave-inspired accents";
      variant = "dark";
      inherits = "vicinae-dark";
    };

    colors = {
      core = {
        background = "#000000";
        foreground = "#DCD7BA";
        secondary_background = "#0A0A0A";
        border = "#1A1A1A";
        accent = "#7E9CD8";
      };
      accents = {
        blue = "#7E9CD8";
        green = "#76946A";
        magenta = "#957FB8";
        orange = "#B4A1D4";
        purple = "#938AA9";
        red = "#C34043";
        yellow = "#E6C384";
        cyan = "#7FB4CA";
      };
      list.item.selection = {
        background = "#141414";
        secondary_background = "#1E1E1E";
      };
    };
  };

  services.vicinae.settings = {
    pop_to_root_on_close = true;
    favorites = [
      "sessionizer:sessionizer"
      "sessionizer:find-open-session"
    ];
    theme = {
      light = {
        name = "kanagawa-deep";
        icon_theme = "auto";
      };
      dark = {
        name = "kanagawa-deep";
        icon_theme = "auto";
      };
    };
  };
}
