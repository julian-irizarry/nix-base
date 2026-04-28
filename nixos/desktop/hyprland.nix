{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

lib.mkIf config.sys.desktop.hyprland.enable {
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  xdg.portal.enable = true;

  # Standalone GNOME apps — usable without gnome-shell. Chosen to complement
  # noctalia, which already ships bar / notifications / launcher / lock / OSD
  # / wallpaper / night-light but no file manager, calculator, or viewers.
  environment.systemPackages = with pkgs; [
    gnome-disk-utility
    nautilus
    baobab
    file-roller
    loupe
    evince
    gnome-calculator
    mission-center

    # Per-app audio routing UI. noctalia's volume widget handles master
    # volume; pwvucontrol exposes per-app and per-device routing and talks
    # to pipewire natively (unlike pavucontrol which uses the pulse shim).
    pwvucontrol
  ];

  # Backing services for nautilus + gnome-disk-utility. gvfs powers trash,
  # mounted volumes, and network shares; tumbler renders thumbnails;
  # udisks2 backs gnome-disk-utility. dconf stores settings for all of them.
  services.gvfs.enable = true;
  services.tumbler.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;

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
