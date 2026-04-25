{ config, lib, ... }:

{
  imports = [
    ./cosmic.nix
    ./hyprland.nix
  ];

  config = lib.mkIf (config.sys.desktop.cosmic.enable || config.sys.desktop.hyprland.enable) {
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}
