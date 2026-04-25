{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.sys.desktop.hyprland.enable {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  # Mirrors flake.nix nixConfig: the flake-level entry helps evaluators fetching
  # noctalia-shell at build time; this entry wires the deployed system's daemon
  # so rebuilds on-host also hit the cache.
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };
}
