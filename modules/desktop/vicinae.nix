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
    package = config.lib.nixGL.wrap pkgs.vicinae;
    systemd = {
      enable = true;
      autoStart = true;
    };
  };

  xdg.configFile."vicinae/settings.json".source =
    (pkgs.formats.json { }).generate "vicinae-settings.json"
      {
        "$schema" = "https://vicinae.com/schemas/config.json";
        keybinding = "emacs";
        theme = {
          light = {
            name = "kanagawa";
            icon_theme = "auto";
          };
          dark = {
            name = "kanagawa";
            icon_theme = "auto";
          };
        };
      };
}
