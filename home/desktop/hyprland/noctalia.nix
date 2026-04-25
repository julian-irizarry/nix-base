{
  config,
  lib,
  pkgs,
  noctalia,
  ...
}:

let
  cfg = config.my.desktop.hyprland;
in
lib.mkIf (cfg.enable && cfg.shell == "noctalia" && pkgs.stdenv.hostPlatform.isLinux) {
  programs.noctalia-shell = {
    enable = true;
    package = noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };

  wayland.windowManager.hyprland.settings = {
    exec-once = lib.mkAfter [ "noctalia-shell" ];

    decoration = {
      rounding = 20;
      rounding_power = 2;
      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };
      blur = {
        enabled = true;
        size = 3;
        passes = 2;
        vibrancy = 0.1696;
      };
    };

    # Blur noctalia bar/panels. Matches the layer namespace noctalia creates
    # ("noctalia-background-*") so panels feel translucent instead of opaque.
    layerrule = [
      "ignore_alpha 0.5, ^(noctalia-background-.*)$"
      "blur, ^(noctalia-background-.*)$"
      "blurpopups, ^(noctalia-background-.*)$"
    ];
  };
}
